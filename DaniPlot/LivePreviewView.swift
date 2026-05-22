import SwiftUI
import Combine

struct LivePreviewView: View {
    @Binding var document: DaniPlotDocument

    enum PreviewMode: String, CaseIterable, Identifiable {
        case image = "Image"
        case script = "Script"
        var id: String { rawValue }
    }

    @State private var mode: PreviewMode = .image
    @State private var script: String = ""

    @State private var isRendering = false
    @State private var result: RenderResult? = .none

    private let service = RenderService()

    // Debounce
    @State private var debouncer = PassthroughSubject<Void, Never>()
    @State private var cancellable: AnyCancellable?

    var body: some View {
        if #available(macOS 14.0, *) {
            VStack(spacing: 0) {
                header
                Divider()
                content
            }
            .task {
                setupDebounce()
                refreshScriptAndScheduleRender()
            }
            .onChange(of: document.model) {
                refreshScriptAndScheduleRender()
            }
        } else {
            VStack(spacing: 0) {
                header
                Divider()
                content
            }
            .task {
                setupDebounce()
                refreshScriptAndScheduleRender()
            }
            .onChange(of: document.model) { _ in
                refreshScriptAndScheduleRender()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Picker("Preview", selection: $mode) {
                ForEach(PreviewMode.allCases) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            if mode == .image {
                StepperFieldFloat(
                    title: "W",
                    value: $document.model.size.width,
                    range: 200...2400
                )
                StepperFieldFloat(
                    title: "H",
                    value: $document.model.size.height,
                    range: 200...2000
                )
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(script, forType: .string)
            } label: { Label("Copy Script", systemImage: "doc.on.doc") }

            Button {
                Task { await forceRenderNow() }
            } label: {
                isRendering ? AnyView(ProgressView().controlSize(.small)) : AnyView(Image(systemName: "arrow.clockwise"))
            }
            .buttonStyle(.plain)
            .help("Render now")
            Button {
                Task {
                    let err = await ExportService.export(model: document.model)
                    if let err {
                        showExportError(err.message)
                    }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.down")
            }
            .help("Render with gnuplot and save in the chosen format")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
    
    @State private var exportAlert: String?

    private func showExportError(_ message: String) {
        exportAlert = message
        NSAlert(error: NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
            .runModal()
    }
    
    @ViewBuilder
    private var content: some View {
        switch mode {
        case .image:
            if document.model.plots.isEmpty == false, let url = result?.url {
       
                switch result?.format {
                case .svg:
                    CenteredSVGView(svgURL: url, sizing: .actual)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                case .pdf:
                    PDFActualSizeView(url: url)
                case .tikz_pdf:
                    PDFActualSizeView(url: url)
                default:
                    Text("Unsupported format: \(result!.format)").font(.headline)
                }
         // white behind the web view
            } else {
                VStack(spacing: 8) {
                    Text("No image yet").font(.headline)
                    if result?.log == nil || result!.log.isEmpty {
                        Text(result?.log ?? "No Output.")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 560)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()

            DisclosureGroup("Render Log") {
                ScrollView {
                    Text(result?.log ?? "No Output.")
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 160)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

        case .script:
            VStack(spacing: 0) {
                ScrollView {
                    Text(script)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(Color(nsColor: .textBackgroundColor))

                Divider()

                DisclosureGroup("Render Log") {
                    ScrollView {
                        Text(result?.log ?? "No Output.")
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 160)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Debounce + render

    private func setupDebounce() {
        cancellable = debouncer
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { _ in Task { await forceRenderNow() } }
    }

    private func refreshScriptAndScheduleRender() {
        script = document.model.toGnuplotScript()
        debouncer.send(())
    }

    private func forceRenderNow() async {
        isRendering = true
        let res = await service.renderDocument(document.model)
        await MainActor.run {
            self.result = res
            self.isRendering = false
        }
    }
}
