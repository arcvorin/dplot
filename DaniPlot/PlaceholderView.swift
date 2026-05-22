//
//  PlaceholderView.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import SwiftUI

struct PlaceholderView: View {
    let title: String
    let systemImage: String
    let description: String?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3)
            if let description {
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
