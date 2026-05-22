//
//  DaniPlotDocument.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//

import SwiftUI
import UniformTypeIdentifiers

import FoundationModels

nonisolated extension UTType
 {
    static let daniPlotDoc = UTType(exportedAs: "me.javiermatusevich.DaniPlot.dplot",
                              conformingTo: .json)
}

// Data source: a function expression or a file path
nonisolated enum PlotSource: Codable, Equatable, Hashable {
    case function(String)     // e.g., "x"
    case file(path: String)   // e.g., "./CV_S1_3D.txt"

    enum CodingKeys: String, CodingKey { case kind, value, path }
    enum Kind: String, Codable { case function, file }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .function:
            self = .function(try c.decode(String.self, forKey: .value))
        case .file:
            self = .file(path: try c.decode(String.self, forKey: .path))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .function(let expr):
            try c.encode(Kind.function, forKey: .kind)
            try c.encode(expr, forKey: .value)
        case .file(let path):
            try c.encode(Kind.file, forKey: .kind)
            try c.encode(path, forKey: .path)
        }
    }
}

// Column mapping for "using"
nonisolated struct UsingSpec: Codable, Equatable, Hashable {
    // Basic: x:y or x:y:yerror (your example uses 1:2:3)
    // You can extend with optional via, every, index, etc.
    var columns: [String] // e.g., [1,2,3]
}

// Style options for "with" (w), line, point, color
nonisolated enum PlotStyle: String, Codable, Equatable, Hashable {
    // Extend as needed
    case lines = "lines"              // l
    case points = "points"            // p
    case linespoints = "linespoints"  // lp
    case yerrorbars = "yerrorbars"    // yerrorbars
    case dots = "dots"
    case impulses = "impulses"
}

nonisolated struct LineSpec: Codable, Equatable, Hashable {
    var lineType: Int?    // lt
    var lineWidth: Double? // lw
    var dash: String?
    // You can support rgb or palette; here we model rgb as hex or named
    var rgb: String?      // e.g., "#A8D6A8" or "grey" or "black"
}

nonisolated struct PointSpec: Codable, Equatable, Hashable {
    var pointType: Int?   // pt
    var pointSize: Double? // ps
}

nonisolated enum PossibleAxes: String, Codable, Equatable, Hashable {
    case one, two
    
    func value() -> Int {
        switch self {
        case .one: return 1
        case .two: return 2
        }
    }
}

nonisolated struct ChosenAxes: Codable, Equatable, Hashable {
    var x: PossibleAxes = .one
    var y: PossibleAxes = .one
}
// The main plot item
nonisolated struct PlotItem: Codable, Equatable, Identifiable, Hashable {
    var source: PlotSource
    var usingSpec: UsingSpec?        // only relevant when source is .file typically
    var with: PlotStyle?             // "with" clause (w)
    var line: LineSpec?              // lt, lw, lc rgb
    var point: PointSpec?            // pt, ps
    var title: String?               // title or nil means not specified
    var showTitle: Bool              // notitle if false
    var id = UUID()
    var axes = ChosenAxes()
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try container.decode(PlotSource.self, forKey: .source)
        self.usingSpec = try container.decodeIfPresent(UsingSpec.self, forKey: .usingSpec)
        self.with = try container.decodeIfPresent(PlotStyle.self, forKey: .with)
        self.line = try container.decodeIfPresent(LineSpec.self, forKey: .line)
        self.point = try container.decodeIfPresent(PointSpec.self, forKey: .point)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.showTitle = try container.decode(Bool.self, forKey: .showTitle)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.axes = (try? container.decode(ChosenAxes.self, forKey: .axes)) ?? ChosenAxes()
    }
    
    
    init(source: PlotSource, usingSpec: UsingSpec? = nil, with: PlotStyle? = nil, line: LineSpec? = nil, point: PointSpec? = nil, title: String? = nil, showTitle: Bool = true) {
        self.source = source
        self.usingSpec = usingSpec
        self.with = with
        self.line = line
        self.point = point
        self.title = title
        self.showTitle = showTitle
    }

    // Convenience ctor for a file-based item
    static func file(
        path: String,
        using columns: [String]? = nil,
        with style: PlotStyle? = nil,
        line: LineSpec? = nil,
        point: PointSpec? = nil,
        title: String? = nil,
        showTitle: Bool = true
    ) -> PlotItem {
        PlotItem(
            source: .file(path: path),
            usingSpec: columns.map { UsingSpec(columns: $0) },
            with: style,
            line: line,
            point: point,
            title: title,
            showTitle: showTitle
        )
    }

    // Convenience ctor for a function-based item
    static func function(
        _ expr: String,
        with style: PlotStyle? = nil,
        line: LineSpec? = nil,
        point: PointSpec? = nil,
        title: String? = nil,
        showTitle: Bool = true
    ) -> PlotItem {
        PlotItem(
            source: .function(expr),
            usingSpec: nil,
            with: style,
            line: line,
            point: point,
            title: title,
            showTitle: showTitle
        )
    }
}

