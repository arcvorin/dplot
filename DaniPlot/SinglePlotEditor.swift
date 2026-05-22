//
//  SinglePlotEditor.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//
import SwiftUI

struct SinglePlotEditor: View {
    @Binding var item: PlotItem
    @Binding var document: DaniPlotDocument

    var body: some View {
        Form {
            
            
            Section("Source") {
                TextField("Title", text: Binding(
                    get: { item.title ?? "" },
                    set: { item.title = $0.isEmpty ? nil : $0 }
                ), prompt: Text("The title goes here (optional)")).textFieldStyle(.roundedBorder)
                Picker("Type", selection: bindingForSourceKind) {
                    Text("Function").tag(SourceKind.function)
                    Text("File").tag(SourceKind.file)
                }
                switch item.source {
                case .function:
                    TextField("Expression (e.g., x, sin(x))", text: bindingForFunctionExpr)
                        .textFieldStyle(.roundedBorder)
                case .file:
                    HStack(spacing: 8) {
                        TextField("File Path", text: bindingForFilePath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse…") {
                            if let url = openFilePanel() {
                                item.source = .file(path: url.path)
                                // If your separator should switch to tab/csv depending on extension,
                                // you could adjust document/model here as well.
                            }
                        }
                    }
                    UsingEditor(usingSpec: $item.usingSpec)
                }
            }
            
            Section("Target Surface") {
                HStack {
                    Picker("X Axis", selection: $item.axes.x) {
                        Text("Default").tag(PossibleAxes.one)
                        Text("Secondary").tag(PossibleAxes.two)
                    }
                    Picker("Y Axis", selection: $item.axes.y) {
                        Text("Default").tag(PossibleAxes.one)
                        Text("Secondary").tag(PossibleAxes.two)
                    }.onChange(of: item.axes.x, perform: {
                        if ($0 == .two) {
                            document.model.secondaryAxes.enabled = true
                        }
                    })
                    .onChange(of: item.axes.y, perform: {
                        if ($0 == .two) {
                            document.model.secondaryAxes.enabled = true
                        }
                    })
                }
            }

            Section("Style") {
                Picker("With", selection: Binding(
                    get: { item.with ?? .points },
                    set: {
                        item.with = $0 ?? .points
        
                        switch ($0) {
                        case .points:
                            item.line = LineSpec(rgb: item.line?.rgb ?? "#000000")
                            item.point = item.point ?? PointSpec(pointType: 0, pointSize: 1.0)
                        case .dots:
                            item.point = nil
                            item.line = LineSpec(rgb: item.line?.rgb ?? "#000000")
                        case .impulses:
                            item.point = nil
                            item.line = item.line ?? LineSpec(lineWidth: 1.0, rgb: item.line?.rgb ?? "#000000")
                            break
                        case .lines:
                            item.point = nil
                            item.line = item.line ?? LineSpec(lineWidth: 1.0, rgb: item.line?.rgb ?? "#000000")
                            break
                        case .linespoints:
                            item.point = item.point ?? PointSpec(pointType: 0, pointSize: 1.0)
                            item.line = item.line ?? LineSpec(lineWidth: 1.0, rgb: item.line?.rgb ?? "#000000")
                            break
                        case .yerrorbars:
                            item.line = LineSpec(rgb: item.line?.rgb ?? "#000000")
                            item.point = item.point ?? PointSpec(pointType: 0, pointSize: 1.0)
 
                            break
                        case .none:
                            break
                        }
                    }
                )) {
                    Text("lines").tag(PlotStyle.lines)
                    Text("points").tag(PlotStyle.points)
                    Text("linespoints").tag(PlotStyle.linespoints)
                    switch (item.source) {
                        case .function:
                        EmptyView()
                        case .file:
                        Text("yerrorbars").tag(PlotStyle.yerrorbars)
                    }
                    Text("dots").tag(PlotStyle.dots)
                    Text("impulses").tag(PlotStyle.impulses)
                }

                LineSpecEditor(plot: $item)
                if (item.point != nil) {
                    PointSpecEditor(point: $item.point)
                }
            }

            if (document.model.key.area != .unset) {
                Section("Legend") {
                    Toggle("Show Title", isOn: $item.showTitle)
                }
            }

            Section("Preview") {
                Text(item.toGnuplotCommand())
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .frame(maxHeight: .infinity)
    }

    // MARK: - File dialog

        private func openFilePanel() -> URL? {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            panel.allowedContentTypes = [] // or specify UTTypes like [.commaSeparatedText, .plainText]
            panel.title = "Choose Data File"
            panel.prompt = "Choose"
            if panel.runModal() == .OK {
                return panel.url
            }
            return nil
        }

        // MARK: - Bindings for enum-associated values (unchanged)

        private enum SourceKind { case function, file }

        private var bindingForSourceKind: Binding<SourceKind> {
            Binding<SourceKind>(
                get: {
                    switch item.source {
                    case .function: return .function
                    case .file: return .file
                    }
                },
                set: { newKind in
                    switch newKind {
                    case .function:
                        item.source = .function("x")
                        item.usingSpec = nil
                        if (item.with == .yerrorbars) {
                            item.with = .points
                            item.line = LineSpec(rgb: "#000000")
                            item.usingSpec = nil
                        }
                    case .file:
                        item.source = .file(path: "./data.txt")
                        if item.usingSpec == nil { item.usingSpec = UsingSpec(columns: ["1", "2"]) }
                    }
                }
            )
        }

        private var bindingForFunctionExpr: Binding<String> {
            Binding<String>(
                get: {
                    if case .function(let expr) = item.source { return expr }
                    return ""
                },
                set: { newValue in item.source = .function(newValue) }
            )
        }

        private var bindingForFilePath: Binding<String> {
            Binding<String>(
                get: {
                    if case .file(let path) = item.source { return path }
                    return ""
                },
                set: { newValue in item.source = .file(path: newValue) }
            )
        }
}
