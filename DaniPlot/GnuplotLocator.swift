//
//  GnuplotLocator.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import Foundation

nonisolated enum GnuplotLocator {
    static func resolveExecutableURL() -> URL? {
        // 1) Common Homebrew locations
        let candidates = [
            "/opt/homebrew/bin/gnuplot", // Apple Silicon default
            "/usr/local/bin/gnuplot"     // Intel / older Homebrew
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        // 2) Try PATH using /usr/bin/which
        if let path = which("gnuplot") {
            return URL(fileURLWithPath: path)
        }

        // 3) Final fallback: nil (not found)
        return nil
    }

    private static func which(_ cmd: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = [cmd]
        let pipe = Pipe()
        proc.standardOutput = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let s = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                print("which: \(s)")
                if let s, !s.isEmpty, FileManager.default.isExecutableFile(atPath: s) {
                    return s
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