nonisolated extension PlotItem {
    
    func copyWith(with: PlotStyle? = nil, line: LineSpec? = nil, point: PointSpec? = nil, showTitle: Bool? = nil, title: String? = nil) -> PlotItem {

        var copy = PlotItem(source: source, showTitle: showTitle ?? self.showTitle)
        copy.usingSpec = self.usingSpec
        copy.title = self.title
        copy.with = with ?? self.with
        copy.line = line ?? self.line
        copy.point = point ?? self.point
        copy.title = title ?? self.title
        return copy
    }
    
    func toGnuplotCommand() -> String {
        var parts: [String] = []

        var extraCommands: [String] = []
        // Source
        switch source {
        case .function(let expr):
            parts.append(expr)
        case .file(let path):
            // quote the path
            parts.append("'\(path)'")
            if let u = usingSpec, !u.columns.isEmpty {
                let cols = u.columns.joined(separator: ":")
                parts.append("using \(cols)")
            }
        }
        
        parts.append("axes x\(axes.x.value())y\(axes.y.value())")
        

        // with
        if let w = with {
            switch w {
            case .lines: parts.append("w l")
            case .points: parts.append("w p")
            case .linespoints: parts.append("w lp")
            case .yerrorbars:
                parts.append("w yerrorbars")

                if let p = point {
                    if let pt = p.pointType, pt.isMultiple(of: 2) {
                        var figure = self.copyWith(with:.points, point:.init(pointType: pt + 1, pointSize: p.pointSize))
                        figure.line?.rgb = "white"
                        figure.showTitle = false
                        extraCommands.append(figure.toGnuplotCommand())
                    }
                    
                }
                extraCommands.append(self.copyWith(with:.points).toGnuplotCommand())
            default:
                parts.append("w \(w.rawValue)")
            }
        }

        // point spec
        if let p = point {
            if let with = with, with == .yerrorbars { parts.append("pt 0 ps 0") } else {
                if let pt = p.pointType { parts.append("pt \(pt)") }
                if let ps = p.pointSize { parts.append("ps \(String(format: "%.3g", ps))") }
            }
        }

        // line spec
        if let l = line {
                if let lt = l.lineType { parts.append("lt \(lt)") }
                if let dash = l.dash { parts.append("dashtype \'\(dash)\'") }
                if let lw = l.lineWidth { parts.append("lw \(String(format: "%.3g", lw))") }
                if let rgb = l.rgb { parts.append("lc rgb \"\(rgb)\"") }
        }

        // title / notitle
        if showTitle, let with = with, with != .yerrorbars {
                if let t = title {
                    parts.append("title \"\(t)\"")
                } else {
                    switch self.source {
                    case .function(let expr): parts.append("title \"\(expr)\"")
                    case .file(let path): parts.append("title\"\(path)\"")
                    }
                    // If title is nil but showTitle == true, gnuplot will auto-derive.
                }
        } else {
            parts.append("notitle")
        }

        var commands: [String] = [parts.joined(separator: " ")]
        commands.append(contentsOf: extraCommands)
        
        return commands.joined(separator: ", \\\n  ")
    }
}

nonisolated struct Range: Codable, Equatable {
    var start: Double
    var end: Double
}

nonisolated struct FloatSize: Codable, Equatable {
    var width: Float
    var height: Float
}

