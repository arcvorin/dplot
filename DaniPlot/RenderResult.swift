//
//  RenderResult.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import Foundation

nonisolated struct RenderResult: Equatable {
    var url: URL?
    var format: Format
    var log: String
    
    func appendToLog(_ string: String) -> RenderResult {
        let mutatedLog = "\(self.log)\n\(string)"
        return RenderResult(url: self.url, format: self.format, log: mutatedLog)
    }
}

enum TeXEngine: String {
    case pdflatex
    case lualatex
}

private actor StreamAccumulator {
    private var chunks: [Data] = []

    func append(_ data: Data) {
        chunks.append(data)
    }

    func string() -> String {
        let data = chunks.reduce(into: Data(), { $0.append($1) })
        return String(data: data, encoding: .utf8) ?? ""
    }
}

actor RenderService {
    private var lastTaskID = 0
    private let processTimeoutNanoseconds: UInt64 = 30 * 1_000_000_000
    
    private var cachedGnuplotURL: URL?

    private func gnuplotURL() -> URL? {
        if let cachedGnuplotURL { return cachedGnuplotURL }
        let url = GnuplotLocator.resolveExecutableURL()
        cachedGnuplotURL = url
        return url
    }
    
    private func which(_ cmd: String) -> String? {
        let p = Process()
        var env = ProcessInfo.processInfo.environment
        let additions = "/opt/homebrew/bin:/usr/local/bin:/Library/TeX/texbin"
        env["PATH"] = [additions, env["PATH"] ?? ""].joined(separator: ":")
        p.environment = env
        p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        p.arguments = [cmd]
        let pipe = Pipe()
        p.standardOutput = pipe
        do {
            print("Running which...")
            try p.run()
            p.waitUntilExit()
            print("Done")
            guard p.terminationStatus == 0 else {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let s = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("which: \(s)")

            return s
        } catch {
            print("Error while executing `which`: \(error)")
            return nil
        }
    }

    func renderDocument(_ model: DataModel) async -> RenderResult {
        // Prepare temp files

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DaniPlotPreview", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let taskID = UUID().uuidString
        let scriptURL = tempDir.appendingPathComponent("script-\(taskID).gp")
        let outURL = tempDir.appendingPathComponent("out-\(taskID).\(model.format.intermediateExtensionString())")
        let logURL = tempDir.appendingPathComponent("log-\(taskID).txt")

        let script = model.toGnuplotScript(outURL: outURL)
        

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            return RenderResult(url: nil, format: model.format, log: "Failed writing script: \(error)")
        }

        // Run gnuplot
        guard let exe = gnuplotURL() else {
                    return RenderResult(
                        url: nil,
                        format: model.format,
                        log: """
                        Could not find gnuplot.
                        Looked in:
                          - /opt/homebrew/bin/gnuplot
                          - /usr/local/bin/gnuplot
                          - PATH (via /usr/bin/which)
                        Please install via Homebrew:
                          brew install gnuplot
                        Or set a custom path in app settings.
                        """
                    )
        }
        
        let proc = Process()
        proc.executableURL = gnuplotURL()
        proc.arguments = [scriptURL.path]

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        do {
           try proc.run()
       } catch {
           print(error)
           return RenderResult(url: nil, format: model.format, log: "Failed launching gnuplot at \(exe.path): \(error)")
       }
        let stdoutAccumulator = StreamAccumulator()
        let stderrAccumulator = StreamAccumulator()
        let printQueue = DispatchQueue(label: "DaniPlot.RenderService.ProcessOutput", qos: .utility)

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            Task {
                await stdoutAccumulator.append(data)
            }
            printQueue.async {
                if let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty {
                    print("[gnuplot stdout] \(chunk)", terminator: "")
                }
            }
        }
        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            Task {
                await stderrAccumulator.append(data)
            }
            printQueue.async {
                if let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty {
                    print("[gnuplot stderr] \(chunk)", terminator: "")
                }
            }
        }

        let didTimeout = await waitForProcess(proc, timeoutNanoseconds: processTimeoutNanoseconds)
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil

        // Collect logs
        let stdout = await stdoutAccumulator.string() + (String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
        let stderr = await stderrAccumulator.string() + (String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
        let combined = [stdout, stderr].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        print("combined: \(combined)")
        try? combined.write(to: logURL, atomically: true, encoding: .utf8)

        if didTimeout {
            return RenderResult(
                url: nil,
                format: model.format,
                log: "Gnuplot timed out after \(processTimeoutNanoseconds / 1_000_000_000)s.\n\(combined)"
            )
        }

        if proc.terminationStatus == 0, FileManager.default.fileExists(atPath: outURL.path) {
            let result = RenderResult(url: outURL, format: model.format, log: combined)
            if (model.format == .tikz_pdf) {
                return await texToPDF(texResult: result)
            }
            return result
        } else {
            return RenderResult(url: nil, format: model.format, log: "Gnuplot failed (exit \(proc.terminationStatus)):\n\(combined)")
        }
    }
    
    func texToPDF(texResult: RenderResult, texEngine: TeXEngine = .pdflatex) async -> RenderResult {
        print("Tex to PDF")
        guard let url = texResult.url else {
            return texResult.appendToLog("Can't render to PDF without a path to the tex file")
        }
        guard texResult.format == .tikz_pdf else {
            return texResult.appendToLog("Can't render to PDF as the format is not .tikz_pdf")
        }
        let directoryURL = url.deletingLastPathComponent()
        let taskID = UUID().uuidString
        let docURL = directoryURL.appendingPathComponent("\(taskID).tex")
        let finalURL = directoryURL.appendingPathComponent("\(taskID).pdf")
        let texName = texEngine.rawValue
        
        guard let texPath = which(texName), FileManager.default.isExecutableFile(atPath: texPath) else {
            return .init(url: texResult.url, format: .tikz, log: texResult.log.appending("\nCould not find \(texName) on your system"))
       }
    
        let doc = """
             \\documentclass[tikz.border=3mm]{standalone}
             \\usetikzlibrary(decorations.pathreplasing.calligraphy}
             \\input{\(url.lastPathComponent)}
             \\end{document}
             """
        do { try doc.write(to: docURL, atomically: true, encoding: .utf8) }
        catch {
            return .init(url: nil, format: .tikz_pdf, log: texResult.log.appending("\nFailed to write LaTeX doc: \(error)"))
       }
        print(docURL.path())
        let pass1 = await run(URL(fileURLWithPath: texPath), args: ["-interaction=nonstopmode", docURL.lastPathComponent], cwd: directoryURL)
                guard pass1.0 == 0 else {
                    return .init(url: nil, format: .tikz_pdf, log: texResult.log.appending("\n\(texName) failed (1):\n\(pass1.1)\n\(pass1.2)"))
                }
        let pass2 = await run(URL(fileURLWithPath: texPath), args: ["-interaction=nonstopmode", docURL.lastPathComponent], cwd: directoryURL)
        print("Finished rendering to PDF")

        guard FileManager.default.fileExists(atPath: finalURL.path) else {
            return .init(url: nil, format: .tikz_pdf, log: texResult.log.appending("\n\(texName) did not produce PDF:\n\(pass2.1)\n\(pass2.2)"))
        }
        
        let combinedLog = [texResult.log, pass1.1, pass1.2, pass2.1, pass2.2]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n")
        return .init(url: finalURL, format: .tikz_pdf, log: combinedLog)
        
    }
    
    private func run(_ exe: URL, args: [String], cwd: URL?) async -> (Int32, String, String) {
        let p = Process()
        p.executableURL = exe
        p.arguments = args
        p.currentDirectoryURL = cwd
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do { try p.run() } catch {
            return (127, "", "Failed to run \(exe.path): \(error)")
        }
        p.waitUntilExit()
        let so = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let se = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, so, se)
    }

    private func waitForProcess(_ process: Process, timeoutNanoseconds: UInt64) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    process.terminationHandler = { _ in
                        continuation.resume(returning: false)
                    }
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                guard process.isRunning else { return false }
                process.terminate()
                return true
            }

            let result = await group.next() ?? false
            group.cancelAll()
            process.terminationHandler = nil
            return result
        }
    }
}
