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
        }

        #if os(visionOS)
            @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
            @Test func configuredTextViewDisablesEditingOnVisionOS() {
                let textView = CDMarkdownView.configuredTextView()
                #expect(textView.isEditable == false)
            }
        #endif

        @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
        @Test func makeCoordinatorCarriesOnLinkTapHandler() {
            let view = CDMarkdownView("test", onLinkTap: { _ in })
            let coordinator = view.makeCoordinator()
            #expect(coordinator.onLinkTap != nil)
        }

        #if !os(visionOS)
            @available(iOS 15.0, tvOS 15.0, *)
            @Test func shouldInteractWithFiresHandlerAndReturnsFalse() {
                var tappedURL: URL?
                let coordinator = CDMarkdownView.Coordinator(onLinkTap: { tappedURL = $0 })
                let url = URL(string: "https://example.com")! // swiftformat:disable:this:line noForceUnwrapInTests
                let result = coordinator.textView(UITextView(),
                                                  shouldInteractWith: url,
                                                  in: NSRange(location: 0, length: 1),
                                                  interaction: .invokeDefaultAction)
                #expect(tappedURL == url)
                #expect(result == false)
            }

            @available(iOS 15.0, tvOS 15.0, *)
            @Test func shouldInteractWithReturnsTrueWhenNoHandler() {
                let coordinator = CDMarkdownView.Coordinator(onLinkTap: nil)
                let url = URL(string: "https://example.com")! // swiftformat:disable:this:line noForceUnwrapInTests
                let result = coordinator.textView(UITextView(),
                                                  shouldInteractWith: url,
                                                  in: NSRange(location: 0, length: 1),
                                                  interaction: .invokeDefaultAction)
                #expect(result == true)
            }
        #endif

        #if os(iOS) || os(visionOS)
            @available(iOS 17.0, visionOS 1.0, *)
            @Test func primaryActionFiresHandlerAndReturnsNil() {
                var tappedURL: URL?
                let url = URL(string: "https://example.com")! // swiftformat:disable:this:line noForceUnwrapInTests
                let defaultAction = UIAction { _ in }
                let result = CDMarkdownView.Coordinator.primaryAction(forLinkURL: url,
                                                                      onLinkTap: { tappedURL = $0 },
                                                                      defaultAction: defaultAction)
                #expect(tappedURL == url)
                #expect(result == nil)
            }

            @available(iOS 17.0, visionOS 1.0, *)
            @Test func primaryActionReturnsDefaultActionWhenNoHandler() {
                let url = URL(string: "https://example.com")! // swiftformat:disable:this:line noForceUnwrapInTests
                let defaultAction = UIAction { _ in }
                let result = CDMarkdownView.Coordinator.primaryAction(forLinkURL: url,
                                                                      onLinkTap: nil,
                                                                      defaultAction: defaultAction)
                #expect(result === defaultAction)
            }
        #endif
    }
#endif
