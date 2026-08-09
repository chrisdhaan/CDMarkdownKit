import Foundation
import Testing
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

struct DictionaryCDMarkdownKitTests {

    @Test func addStrikethroughStyleBridgesIntoAnyObjectDictionary() {
        var attributes: [CDAttributedStringKey: AnyObject] = [:]
        attributes.addStrikethroughStyle(.single)
        let value = attributes[NSAttributedString.Key.strikethroughStyle] as? Int
        #expect(value == NSUnderlineStyle.single.rawValue)
    }

    @Test func addUnderlineStyleBridgesIntoAnyObjectDictionary() {
        var attributes: [CDAttributedStringKey: AnyObject] = [:]
        attributes.addUnderlineStyle(.double)
        let value = attributes[NSAttributedString.Key.underlineStyle] as? Int
        #expect(value == NSUnderlineStyle.double.rawValue)
    }
}
