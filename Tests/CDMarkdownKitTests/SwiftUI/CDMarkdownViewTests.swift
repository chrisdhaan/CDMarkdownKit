import SwiftUI
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownViewTests {

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func resolveParserPrefersExplicitOverEnvironmentAndDefault() {
            let explicit = CDMarkdownParser()
            let environment = CDMarkdownParser()
            let resolved = CDMarkdownView.resolveParser(explicit: explicit, environment: environment, theme: .default)
            #expect(resolved === explicit)
        }

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func resolveParserPrefersEnvironmentOverDefault() {
            let environment = CDMarkdownParser()
            let resolved = CDMarkdownView.resolveParser(explicit: nil, environment: environment, theme: .default)
            #expect(resolved === environment)
        }

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func resolveParserFallsBackToThemedDefault() {
            var theme = CDMarkdownTheme.default
            theme.fontColor = .red
            let resolved = CDMarkdownView.resolveParser(explicit: nil, environment: nil, theme: theme)
            #expect(resolved.fontColor == theme.fontColor)
        }

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func configuredTextViewOverridesScrollAndSelectionDefaults() {
            let textView = CDMarkdownView.configuredTextView()
            #expect(textView.isScrollEnabled == false)
            #expect(textView.isSelectable == true)
            #expect(textView.backgroundColor == .clear)
            if #available(iOS 16.0, tvOS 16.0, *) {
                #expect(textView.tk2Delegate is CDMarkdownTextLayoutDelegate)
            }
        }

        #if os(visionOS)
            @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
            @Test func configuredTextViewDisablesEditingOnVisionOS() {
                let textView = CDMarkdownView.configuredTextView()
                #expect(textView.isEditable == false)
            }
        #endif

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func makeCoordinatorCarriesOnLinkTapHandler() throws {
            var tappedURL: URL?
            let view = CDMarkdownView("test", onLinkTap: { tappedURL = $0 })
            let coordinator = view.makeCoordinator()
            let url = try #require(URL(string: "https://example.com"))
            #if !os(visionOS)
                _ = coordinator.textView(UITextView(),
                                         shouldInteractWith: url,
                                         in: NSRange(location: 0, length: 1),
                                         interaction: .invokeDefaultAction)
            #else
                coordinator.onLinkTap?(url)
            #endif
            #expect(tappedURL == url)
        }

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func makeCoordinatorWithNilHandlerHasNilOnLinkTap() {
            let view = CDMarkdownView("test", onLinkTap: nil)
            let coordinator = view.makeCoordinator()
            #expect(coordinator.onLinkTap == nil)
        }

        #if !os(visionOS)
            @available(iOS 15.0, tvOS 15.0, *)
            @Test func shouldInteractWithFiresHandlerAndReturnsFalse() throws {
                var tappedURL: URL?
                let coordinator = CDMarkdownView.Coordinator(onLinkTap: { tappedURL = $0 })
                let url = try #require(URL(string: "https://example.com"))
                let result = coordinator.textView(UITextView(),
                                                  shouldInteractWith: url,
                                                  in: NSRange(location: 0, length: 1),
                                                  interaction: .invokeDefaultAction)
                #expect(tappedURL == url)
                #expect(result == false)
            }

            @available(iOS 15.0, tvOS 15.0, *)
            @Test func shouldInteractWithReturnsTrueWhenNoHandler() throws {
                let coordinator = CDMarkdownView.Coordinator(onLinkTap: nil)
                let url = try #require(URL(string: "https://example.com"))
                let result = coordinator.textView(UITextView(),
                                                  shouldInteractWith: url,
                                                  in: NSRange(location: 0, length: 1),
                                                  interaction: .invokeDefaultAction)
                #expect(result == true)
            }
        #endif

        #if os(iOS) || os(visionOS)
            @available(iOS 17.0, visionOS 1.0, *)
            @Test func primaryActionFiresHandlerAndReturnsNil() throws {
                var tappedURL: URL?
                let url = try #require(URL(string: "https://example.com"))
                let defaultAction = UIAction { _ in }
                let result = CDMarkdownView.Coordinator.primaryAction(forLinkURL: url,
                                                                      onLinkTap: { tappedURL = $0 },
                                                                      defaultAction: defaultAction)
                #expect(tappedURL == url)
                #expect(result == nil)
            }

            @available(iOS 17.0, visionOS 1.0, *)
            @Test func primaryActionReturnsDefaultActionWhenNoHandler() throws {
                let url = try #require(URL(string: "https://example.com"))
                let defaultAction = UIAction { _ in }
                let result = CDMarkdownView.Coordinator.primaryAction(forLinkURL: url,
                                                                      onLinkTap: nil,
                                                                      defaultAction: defaultAction)
                #expect(result === defaultAction)
            }
        #endif
    }

