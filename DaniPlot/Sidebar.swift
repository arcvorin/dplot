//
//  Sidebar.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//
import SwiftUI

struct Sidebar: View {
    @Binding var document: DaniPlotDocument

    @State var currentMainMenu = 0
    @State var currentAxes = 0
    var key: some View {
        Form {
            Section("Key") {
                Picker("Region", selection:$document.model.key.area) {
                    Text("Inside").tag(Area.inside)
                    Text("Outside").tag(Area.outside)
                    Text("None").tag(Area.unset)
                }

                
                if (document.model.key.area != .unset) {
                    Picker("Layout", selection: $document.model.key.layout) {
                        Text("Vertical").tag(LegendLayout.vertical)
                        Text("Horizontal").tag(LegendLayout.horizontal)
                    }
                    
                    Picker("Label Justification", selection: $document.model.key.labelPosition) {
                        Text("Left").tag(LabelPosition.left)
                        Text("Right").tag(LabelPosition.right)
                    }
                    
                    Picker("Position", selection: $document.model.key.positionPickerValue) {
                        Text("Regular").tag("none")
                        Text("Custom").tag("position")
                    }
                    
                    if case .position(let x, let y) = document.model.key.position {
                        StepperFieldDouble(title: "X", value: Binding(get: {x}, set:{
                            document.model.key.position = .position(x: $0, y: y)
                        }), step: 0.1, range: -100...100)
                        StepperFieldDouble(title: "Y", value: Binding(get: {y}, set:{
                            document.model.key.position = .position(x: x, y: $0)
                        }), step: 0.1, range: -100...100)
                    }
                    
                    if (document.model.key.positionPickerValue != "position") {
                        Picker("Vertical", selection: $document.model.key.yDirection) {
                            Text("Top").tag(VerticalDirection.top)
                            Text("Bottom").tag(VerticalDirection.bottom)
                            Text("Center").tag(VerticalDirection.center)
                        }
                        Picker("Horizontal", selection: $document.model.key.xDirection) {
                            Text("Left").tag(HorizontalDirection.left)
                            Text("Right").tag(HorizontalDirection.right)
                            Text("Center").tag(HorizontalDirection.center)
                        }
                    }
                    
                    Picker("Vertical Spacing", selection: $document.model.key.verticalSpacingValue) {
                    Text ("Standard").tag("none")
                    Text("Custom").tag("number")
                    }
                    
                    if case .number(let y) = document.model.key.verticalSpacing {
                        StepperFieldDouble(title: "Spacing", value: Binding(get: {y}, set:{
                            document.model.key.verticalSpacing = .number($0)
                        }), step: 0.1, range: -100...100)
                    }
                    
                    Picker("Size", selection: $document.model.key.sizeValue) {
                    Text ("Standard").tag("none")
                    Text("Custom").tag("position")
                    }
                    
                    if case .position(let x, let y) = document.model.key.sizeOffset {
                        StepperFieldDouble(title: "Width Offset", value: Binding(get: {x}, set:{
                            document.model.key.sizeOffset = .position(x: $0, y: y)
                        }), step: 0.1, range: -100...100)
                        StepperFieldDouble(title: "Height Offset", value: Binding(get: {y}, set:{
                            document.model.key.sizeOffset = .position(x: x, y: $0)
                        }), step: 0.1, range: -100...100)
                    }
      
                    Picker("Box", selection: $document.model.key.boxPickerValue) {
                        Text("None").tag("none")
                        Text("Simple").tag("simple")
                        Text("Style").tag("custom-style")
                        Text("Custom").tag("custom-config")
                    }
          
                    if document.model.key.box.pickerValue == "custom-style" {
                        StepperFieldInt(title:"Style", value: Binding(
                            get: {
                                if case .custom(let style) = document.model.key.box {
                                    if case .number(let int) = style {
                                        return int
                                    }
                                }
                                return 0
                            },
                            set: {
                                document.model.key.box = .custom(.number($0))
                            }),range: 0...32 )
                    }
                    if document.model.key.box.pickerValue == "custom-config" {
                        StepperFieldInt(title:"Line Type", value: Binding(
                            get: {
                                let settings = boxCustomLineType()
                                if case .number(let intV) = settings?.lineType {
                                    return intV
                                }
                                return 0
                            },
                            set: {
                                let settings = boxCustomLineType()
                                if let settings = settings {
                                    document.model.key.box = .custom(.custom(.init(lineType: .number($0), lineWidth: settings.lineWidth)))
                                }
                            }),range: 0...32 )
                        StepperFieldDouble(title:"Line Width", value: Binding(
                            get: {
                                let settings = boxCustomLineType()
                                if case .number(let intV) = settings?.lineWidth {
                                    return intV
                                }
                                return 0
                            },
                            set: {
                                let settings = boxCustomLineType()
                                if let settings = settings {
                                    document.model.key.box = .custom(.custom(.init(lineType: settings.lineType, lineWidth: .number($0))))
                                }
                            }),step: 1, range: 0...32 )
                    }
                }
            }
        }.formStyle(.grouped)
    }
    