nonisolated enum Format: String, Codable, Equatable {
    case svg
    case pdf
    case tikz
    case tikz_pdf
    func intermediateExtensionString() -> String {
        switch self {
        case .svg: return "svg"
        case .pdf: return "pdf"
        case .tikz: return "tex"
        case .tikz_pdf: return "tex"
        }
    }
    
    func finalExtensionString() -> String {
        switch self {
        case .svg: return "svg"
        case .pdf: return "pdf"
        case .tikz: return "tex"
        case .tikz_pdf: return "pdf"
        }
    }
}

nonisolated enum VerticalDirection: Codable, Equatable, Hashable {
    case top
    case bottom
    case center
    case none
    func representation() -> String {
        switch(self) {
        case .bottom:
            return "bottom"
        case .top:
            return "top"
        case .center:
            return "center"
        case .none:
            return ""
        }
    }
}

nonisolated enum HorizontalDirection: Codable, Equatable, Hashable {
    case left
    case right
    case center
    case none
    
    func representation() -> String {
        switch(self) {
        case .right:
            return "right"
        case .left:
            return "left"
        case .center:
            return "center"
        case .none:
            return ""
        }
    }
}

nonisolated enum MarginDirection: String, Codable, Equatable, Hashable {
    case top = "top"
    case left = "left"
    case right = "right"
    case bottom = "bottom"
    case none = "none"
    case all = "all"
}

nonisolated enum Area: Codable, Equatable, Hashable {
    case outside
    case inside
    case fixed
    case unset
    func representation() -> String {
        switch(self) {
        case .outside:
            return "outside"
        case .inside:
            return "inside"
        case .fixed:
            return "fixed"
        case .unset:
            return ""
        }
    }
}

nonisolated struct Margin: Codable, Equatable, Hashable {
    var position: MarginDirection
    var value: Double
    func representation() -> String {
            switch(position) {
            case .bottom:
                return "bmargin"
            case .top:
                return "tmargin"
            case .all:
                return "margin"
            case .none:
                return ""
            case .left:
                return "lmargin"
            case .right:
                return "rmargin"
            }
    }
}

nonisolated enum LegendPosition: Codable, Equatable, Hashable {
    case none
    case position(x: Double, y: Double)
    func representationAt() -> String {
        switch self {
        case .none:
            return ""
        case .position(x: let x, y: let y):
            return "at \(x),\(y)"
        }
    }
    
    func representationOffset() -> String {
        switch self {
        case .none:
            return ""
        case .position(x: let x, y: let y):
            return "offset \(x),\(y)"
        }
    }
    
    func representationSize() -> String {
        switch self {
        case .none:
            return ""
        case .position(x: let x, y: let y):
            return "width \(x) height \(y)"
        }
    }

    var pickerValue: String {
        switch self {
        case .none:
            return "none"
        case .position:
            return "position"
        }
    }
}

nonisolated enum LineStyle: Codable, Equatable, Hashable {
    case number(Int)
    case custom(CustomLineSettings)
    case none
    
    func representation() -> String {
        switch self {
        case .number(let v):
            return "ls \(v)"
        case .custom(let v):
            return v.representation()
        case .none:
            return ""
        }
    }
}

nonisolated struct CustomLineSettings : Codable, Equatable, Hashable {
    var lineType: LineType = .none
    var lineWidth: LineWidth = .none
    func representation() -> String {
        let value = "\(lineType.representation()) \(lineWidth.representation())"
        if value.count >= 1 {
            return value
        }
        return ""
    }
}

nonisolated enum LineType: Codable, Equatable, Hashable {
    case number(Int)
    case none
    
    func representation() -> String {
        switch self {
        case .number(let v):
            return "lt \(v)"
        case .none:
            return ""
        }
    }
}

nonisolated enum LineWidth: Codable, Equatable, Hashable {
    case number(Double)
    case none
    
    func representation() -> String {
        switch self {
        case .number(let v):
            return "lw \(v)"
        case .none:
            return ""
        }
    }
}



nonisolated enum LegendBox: Codable, Equatable, Hashable {
    case none
    case simple
    case custom(LineStyle)
    
    func representation() -> String {
        switch self {
        case .none:
            return ""
        case .simple:
            return "box"
        case .custom(let v):
            return "box \(v.representation())"
        }
    }
    
    var pickerValue : String {
        get {
            switch self {
            case .none:
                return "none"
            case .simple:
                return "simple"
            case .custom(let v):
                switch v {
                case .none:
                    return "none"
                case .number(_):
                    return "custom-style"
                case .custom(_):
                    return "custom-config"
                }
            }
        }
    }
}

