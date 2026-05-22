import SwiftUI

struct PlotEditor: View {
    @Binding var document: DaniPlotDocument
    @State private var selection: Int? = nil  // index into document.model.plots

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(Array(document.model.plots.enumerated()), id: \.offset) { index, p in
                    Text(brief(p))
                        .tag(index)
                        .contextMenu {
                            Button {
                                let plot = document.model.plots[index]
                                let copy = plot.copyWith(title: plot.title != nil ? "\(plot.title ?? "New Plot") (copy)" : "\(brief(plot)) (copy)")
                                document.model.plots.insert(copy, at: index)
                            } label: {
                                Label("Duplicate", systemImage: "plus")
                            }
                            Button(role: .destructive) {
                                document.model.plots.remove(at: index)
                                if selection == index { selection = nil }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove(perform: {
                    indices, newOffset in
                    document.model.plots.move(fromOffsets: indices, toOffset: newOffset)
                })
            }.frame(minWidth: 50, maxHeight: 200)
            Divider()
            if let i = selection, document.model.plots.indices.contains(i) {
                           SinglePlotEditor(item: $document.model.plots[i], document: $document)
                    .id(i
                    )
                       } else {
                           if #available(macOS 14.0, *) {
                               ContentUnavailableView("No Plot Selected",
                                                      systemImage: "chart.xyaxis.line",
                                                      description: Text("Select a plot to edit."))
                               .frame(maxWidth: .infinity, maxHeight: .infinity)
                           } else {
                               PlaceholderView(title: "No Plot Selected", systemImage: "chart.xyaxis.line", description: "Select a plot to edit.")
                               // Fallback on earlier versions
                           }
                       }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    addFilePlot()
                } label: {
                    Label("Add File Plot", systemImage: "plus")
                }
                Button(role: .destructive, action: deleteSelected) {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selection == nil)
                // Optional: move up/down buttons
                Button(action: moveUp) {
                    Image(systemName: "arrow.up")
                }
                .disabled(!(selection.map { $0 > 0 } ?? false))
                Button(action: moveDown) {
                    Image(systemName: "arrow.down")
                }
                .disabled(!(selection.map { $0 < document.model.plots.count - 1 } ?? false))
            }
        }
    }

    private func brief(_ p: PlotItem) -> String {
        if let title = p.title {
            return title
        }
        switch p.source {
        case .function(let expr): return "\(expr) \(p.with?.rawValue ?? "")"
        case .file(let path): return "\(path) \(p.with?.rawValue ?? "")"
        }
    }

    private func addFilePlot() {
        document.model.plots.append(
            .file(path: "./data.txt",
                  using: ["1", "2"],
                  with: .linespoints,
                  line: .init(lineType: 1, lineWidth: 1.5, rgb: "#333333"),
                  point: .init(pointType: 7, pointSize: 1.0),
                  title: "Series",
                  showTitle: true)
        )
        selection = document.model.plots.count - 1
    }

    private func deleteSelected() {
        guard let i = selection, document.model.plots.indices.contains(i) else { return }
        document.model.plots.remove(at: i)
        selection = nil
    }

    private func moveUp() {
        guard let i = selection, i > 0 else { return }
        document.model.plots.swapAt(i, i - 1)
        selection = i - 1
    }

    private func moveDown() {
        guard let i = selection, i < document.model.plots.count - 1 else { return }
        document.model.plots.swapAt(i, i + 1)
        selection = i + 1
    }
}
