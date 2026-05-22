//
//  ColorField.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import SwiftUI
import AppKit

struct ColorField: View {
    // rgb string like "#A8D6A8" or "grey"; nil = unset
    @Binding var rgbString: String?

    @State private var color: Color = .black
    @State private var text: String = ""   // editable hex/name

    var body: some View {
        HStack(spacing: 8) {
            // Swatch + picker
            TextField("Color", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(applyText)
                .onChange(of: text) { _ in
                    // Live-validate lightweight (optional)
                }

            ColorPicker("Color", selection: $color, supportsOpacity: false)
                .labelsHidden()

                .onChange(of: color) { _ in
                    // When user picks, update text and binding with hex
                    let ns = NSColor(color)
                    let hex = ns.hex
                    text = hex
                    rgbString = hex
                }

//            // Show current swatch explicitly
//            RoundedRectangle(cornerRadius: 4)
//                .fill(color)
//                .frame(width: 24, height: 16)
//                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.secondary, lineWidth: 0.5))

            // Editable text (hex or named)

            // Quick set buttons (optional)
//            Menu("Presets") {
//                Button("Black") { setText("black") }
//                Button("Grey") { setText("#808080") }
//                Button("Red") { setText("#FF3B30") }
//                Button("Green") { setText("#34C759") }
//                Button("Blue") { setText("#007AFF") }
//            }
        }
        .onAppear {
            // Initialize from binding
            if let s = rgbString {
                
                if let ns = NSColor(s) {
                    let c = Color(nsColor: ns)
                    color = c; text = s
                }
                else { text = s } // named color; keep text; swatch uses default
            } else {
                text = ""
            }
        }
    }

    private func applyText() {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let ns = NSColor(s) {
            let c = Color(nsColor: ns)
            color = c
            rgbString = s.uppercased()
        } else {
            // Accept named colors for gnuplot as raw text
            rgbString = s.isEmpty ? nil : s
        }
    }

    private func setText(_ s: String) {
        text = s
        applyText()
        switch text {
        case "black": color = .black
        case "grey": color = .gray
        case "red": color = .red
        case "green": color = .green
        case "blue": color = .blue
        default: break
        }
    }
}

private extension NSColor {
    convenience init(_ color: Color) {
        self.init(cgColor: color.cgColor ?? NSColor.black.cgColor)!
    }
}