nonisolated enum LabelPosition: Codable, Equatable, Hashable {
    case left
    case right
    
    func repreentation() -> String {
        switch self {
        case .left:
            return "Left"
        case .right:
            return "Right"
        }
    }
}

nonisolated enum VerticalSpacing: Codable, Equatable, Hashable {
    case number(Double)
    case none
    
    func representation() -> String {
        switch self {
        case .number(let v):
            return "spacing \(v)"
        case .none:
            return ""
        }
    }
}

nonisolated enum LegendLayout: Codable, Equatable, Hashable {
    case horizontal
    case vertical
    
    func representation() -> String {
        switch self {
        case .horizontal:
            return "horizontal"
        case .vertical:
            return "vertical"
        }
    }
}

nonisolated struct GraphKey: Codable, Equatable,Hashable {
    var area: Area = .unset
    var xDirection: HorizontalDirection = .left
    var yDirection: VerticalDirection = .top
    var position: LegendPosition = .none
    var offset: LegendPosition = .none
    var sizeOffset: LegendPosition = .position(x: 0, y: 0)
    var verticalSpacing: VerticalSpacing = .none
    var box: LegendBox = .simple
    var labelPosition: LabelPosition = .right
    var layout: LegendLayout = .vertical
    func command() -> String {
        if (area == .unset) {
            return "unset key"
        }
        return "set key \(area.representation()) \(position.representationAt()) \(xDirection.representation()) \(yDirection.representation()) \(offset.representationOffset()) \(verticalSpacing.representation()) \(layout.representation()) \(labelPosition.repreentation()) \(sizeOffset.representationSize()) \(box.representation())".replacingOccurrences(of: "  ", with: " ")
    }
    
    var positionPickerValue: String {
        get {
            position.pickerValue
        }
        set {
            switch newValue {
            case "none":
                position = .none
                xDirection = .right
                yDirection = .top
            case "position":
                position = .position(x: 0, y: 0)
                xDirection = .center
                yDirection = .center
            default:
                position = .none
            }
        }
    }
    
    var verticalSpacingValue: String {
        get {
            if case .number(let v) = verticalSpacing {
                return "number"
            }
            return "none"
        } set {
            switch newValue {
            case "none":
                verticalSpacing = .none
            case "number":
                verticalSpacing = .number(1)
            default:
                verticalSpacing = .none
            }
            
        }
    }
    var boxPickerValue: String {
        get {
            box.pickerValue
        }
        set {
            switch newValue {
            case "none":
                box = .none
            case "simple":
                box = .simple
            case "custom-style":
                box = .custom(.number(0))
            case "custom-config":
                box = .custom(.custom(.init(lineType: .number(0))))
            default:
                box = .none
            }
        }
    }
    
    var sizeValue: String {
        get {
            if case .position(let x, let y) = sizeOffset {
                return "position"
            }
            return "none"
        }
        set {
            switch newValue {
            case "none":
                sizeOffset = .none
            case "position":
                sizeOffset = .position(x: 0, y: 0)
            default:
                sizeOffset = .none
            }
        }
    }
}


nonisolated enum OptionalNumber: Codable, Equatable {
    case none
    case number(Double)
    
    var isEnabled: Bool {
        switch self {
        case .none:
            return false
        case .number:
            return true
        }
    }
}

nonisolated struct TicsSettings: Codable, Equatable {
    var start: OptionalNumber = .none
    var end: OptionalNumber = .none
    var incr: OptionalNumber = .number(1.0)
    var extra: [Double] = []
    
    var incrementsEnabled: Bool {
        get {
            !(self.incr == .none && self.end == .none && self.start == .none)
        }
        set {
            if (newValue) {
                incr = .number(1.0)
            } else {
                incr = .none
                end = .none
                start = .none
            }
        }
    }
    
    func representation() -> String {
        var string = ""
        if case .number(let incr) = self.incr {
            string.append("\(incr)")
            if case .number(let start) = self.start {
                string = "\(start),\(string)"
                if case .number(let end) = self.end {
                    string.append(",\(end)")
                }
            }
            if !self.extra.isEmpty {
                string.append("add (\(self.extra.map(\.description).joined(separator: ",")))")
            }
            return string
        }
        if (!self.extra.isEmpty) {
            string.append("(\(self.extra.map(\.description).joined(separator: ",")))")
        }
        return string
    }
}