#elseif os(macOS)
    import Cocoa

    @MainActor
    struct CDMarkdownViewTests {

        @available(macOS 12.0, *)
        @Test func resolveParserPrefersExplicitOverEnvironmentAndDefault() {
            let explicit = CDMarkdownParser()
            let environment = CDMarkdownParser()
            let resolved = CDMarkdownView.resolveParser(explicit: explicit, environment: environment, theme: .default)
            #expect(resolved === explicit)
        }

        @available(macOS 12.0, *)
        @Test func resolveParserPrefersEnvironmentOverDefault() {
            let environment = CDMarkdownParser()
            let resolved = CDMarkdownView.resolveParser(explicit: nil, environment: environment, theme: .default)
            #expect(resolved === environment)
        }

        @available(macOS 12.0, *)
        @Test func resolveParserFallsBackToThemedDefault() {
            var theme = CDMarkdownTheme.default
            theme.fontColor = .red
            let resolved = CDMarkdownView.resolveParser(explicit: nil, environment: nil, theme: theme)
            #expect(resolved.fontColor == theme.fontColor)
        }

        @available(macOS 12.0, *)
        @Test func makeCoordinatorCarriesOnLinkTapHandler() throws {
            var tappedURL: URL?
            let view = CDMarkdownView("test", onLinkTap: { url in
                tappedURL = url
                return true
            })
            let coordinator = view.makeCoordinator()
            let url = try #require(URL(string: "https://example.com"))
            _ = coordinator.textView(NSTextView(), clickedOnLink: url, at: 0)
            #expect(tappedURL == url)
        }

        @available(macOS 12.0, *)
        @Test func makeCoordinatorWithNilHandlerHasNilOnLinkTap() {
            let view = CDMarkdownView("test", onLinkTap: nil)
            let coordinator = view.makeCoordinator()
            #expect(coordinator.onLinkTap == nil)
        }

        @available(macOS 12.0, *)
        @Test func clickedOnLinkReturnsHandlerResultForURL() throws {
            var tappedURL: URL?
            let coordinator = CDMarkdownView.Coordinator(onLinkTap: { url in
                tappedURL = url
                return true
            })
            let url = try #require(URL(string: "https://example.com"))
            let result = coordinator.textView(NSTextView(), clickedOnLink: url, at: 0)
            #expect(tappedURL == url)
            #expect(result == true)
        }

        @available(macOS 12.0, *)
        @Test func clickedOnLinkReturnsFalseWhenNoHandler() throws {
            let coordinator = CDMarkdownView.Coordinator(onLinkTap: nil)
            let result = try coordinator.textView(NSTextView(), clickedOnLink: #require(URL(string: "https://example.com")), at: 0)
            #expect(result == false)
        }

        @available(macOS 12.0, *)
        @Test func clickedOnLinkReturnsFalseWhenLinkIsNotAURL() {
            let coordinator = CDMarkdownView.Coordinator(onLinkTap: { _ in true })
            let result = coordinator.textView(NSTextView(), clickedOnLink: "not a url", at: 0)
            #expect(result == false)
        }
    }
#endif
