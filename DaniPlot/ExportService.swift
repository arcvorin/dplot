//
//  ExportLog.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import Foundation
import AppKit
import UniformTypeIdentifiers

struct ExportLog: Equatable {
    let message: String
}

enum ExportService {
    static func export(model: DataModel) async -> ExportLog? {
        let title = model.title.isEmpty ? "Plot" : model.title.replacingOccurrences(of: " ", with: "_")
        guard let destURL = askUserForSaveURL(suggestedName: title, format: model.format.finalExtensionString()) else { return nil }

        // 2) Build temp working dir
        let baseDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DaniPlotExport", isDirectory: true)
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let taskID = UUID().uuidString
        let workDir = baseDir.appendingPathComponent(taskID, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        } catch {
            return ExportLog(message: "Failed to create temp dir: \(error)")
        }

        // 3) Prepare script and output paths
        let scriptURL = workDir.appendingPathComponent("export.gp")
        let tempURL = workDir.appendingPathComponent("out.\(model.format.intermediateExtensionString())")

        let script = model.toGnuplotScript(outURL: tempURL)

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            return ExportLog(message: "Failed writing script: \(error)")
        }

        // 5) Resolve gnuplot
        guard let exe = resolveGnuplot(userPath: nil) else {
            return ExportLog(message:
                """
                Could not find gnuplot.
                Tried:
                  userPath=\(nil ?? "(nil)")
                  /opt/homebrew/bin/gnuplot
                  /usr/local/bin/gnuplot
                  PATH (via /usr/bin/which)
                """)
        }

        // 6) Run gnuplot
        let run = runProcess(exe: exe, args: [scriptURL.path], cwd: workDir)
        guard run.status == 0 else {
            return ExportLog(message:
                """
                Gnuplot failed
                Path: \(exe.path)
                Status: \(run.status)
                stdout: \(run.out)
                stderr: \(run.err)
                """)
        }

        // 7) Move result to user-chosen location (overwrite if exists)
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: tempURL, to: destURL)
        } catch {
            return ExportLog(message: "Failed saving SVG: \(error)")
        }

        return nil // success, no error log
    }

    // MARK: - Helpers

    private static func askUserForSaveURL(suggestedName: String, format: String) -> URL? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        switch format {
        case "svg":
            panel.allowedContentTypes = [.svg]
        case "png":
            panel.allowedContentTypes = [.png]
        case "pdf":
            panel.allowedContentTypes = [.pdf]
        default:
            assertionFailure("Format \(format) not supported")
            break
        }
        panel.isExtensionHidden = false
        panel.title = "Export \(format.uppercased())"
        panel.nameFieldStringValue = suggestedName.hasSuffix(".\(format)") ? suggestedName : suggestedName + ".\(format)"
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func resolveGnuplot(userPath: String?) -> URL? {
        if let p = userPath, !p.isEmpty, FileManager.default.isExecutableFile(atPath: p) {
            return URL(fileURLWithPath: p)
        }
        let asPath = "/opt/homebrew/bin/gnuplot"
        if FileManager.default.isExecutableFile(atPath: asPath) {
            return URL(fileURLWithPath: asPath)
        }
        let intelPath = "/usr/local/bin/gnuplot"
        if FileManager.default.isExecutableFile(atPath: intelPath) {
            return URL(fileURLWithPath: intelPath)
        }
        if let which = which("gnuplot"), FileManager.default.isExecutableFile(atPath: which) {
            return URL(fileURLWithPath: which)
        }
        return nil
    }

    private static func which(_ cmd: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        p.arguments = [cmd]
        let pipe = Pipe()
        p.standardOutput = pipe
        do {
            try p.run()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private static func runProcess(exe: URL, args: [String], cwd: URL?) -> (status: Int32, out: String, err: String) {
        let p = Process()
        p.executableURL = exe
        p.arguments = args
        p.currentDirectoryURL = cwd
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do {
            try p.run()
        } catch {
            return (127, "", "Failed to run \(exe.path) \(args.joined(separator: " ")): \(error)")
        }
        p.waitUntilExit()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""
        return (p.terminationStatus, out, err)
    }
}
