//
//  SVGWebView.swift
//  DaniPlot
//
//  Created by Arc Vorin on 2025-10-11.
//


import SwiftUI
import WebKit

struct SVGWebView: NSViewRepresentable {
    let svgURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.setValue(false, forKey: "drawsBackground")
        wv.allowsBackForwardNavigationGestures = false
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let svgURL else {
            webView.loadHTMLString("<html><body style='font-family:-apple-system;color:#888'>No SVG</body></html>", baseURL: nil)
            return
        }
        webView.loadFileURL(svgURL, allowingReadAccessTo: svgURL.deletingLastPathComponent())
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {}
}

struct CenteredSVGView: NSViewRepresentable {
    let svgURL: URL
    // choose how to size the SVG
    enum Sizing { case actual, fit }
    var sizing: Sizing = .actual

    func makeNSView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.setValue(false, forKey: "drawsBackground")
        wv.layer?.backgroundColor = NSColor.white.cgColor
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        // We center via flexbox; for "fit" we constrain max width/height to viewport
        let fitCSS: String
        switch sizing {
        case .actual:
            // no scaling; let the SVG’s own width/height decide its size
            fitCSS = """
            img, object, embed { max-width:none; max-height:none; }
            """
        case .fit:
            fitCSS = """
            img, object, embed { max-width:100%; max-height:100%; }
            """
        }

        let html = """
        <!doctype html>
        <meta charset="utf-8">
        <style>
          html, body {
            height: 100%;
            margin: 0;
            background: #fff;
          }
          .wrap {
            display: flex;
            align-items: center;        /* vertical center */
            justify-content: center;    /* horizontal center */
            height: 100vh;              /* full viewport height */
            width: 100vw;               /* full viewport width */
            background: #fff;
          }
          \(fitCSS)
        </style>
        <div class="wrap">
          <img src="\(svgURL.lastPathComponent)" alt="svg" />
        </div>
        """
        // Use baseURL to grant access to the file folder
        wv.loadHTMLString(html, baseURL: svgURL.deletingLastPathComponent())
    }
}

import PDFKit

struct PDFActualSizeView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = false
        v.displayMode = .singlePage
        v.displaysPageBreaks = false      // no shadow/edge/border between page and background
        v.pageShadowsEnabled = false
        v.backgroundColor = .white        // same as plot background

        if let doc = PDFDocument(url: url) {
            v.document = doc
            if let page = doc.page(at: 0) {
                // PDF size in points (1 pt = 1/72 in)
                let box = page.bounds(for: .mediaBox).size
                // Actual-size scale so 72pt -> 96 CSS px (common mapping)
                let scale = 96.0 / 72.0
                v.scaleFactor = CGFloat(scale)

                // Optionally size the view to the page at actual size
                let cssSize = NSSize(width: box.width * scale, height: box.height * scale)
                v.setFrameSize(cssSize)
            }
        }
        return v
    }

    func updateNSView(_ v: PDFView, context: Context) {
        // nothing
        if let doc = PDFDocument(url: url) {
            v.document = doc
            if let page = doc.page(at: 0) {
                // PDF size in points (1 pt = 1/72 in)
                let box = page.bounds(for: .mediaBox).size
                // Actual-size scale so 72pt -> 96 CSS px (common mapping)
                let scale = 96.0 / 72.0
                v.scaleFactor = CGFloat(scale)

                // Optionally size the view to the page at actual size
                let cssSize = NSSize(width: box.width * scale, height: box.height * scale)
                v.setFrameSize(cssSize)
            }
        }
    }
}
