//
//  DaniPlotApp.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//

import SwiftUI

@main
struct DaniPlotApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: DaniPlotDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
