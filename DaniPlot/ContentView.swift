import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var document: DaniPlotDocument

    var body: some View {
        NavigationSplitView {
            Sidebar(document: $document)
                .frame(minWidth: 340)
        } detail: {
            HStack {
                PlotEditor(document: $document)
                Divider()
                Divider()
                LivePreviewView(document: $document)
                                .frame(minWidth: 700, idealWidth: 840) // adjust to taste
            }
     
        }
        .navigationTitle(document.model.title.isEmpty ? "DaniPlot" : document.model.title)
        .toolbar {
            ToolbarItemGroup {
                Button("Add File Plot") {
                    document.model.plots.append(.file(
                        path: "./data.txt",
                        using: ["1", "2"],
                        with: .linespoints,
                        line: .init(lineType: 1, lineWidth: 1.5, rgb: "#333333"),
                        point: .init(pointType: 7, pointSize: 1.0),
                        title: "Series",
                        showTitle: true
                    ))
                }
                Button("Add Function Plot") {
                    document.model.plots.append(.function(
                        "x",
                        with: .lines,
                        line: .init(lineType: 1, lineWidth: 2.0, rgb: "grey"),
                        point: nil,
                        title: nil,
                        showTitle: false
                    ))
                }
            }
            ToolbarItem {
                    Button {
                        Task {
                            let err = await ExportService.export(model: document.model)
                            if let err {
                                // show alert as above
                                showExportError(err.message)
                            }
                        }
                    } label: {
                        Label("Export…", systemImage: "square.and.arrow.down")
                    }
                }
        }
    }
    
    @State private var exportAlert: String?

    private func showExportError(_ message: String) {
        exportAlert = message
        NSAlert(error: NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
            .runModal()
    }
}


#Preview {
    ContentView(document: .constant(
        DaniPlotDocument(
            model: DataModel(
                separator: "\t",
                title: "Sample Plot",
                xLabel: "x",
                yLabel: "y",
                format: .svg,
                xRange: .init(start: 0, end: 10),
                yRange: .init(start: 0, end: 10),
                xTics: .init(),
                yTics: .init(),
                plots: [
                    .function("x", with: .lines,
                              line: .init(lineType: 2, lineWidth: 2, rgb: "grey"),
                              point: nil, title: nil, showTitle: false),
                    .file(path: "./CV_S1_3D.txt", using: ["1","2","3"], with: .yerrorbars,
                          line: .init(lineType: nil, lineWidth: 2, rgb: "#A8D6A8"),
                          point: .init(pointType: 4, pointSize: 1),
                          title: " CV 10% ")
                ],
                version: 1
            )
        )
    ))
    .frame(minWidth: 900, minHeight: 600)
}
