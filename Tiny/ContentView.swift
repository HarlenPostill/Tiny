//
//  ContentView.swift
//  Tiny
//
//  Created by Harlen Postill on 9/9/2025.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var urlString: String = "apple.com"
    @State private var currentURL: URL?
    @State private var webViewProxy = WebViewProxy()
    
    var body: some View {
        VStack(spacing: 0) {
            addressBar
                .padding(.top, 12)
                .padding(.bottom, 12)
            WebView(url: $currentURL, proxy: $webViewProxy)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(Color.clear)
        .frame(minWidth: 450, idealWidth: 500, maxWidth: .infinity, minHeight: 300, idealHeight: 800, maxHeight: .infinity)
        .onAppear(perform: setupWindow)
        .onAppear {
            loadURL()
        }
    }

    private var addressBar: some View {
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
    }

    private func loadURL() {
        let input = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let url = createURL(from: input) {
            currentURL = url
        }
    }
    
    private func createURL(from input: String) -> URL? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedInput.hasPrefix("https://") || trimmedInput.hasPrefix("http://") {
            return URL(string: trimmedInput)
        }
        
        if isDomainLike(trimmedInput) {
            let urlString = "https://" + trimmedInput
            return URL(string: urlString)
        }
        
        return createGoogleSearchURL(for: trimmedInput)
    }
    
    private func isDomainLike(_ input: String) -> Bool {
        let lowercased = input.lowercased()
        guard lowercased.contains(".") else { return false }
        guard !lowercased.contains(" ") else { return false }        
        let searchIndicators = ["what", "how", "why", "when", "where", "who", "?"]
        for indicator in searchIndicators {
            if lowercased.contains(indicator) { return false }
        }
        let tldPattern = #"\.[a-zA-Z]{2,6}(/.*)?$"#
        let regex = try? NSRegularExpression(pattern: tldPattern)
        let range = NSRange(location: 0, length: input.count)
        let hasValidTLD = regex?.firstMatch(in: input, options: [], range: range) != nil
        
        return hasValidTLD
    }
    
    private func createGoogleSearchURL(for query: String) -> URL? {
        guard !query.isEmpty else { return nil }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let googleSearchURL = "https://www.google.com/search?q=\(encodedQuery)"
        return URL(string: googleSearchURL)
    }
    
    private func setupWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
    }
}

// MARK: - WebView & Proxy

/// A proxy to communicate with the underlying `WKWebView`.
struct WebViewProxy {
    var reload: () -> Void = {}
    var goBack: () -> Void = {}
    var goForward: () -> Void = {}
    var canGoBack: () -> Bool = { false }
    var canGoForward: () -> Bool = { false }
}

/// Wrapper for `WKWebView`.
struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var proxy: WebViewProxy

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        proxy = WebViewProxy(
            reload: { webView.reload() },
            goBack: { _ = webView.goBack() },
            goForward: { _ = webView.goForward() },
            canGoBack: { webView.canGoBack },
            canGoForward: { webView.canGoForward }
        )
        
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