nonisolated struct  SecondaryAxesSettings: Codable, Equatable {
    var xLabel: String = "x2"
    var yLabel: String = "y2"
    var xRange: Range = .init(start: 0.0, end: 10.0)
    var yRange: Range = .init(start: 0.0, end: 20.0)
    var xTics: TicsSettings = .init()
    var yTics: TicsSettings = .init()
    var xLogScale: Bool = false
    var yLogScale: Bool = false
    var enabled: Bool = false
}

nonisolated struct DataModel: Codable, Equatable {
    var separator: String = #"\t"#
    var title: String = "Untitled"
    var font: String = "Arial"
    var fontPoints: Double = 12
    var size: FloatSize = .init(width: 5, height: 5)
    var xLabel: String = "x"
    var yLabel: String = "y"
    var format: Format = .svg
    var xRange: Range = .init(start: 0.0, end: 10.0)
    var yRange: Range = .init(start: 0.0, end: 10.0)
    var xTics: TicsSettings = .init()
    var yTics: TicsSettings = .init()
    var plots: [PlotItem] = []
    var key: GraphKey = .init()
    var version: Int = 1
    var xLogScale: Bool = false
    var yLogScale: Bool = false
    var secondaryAxes: SecondaryAxesSettings = .init()
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.separator = try container.decode(String.self, forKey: .separator)
        self.title = try container.decode(String.self, forKey: .title)
        self.font = try container.decode(String.self, forKey: .font)
        self.fontPoints = try container.decode(Double.self, forKey: .fontPoints)
        self.size = try container.decode(FloatSize.self, forKey: .size)
        self.xLabel = try container.decode(String.self, forKey: .xLabel)
        self.yLabel = try container.decode(String.self, forKey: .yLabel)
        self.format = try container.decode(Format.self, forKey: .format)
        self.xRange = try container.decode(Range.self, forKey: .xRange)
        self.yRange = try container.decode(Range.self, forKey: .yRange)
        self.xTics = try container.decode(TicsSettings.self, forKey: .xTics)
        self.yTics = try container.decode(TicsSettings.self, forKey: .yTics)
        self.plots = try container.decode([PlotItem].self, forKey: .plots)
        self.key = try container.decode(GraphKey.self, forKey: .key)
        self.version = try container.decode(Int.self, forKey: .version)
        self.xLogScale = try container.decode(Bool.self, forKey: .xLogScale)
        self.yLogScale = try container.decode(Bool.self, forKey: .yLogScale)
        self.secondaryAxes = (try? container.decode(SecondaryAxesSettings.self, forKey: .secondaryAxes)) ?? .init()
    }
    
    init(
        separator: String = #"\t"#,
        title: String = "Untitled",
        font: String = "Arial",
        fontPoints: Double = 12,
        size: FloatSize = .init(width: 5, height: 5),
        xLabel: String = "x",
        yLabel: String = "y",
        format: Format = .svg,
        xRange: Range = .init(start: 0.0, end: 10.0),
        yRange: Range = .init(start: 0.0, end: 10.0),
        xTics: TicsSettings = .init(),
        yTics: TicsSettings = .init(),
        plots: [PlotItem] = [],
        key: GraphKey = .init(),
        version: Int = 1,
        xLogScale: Bool = false,
        yLogScale: Bool = false,
        secondaryAxes: SecondaryAxesSettings = .init()
    ) {
        self.separator = separator
        self.title = title
        self.font = font
        self.fontPoints = fontPoints
        self.size = size
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.format = format
        self.xRange = xRange
        self.yRange = yRange
        self.xTics = xTics
        self.yTics = yTics
        self.plots = plots
        self.key = key
        self.version = version
        self.xLogScale = xLogScale
        self.yLogScale = yLogScale
        self.secondaryAxes = secondaryAxes
    }
}

