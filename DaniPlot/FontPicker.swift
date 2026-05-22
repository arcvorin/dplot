//
//  FontPicker.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-18.
//

import SwiftUI

struct FontPicker: View {
    @State var availableFonts: [String] = NSFontManager.shared.availableFontFamilies
    @Binding var selection: String

    var body: some View {
        Picker("Font", selection: $selection) {
            ForEach(availableFonts, id: \.self) {
                Text($0)
            }
        }
    }
}

#Preview
{

        // Fallback on earlier versions
        FontPicker(selection: .constant("Arial"))
}
