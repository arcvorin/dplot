//
//  DaniPlotTests.swift
//  DaniPlotTests
//
//  Created by Arc Vorin on 2025-10-11.
//

import Testing
@testable import DaniPlot

struct DaniPlotTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    
    @Test func testScript() async throws {
        let model = DataModel.init(plots: [
            .function("x",
                          with: .lines,
                          line: .init(lineType: 2, lineWidth: nil, rgb: "grey"),
                          point: nil,
                          title: nil,
                          showTitle: false),
                .file(path: "./CV_S1_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "#A8D6A8"),
                      point: .init(pointType: 4, pointSize: 1),
                      title: " CV 10% "),
                .file(path: "./CV_S3_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "#97CF97"),
                      point: .init(pointType: 4, pointSize: 1),
                      title: " CV 30% "),
                .file(path: "./CV_S5_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "#69B569"),
                      point: .init(pointType: 4, pointSize: 1),
                      title: " CV 50% "),
                .file(path: "./CV_S7_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "#458945"),
                      point: .init(pointType: 4, pointSize: 1),
                      title: " CV 70% "),
                .file(path: "./CV_S9_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "#2D672D"),
                      point: .init(pointType: 4, pointSize: 1),
                      title: " CV 90% "),
                .file(path: "./Threshold_without_Intersection_3D.txt",
                      using: [1, 2, 3],
                      with: .yerrorbars,
                      line: .init(lineType: nil, lineWidth: 2, rgb: "black"),
                      point: .init(pointType: 6, pointSize: 1),
                      title: " Threshold ")
        ])
        #expect(model.plots[0].toGnuplotCommand() == """
        x w l lt 2 lc rgb "grey" notitle
        """)
        #expect(model.plots[1].toGnuplotCommand() == """
            './CV_S1_3D.txt' using 1:2:3 w yerrorbars pt 4 ps 1 lw 2 lc rgb "#A8D6A8" title " CV 10% "
            """)
        #expect(model.plots[2].toGnuplotCommand() == """
            './CV_S3_3D.txt' using 1:2:3 w yerrorbars pt 4 ps 1 lw 2 lc rgb "#97CF97" title " CV 30% "
            """)
        #expect(model.plots[3].toGnuplotCommand() == """
            './CV_S5_3D.txt' using 1:2:3 w yerrorbars pt 4 ps 1 lw 2 lc rgb "#69B569" title " CV 50% "
            """)
        #expect(model.plots[4].toGnuplotCommand() == """
            './CV_S7_3D.txt' using 1:2:3 w yerrorbars pt 4 ps 1 lw 2 lc rgb "#458945" title " CV 70% "
            """)
        #expect(model.plots[5].toGnuplotCommand() == """
            './CV_S9_3D.txt' using 1:2:3 w yerrorbars pt 4 ps 1 lw 2 lc rgb "#2D672D" title " CV 90% "
            """)
        #expect(model.plots[6].toGnuplotCommand() == """
            './Threshold_without_Intersection_3D.txt' using 1:2:3 w yerrorbars pt 6 ps 1 lw 2 lc rgb "black" title " Threshold "
            """)
    }
}
