//
//  ContentView.swift
//  Tiny
//
//  Created by Harlen Postill on 9/9/2025.
//

import SwiftUI
import WebKit

// MARK: - Main View

struct ContentView: View {
    @State private var urlString: String = "hrln-interactive.com"
    @State private var currentURL: URL?
    @State private var webViewProxy = WebViewProxy()
    
    // Keep track of the drag gesture to move the window
    @State private var dragGestureTranslation: CGSize = .zero

    var body: some View {
        ZStack {
            // The WebView is the main content layer, clipped to a rounded rectangle.
            WebView(url: $currentURL, proxy: $webViewProxy)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(8) // Padding to create the see-through border effect

            // The address bar floats on top of the WebView.
            addressBar
        }
        .background(Color.clear)
        .frame(minWidth: 450, idealWidth: 600, maxWidth: .infinity, minHeight: 300, idealHeight: 800, maxHeight: .infinity)
        .onAppear(perform: setupWindow)
        .onAppear {
             // Load initial URL when the view appears.
            loadURL()
        }
        .gesture(
            DragGesture().onChanged { value in
                // This gesture allows the window to be dragged from anywhere.
                if let window = NSApplication.shared.windows.first {
                    // A new drag gesture has a zero translation. A continuing one will not.
                    // This check prevents the window from jumping to the gesture's start point.
                    if self.dragGestureTranslation == .zero {
                        window.performDrag(with: NSApplication.shared.currentEvent!)
                    }
                    self.dragGestureTranslation = value.translation
                }
            }.onEnded { _ in
                // Reset the translation when the gesture ends.
                self.dragGestureTranslation = .zero
            }
        )
    }

    /// The floating address bar view.
    private var addressBar: some View {
        VStack {
            HStack(spacing: 0) {
                TextField("Search or enter website name", text: $urlString, onCommit: loadURL)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
            }
            .background(
                Capsule(style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, y: 5)
            .frame(width: 450)
            .padding(.top, 24)

            Spacer()
        }
    }

    /// Parses the URL string and updates the `currentURL` state.
    private func loadURL() {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !urlToLoad.hasPrefix("https://") && !urlToLoad.hasPrefix("http://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        if let url = URL(string: urlToLoad) {
            currentURL = url
        }
    }
    
    /// Configures the application window to be transparent and borderless.
    private func setupWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

// MARK: - WebView & Proxy

/// A proxy to communicate with the underlying `WKWebView`.
struct WebViewProxy {
    var reload: () -> Void = {}
}

/// A SwiftUI wrapper for `WKWebView`.
struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var proxy: WebViewProxy

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // Link the proxy actions to the webView instance.
        self.proxy.reload = { webView.reload() }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only load a new request if the URL is valid and different.
        if let url = url, nsView.url != url {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
