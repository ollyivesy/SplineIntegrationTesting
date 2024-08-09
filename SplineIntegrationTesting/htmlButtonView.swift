//
//  htmlButtonView.swift
//  SplineIntegrationTesting
//
//  Created by Olly Ives on 09/08/2024.
//

import SwiftUI
import WebKit

import SwiftUI
import WebKit

struct htmlButtonView: View {
    @State private var webView: WKWebView?
    @State private var isWebViewLoaded = false

    var body: some View {
        VStack {
            WebView2(webView: $webView, isLoaded: $isWebViewLoaded)
                .frame(height: UIScreen.main.bounds.height - 100)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding()

            Text(isWebViewLoaded ? "WebView Loaded" : "WebView Loading...")
                .foregroundColor(isWebViewLoaded ? .green : .red)
        }
        .padding()
    }
}

struct WebView2: UIViewRepresentable {
    @Binding var webView: WKWebView?
    @Binding var isLoaded: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "splineHandler")
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        self.webView = webView
        loadSplineScene(webView: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView2

        init(_ parent: WebView2) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView did finish navigation")
            DispatchQueue.main.async {
                self.parent.isLoaded = true
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("Received message from JavaScript:", message.body)
        }
    }

    func loadSplineScene(webView: WKWebView) {
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html { margin: 0; padding: 0; overflow: hidden; width: 100%; height: 100%; }
                canvas { width: 100%; height: 90%; display: block; }
                #buttonContainer { position: absolute; bottom: 20px; width: 100%; text-align: center; }
                button { padding: 10px 20px; font-size: 16px; }
            </style>
        </head>
        <body>
            <canvas id="canvas3d"></canvas>
            <div id="buttonContainer">
                <button onclick="setTestBoolTrue()">Set TestBool to True</button>
            </div>
            <script type="module">
                import { Application } from 'https://unpkg.com/@splinetool/runtime@1.0.93/build/runtime.js';
                
                const canvas = document.getElementById('canvas3d');
                const spline = new Application(canvas);
                window.spline = spline;

                spline.load('https://prod.spline.design/tfLKc3kIqCWXZSMF/scene.splinecode')
                    .then(() => {
                        console.log("Spline scene loaded successfully");
                        window.webkit.messageHandlers.splineHandler.postMessage("Spline scene loaded");
                    })
                    .catch((error) => {
                        console.error("Error loading Spline scene:", error);
                        window.webkit.messageHandlers.splineHandler.postMessage("Error loading Spline scene: " + error.message);
                    });

                window.setTestBoolTrue = function() {
                    try {
                        spline.setVariable('TestBool', true);
                        console.log('TestBool set to True');
                        window.webkit.messageHandlers.splineHandler.postMessage("TestBool set to True");
                    } catch (error) {
                        console.error('Error setting TestBool:', error);
                        window.webkit.messageHandlers.splineHandler.postMessage("Error setting TestBool: " + error.message);
                    }
                };
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    htmlButtonView()
}
