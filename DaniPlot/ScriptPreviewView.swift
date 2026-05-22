//
//  ScriptPreviewView.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import SwiftUI

struct ScriptPreviewView: View {
    let script: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Script Preview")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                Text(script)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }
}
