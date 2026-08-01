//
//  SwiftUIExampleView.swift
//  iOS Example
//
//  Created by Christopher de Haan on 7/31/26.
//
//  Copyright © 2016-2026 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import CDMarkdownKit
import SwiftUI

@available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
private enum MarkdownComponent: String, CaseIterable, Identifiable {
    case text = "Text"
    case view = "View"

    var id: String { self.rawValue }
}

@available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
private enum ThemeOption: String, CaseIterable, Identifiable {
    case standard = "Default"
    case dark = "System Dark"

    var id: String { self.rawValue }

    var theme: CDMarkdownTheme {
        switch self {
        case .standard:
            return .default
        case .dark:
            return .systemDark
        }
    }
}

@available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
struct SwiftUIExampleView: View {

    @State private var component: MarkdownComponent = .text
    @State private var themeOption: ThemeOption = .standard

    private let modernElementsString = NSLocalizedString("ModernElementsMarkdown",
                                                          tableName: nil,
                                                          bundle: Bundle.main,
                                                          value: "",
                                                          comment: "")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CDMarkdownText / CDMarkdownView")
                    .font(.headline)

                Picker("Component", selection: self.$component) {
                    ForEach(MarkdownComponent.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Theme", selection: self.$themeOption) {
                    ForEach(ThemeOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    switch self.component {
                    case .text:
                        CDMarkdownText(self.modernElementsString)
                    case .view:
                        CDMarkdownView(self.modernElementsString) { url in
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .markdownTheme(self.themeOption.theme)

                Divider()

                Text("Explicit parser via .markdownParser(_:)")
                    .font(.headline)

                CDMarkdownText("**This bold text is purple** because an explicitly-built `CDMarkdownParser` is injected via `.markdownParser(_:)`, which takes precedence over `.markdownTheme(_:)`.")
                    .markdownParser(self.explicitParser())
            }
            .padding()
        }
    }

    // MARK: - Private Methods

    private func explicitParser() -> CDMarkdownParser {
        let parser = CDMarkdownParser(theme: .default)
        parser.bold.color = .systemPurple
        return parser
    }
}