    var general : some View {
        Form {
            Section("General") {
                TextField("Title", text: $document.model.title)
                TextField("Separator", text: $document.model.separator)
                Picker("Format", selection: $document.model.format) {
                    Text("svg").tag(Format.svg)
                    Text("pdf").tag(Format.pdf)
                }
            }
            
            
            Section("Typography") {
                FontPicker(selection: $document.model.font)
                StepperFieldDouble(title: "Font Size", value: $document.model.fontPoints, step: 1, range: 0...100)
            }
        }.formStyle(.grouped)
    }
    
    var primaryAxes: some View {
        Form {
            Section("Axes") {
                TextField("X Label", text: $document.model.xLabel)
                TextField("Y Label", text: $document.model.yLabel)
                Toggle(isOn: $document.model.xLogScale, label: {
                    Text("Log X Scale")
                })
                Toggle(isOn: $document.model.yLogScale, label: {
                    Text("Log Y Scale")
                })
                
                RangeEditor(title: "X Range", range: $document.model.xRange)
                RangeEditor(title: "Y Range", range: $document.model.yRange)
            }

            Section("Tics") {
                
                TicsEditor(title: "X Tics", value: $document.model.xTics)
                TicsEditor(title: "Y Tics", value: $document.model.yTics)
            }
        }.formStyle(.grouped)

    }
    
    var secondaryAxes: some View {
        Form {
            Toggle(isOn: $document.model.secondaryAxes.enabled, label: {
                Text("Secondary Axes Enabled")
            })
            if (document.model.secondaryAxes.enabled) {
                Section("Secondary Axes") {
                    TextField("X2 Label", text: $document.model.secondaryAxes.xLabel)
                    TextField("Y2 Label", text: $document.model.secondaryAxes.yLabel)
                    Toggle(isOn: $document.model.secondaryAxes.xLogScale, label: {
                        Text("Log X2 Scale")
                    })
                    Toggle(isOn: $document.model.secondaryAxes.yLogScale, label: {
                        Text("Log Y2 Scale")
                    })
                    
                    RangeEditor(title: "X2 Range", range: $document.model.secondaryAxes.xRange)
                    RangeEditor(title: "Y2 Range", range: $document.model.secondaryAxes.yRange)
                }
                
                Section("Tics") {
                    
                    TicsEditor(title: "X2 Tics", value: $document.model.secondaryAxes.xTics)
                    TicsEditor(title: "Y2 Tics", value: $document.model.secondaryAxes.yTics)
                }
            }
        }.formStyle(.grouped)
    }
    
    var axes: some View {
        VStack {
            Picker(selection: $currentAxes) {
                Text("Primary").tag(0)
                Text("Secondary").tag(1)
            } label: {
                
            }.pickerStyle(.menu)
            .padding()
            switch(currentAxes) {
            case 0: self.primaryAxes
            case 1: self.secondaryAxes
            default: self.primaryAxes
            }
        }
    }
    
    
    var body: some View {
        HStack(spacing: 0) {
            Picker(selection: $currentMainMenu) {
                Text("General").tag(0)
                Text("Key").tag(1)
                Text("Axes").tag(2)
            } label: {
                
            }.pickerStyle(.segmented)
        }
        switch(currentMainMenu) {
        case 0: self.general
        case 1: self.key
        case 2: self.axes
        default: self.general
        }
    }

    
    func boxCustomLineType() -> CustomLineSettings? {
        if case .custom(let style) = document.model.key.box {
            if case .custom(let settings) = style {
                return settings
            }
        }
        return nil
    }

}