nonisolated struct ExportDimensions {
    var inchesW: Float
    var inchesH: Float
    var fontPt: Double

    var pdfSize: (width: Float, height: Float, fontSize: Int) { (inchesW, inchesH, Int(fontPt)) }
    var svgSize: (width: Float, height: Float, fontSize: Int) {
        let wpx = Int((inchesW * 96).rounded())
        let hpx = Int((inchesH * 96).rounded())
        return (Float(wpx), Float(hpx), Int(fontPt))
    }

}

nonisolated extension DataModel {
    func toGnuplotScript(outURL: URL? = nil) -> String {
        
        let exportDimensions = ExportDimensions(inchesW: size.width, inchesH: size.height, fontPt: fontPoints)
        var s = ""
        switch format {
        case .svg:
            s += "set terminal svg size \(exportDimensions.svgSize.width),\(exportDimensions.svgSize.height) font \"\(font),\(exportDimensions.svgSize.fontSize)pt\" dynamic \n"
        case .pdf:
            s += "set terminal pdfcairo color size \(exportDimensions.pdfSize.width)in,\(exportDimensions.pdfSize.height)in font \"\(font),\(exportDimensions.pdfSize.fontSize)\"  \n"
        case .tikz:
            s += "set terminal tikz size \(exportDimensions.pdfSize.width)in,\(exportDimensions.pdfSize.height)in font \"\(font),\(exportDimensions.pdfSize.fontSize)\"  \n"
        case .tikz_pdf:
            s += "set terminal tikz size \(exportDimensions.pdfSize.width)in,\(exportDimensions.pdfSize.height)in font \"\(font),\(exportDimensions.pdfSize.fontSize)\"  \n"
        default:
            assertionFailure("Format \(format) not supported")
        }
        s += "set output '\(outURL?.path ?? "output.\(format.intermediateExtensionString())")'\n"

        s += "set pointintervalbox 0 \n"
        s += "set datafile separator \"\(separator)\"\n"
        s += "set title \"\(title)\"\n"
        s += "set xlabel \"\(xLabel)\"\n"
        s += "set ylabel \"\(yLabel)\"\n"
        s += "set xrange [\(xRange.start):\(xRange.end)]\n"
        s += "set yrange [\(yRange.start):\(yRange.end)]\n"
        if (xLogScale) {
            s += "set logscale x\n"
        }
        if (yLogScale) {
            s += "set logscale y\n"
        }
        
        s += "set border lw 2 \n"
        s += "set xtics \(xTics.representation())\n"
        s += "set ytics \(yTics.representation())\n"
        
        if (secondaryAxes.enabled) {
            s += "set x2label \"\(secondaryAxes.xLabel)\"\n"
            s += "set y2label \"\(secondaryAxes.yLabel)\"\n"
            s += "set x2range [\(secondaryAxes.xRange.start):\(secondaryAxes.xRange.end)]\n"
            s += "set y2range [\(secondaryAxes.yRange.start):\(secondaryAxes.yRange.end)]\n"
            if (secondaryAxes.xLogScale) {
                s += "set logscale x2\n"
            }
            if (secondaryAxes.yLogScale) {
                s += "set logscale y2\n"
            }
            
            s += "set x2tics \(secondaryAxes.xTics.representation())\n"
            s += "set y2tics \(secondaryAxes.yTics.representation())\n"
        }
        
        s += "\(key.command())\n"
        if !plots.isEmpty {
            s += "plot \\\n  " + plots.map { $0.toGnuplotCommand() }
                .joined(separator: ", \\\n  ")
            s += "\n"
        }
        s += "\nunset output\n"

        return s
    }
}

nonisolated struct DaniPlotDocument: FileDocument {
    var model: DataModel

    init(model: DataModel = .init()) {
          self.model = model
      }

    static let readableContentTypes: [UTType] = [.daniPlotDoc]
    static let writableContentTypes: [UTType] = [.daniPlotDoc]
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
                   throw CocoaError(.fileReadCorruptFile)
               }
               do {
                   self.model = try JSONDecoder().decode(DataModel.self, from: data)
               } catch {
                   print("Decode error")
                   print(error)
                   // You can provide schema migration here if needed
                   throw CocoaError(.fileReadCorruptFile, userInfo: [
                       NSDebugDescriptionErrorKey: "Invalid Encoding: \(error)"
                   ])
               }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(model)
            return .init(regularFileWithContents: data)
    }
}
