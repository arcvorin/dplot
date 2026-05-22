//
//  RangeEditor.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//
import SwiftUI

struct RangeEditor: View {
    let title: String         // "X Range" / "Y Range"
    @Binding var range: Range // your Range type

    var body: some View {
        VStack(alignment: .leading,  spacing: 8) {
            Text(title)
                .font(.headline)

                HStack {
                    Text("Start")
                        .foregroundStyle(.secondary)
                    NumberStepper(value: $range.start, step: 0.5, range: -10_000...10_000)

                    Spacer()
                    Text("End")
                        .foregroundStyle(.secondary)
                    NumberStepper(value: $range.end, step: 0.5, range: -10_000...10_000)
                }
        }
        .padding(.vertical, 4)
    }
}

struct TicInput : View {
    @Binding var value: OptionalNumber
    @State var title: String
    @State var initialValue: Double = 0
    @State var displayToggle: Bool = true
    @State var didChangeStatus: ((_ isEnabled: Bool) -> Void)? = nil
    var body: some View {
        VStack {
            if case .number(let number) = value {
                HStack {
                    if (displayToggle) {
                        Toggle(isOn: Binding(get: {true}, set: {_ in
                            value = .none
                            if let didChangeStatus {
                                didChangeStatus(false)
                            }
                        }), label: {Text(title)})
                    }
                    StepperFieldDouble(title: displayToggle ? "" : title, value: Binding(get:{number}, set:{
                        value = .number($0)
                    }), step: 1, range: 0...100)
                }
            } else {
                Toggle(isOn: Binding(get: {false}, set: {_ in
                    value = .number(initialValue)
                    if let didChangeStatus {
                        didChangeStatus(true)
                    }
                }), label: {Text(title)})
            }
        }
    }
}

struct TicsEditor: View {
    let title: String
    @Binding var value: TicsSettings

    @State private var newValueText = ""
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Toggle(isOn: $value.incrementsEnabled, label:{Text("Increments")})
            if (value.incrementsEnabled) {
                TicInput(value: $value.incr, title: "Increment", displayToggle: false, didChangeStatus: {
                    status in
                    if (status == false) {
                        value.end = .none
                        value.start = .none
                    }
                })
                TicInput(value: $value.start, title: "Start", initialValue: 0, didChangeStatus: {
                    status in
                    if (status == false) {
                        value.end = .none
                    }
                })
                if (value.start.isEnabled) {
                    TicInput(value: $value.end, title: "End", initialValue: 100)
                }
            }
            // Chips row (scrollable horizontally if many)


            // Input row
            HStack(spacing: 8) {
                TextField("Add tic (number)", text: $newValueText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTic)
                    .frame(minWidth: 160)
                Button("Add", action: addTic)
                    .buttonStyle(.bordered)
            }

            // Optional: quick helpers
            HStack(spacing: 8) {
                if (!value.extra.isEmpty) {
                    Button("Clear") { value.extra.removeAll() }
                }
                
            }
            .font(.footnote)
            .buttonStyle(.link)
            .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(value.extra.enumerated()), id: \.offset) { i, v in
                        TicChip(value: v) {
                            value.extra.remove(at: i)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.2))
            )
        }
    }

    private func addTic() {
        let trimmed = newValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let d = Double(trimmed) else { return }
        value.extra.append(d)
        // Deduplicate with tolerance and sort
        value.extra = dedupAndSort(value.extra)
        newValueText = ""
    }

    private func dedupAndSort(_ arr: [Double]) -> [Double] {
        let eps = 1e-9
        let sorted = arr.sorted()
        var out: [Double] = []
        for x in sorted {
            if let last = out.last, abs(last - x) < eps {
                continue
            }
            out.append(x)
        }
        return out
    }
}

private struct TicChip: View {
    let value: Double
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(value.formatted())
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .controlAccentColor).opacity(0.15))
                )
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct NumberStepper: View {
    @Binding var value: Double
    var step: Double = 0.5
    var range: ClosedRange<Double> = -10_000...10_000
    var width: CGFloat = 70

    var body: some View {
        HStack(spacing: 6) {
            TextField("", value: $value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
    }
}

struct StepperFieldDouble: View {
    let title: String
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            TextField(title, value: $value, format: .number)
                
            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()

        }
    }
}

struct StepperFieldFloat: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        HStack {
            TextField(title, value: $value, format: .number)
                
            Stepper("", value: $value, in: range, step: 1)
                .labelsHidden()
        }
    }
}


struct StepperFieldInt: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            TextField(title, value: $value, format: .number)
            Stepper("", value: $value, in: range, step: 1)
                .labelsHidden()

        }
    }
}
