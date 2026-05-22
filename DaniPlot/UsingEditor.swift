//
//  UsingEditor.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//
import SwiftUI

struct UsingEditor: View {
    @Binding var usingSpec: UsingSpec?

    @State private var usingText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Use columns", isOn: Binding(
                get: { usingSpec != nil },
                set: { on in
                    if on {
                        usingSpec = UsingSpec(columns: ["1", "2"])
                    } else {
                        usingSpec = nil
                    }
                    syncText()
                }
            ))
            if usingSpec != nil {
                HStack {
                    Text("Columns (e.g., 1:2:3)")
                    if #available(macOS 14.0, *) {
                        TextField("1:2[:3...]", text: $usingText)
                            .onChange(of: usingText) {
                                applyText()
                            }
                    } else {
                        TextField("1:2[:3...]", text: $usingText)
                            .onChange(of: usingText) { _ in
                                applyText()
                            }
                        // Fallback on earlier versions
                    }                }
                .onAppear { syncText() }
            }
        }
    }

    private func syncText() {
        usingText = (usingSpec?.columns ?? [])
            .joined(separator: ":")
    }

    private func applyText() {
        let tokens = usingText.split(separator: ":").map { "\($0)" }
        usingSpec?.columns = tokens
    }
}

struct LineTypeSelector: View {
    @Binding var plot: PlotItem
    
    var body: some View {
        if (plot.line != nil) {
            linePicker
        }
    }
    
    var numberedPicker: some View {
//        StepperFieldInt(title: "lt", value: Binding(
//            get: { plot.line?.lineType ?? 1 },
//            set: { plot.line?.lineType = $0 }
//        ), range: 0...32)
        EmptyView()
    }
    
    var linePicker: some View {
            Picker("Line Type", selection: Binding(get: {
                plot.line?.dash
            }, set: {dash in
                plot.line?.dash = dash
            })) {
                Text(".").tag("." as String?)
                Text("-").tag("-" as String?)
                Text(".-").tag(".-")
                Text("Continuous").tag(nil as String?)
            }
        }
}

struct LineSpecEditor: View {
    @Binding var plot: PlotItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
//            Toggle("Line Options", isOn: Binding(
//                get: { plot.line != nil },
//                set: { on in
//                    plot.line = on ? (plot.line ?? LineSpec(lineType: nil, lineWidth: 1.0, rgb: nil)) : nil
//                }
//            ))
            if plot.line != nil {
                if (plot.with == .lines || plot.with == .linespoints || plot.with == .yerrorbars || plot.with == .impulses) {
                    
                    
                    HStack {
                        if (plot.with != .yerrorbars) {
                            LineTypeSelector(plot: $plot)
                        }
                        StepperFieldDouble(title: "Line Width", value: Binding(
                            get: { plot.line?.lineWidth ?? 1.0 },
                            set: { plot.line?.lineWidth = $0 }
                        ), step: 0.5, range: 0.0...10.0)
                    }
                }
                ColorField(rgbString: Binding(
                    get: { plot.line?.rgb },
                    set: { new in plot.line?.rgb = new?.isEmpty == true ? nil : new }
                ))
            }
        }
    }
}

struct PointSpecEditor: View {
    @Binding var point: PointSpec?
    
    func isFilled() -> Bool {
        switch (point?.pointType ?? 0) {
        case 0, 1, 2, 3:
            return false
        case 4,6,8,10,12,14:
            return false
        case 5,7,9,11,13,15:
            return true
        default:
            return false
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
//            Toggle("Point Options", isOn: Binding(
//                get: { point != nil },
//                set: { on in
//                    point = on ? (point ?? PointSpec(pointType: 7, pointSize: 1.0)) : nil
//                }
//            ))
            if point != nil {
                HStack {
                    Picker("Point Type", selection: Binding(get: {
                        point?.pointType ?? 0
                    }, set: {pt in
                            point?.pointType = pt
                    })) {
                        Text("Point").tag(0)
                        Text("Plus").tag(1)
                        Text("Cross").tag(2)
                        Text("Star").tag(3)
                        if (!isFilled()) {
                            Text("Square").tag(4)
                            Text("Circle").tag(6)
                            Text("Triangle").tag(8)
                            Text("Upside Down Triangle").tag(10)
                            Text("Diamond").tag(12)
                            Text("Pentagon").tag(14)
                        } else {
                            Text("Square").tag(5)
                            Text("Circle").tag(7)
                            Text("Triangle").tag(9)
                            Text("Upside Down Triangle").tag(11)
                            Text("Diamond").tag(13)
                            Text("Pentagon").tag(15)
                        }
                    }
                    if (point?.pointType ?? 0 >= 4) {
                        Toggle("Filled", isOn: Binding(
                            get: { self.isFilled() },
                            set: { on in
                                if (on) {
                                    switch (self.point?.pointType ?? 0) {
                                    case 0, 1, 2, 3:
                                        self.point?.pointType = self.point?.pointType ?? 0
                                    default:
                                        self.point?.pointType = (self.point?.pointType ?? 0) + 1
                                    }
                                } else {
                                    switch (self.point?.pointType ?? 0) {
                                    case 0, 1, 2, 3:
                                        self.point?.pointType = self.point?.pointType ?? 0
                                    default:
                                        self.point?.pointType = (self.point?.pointType ?? 0) - 1
                                    }
                                }
                            })).toggleStyle(.checkbox)
                    }
                    
                    StepperFieldDouble(title: "Point Size", value: Binding(
                        get: { point?.pointSize ?? 1.0 },
                        set: { point?.pointSize = $0 }
                    ), step: 0.1, range: 0.0...10.0)
                }
            }
        }
    }
}
