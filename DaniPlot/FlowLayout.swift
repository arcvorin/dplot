import SwiftUI

// Top-level PreferenceKey (not nested in a generic type)
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FlowLayout<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var x = CGFloat.zero
        var y = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            content
                .alignmentGuide(.leading) { d in
                    if abs(x - d.width) > g.size.width {
                        x = 0
                        y -= d.height
                    }
                    let result = x
                    x -= d.width
                    return result
                }
                .alignmentGuide(.top) { d in
                    let result = y
                    return result
                }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}
