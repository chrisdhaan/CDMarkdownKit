import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

@MainActor
open class CDMarkdownTable: CDMarkdownElement, CDMarkdownStyle {

    /// Group 1: header row (line containing at least one |)
    /// Group 2: separator row (dashes, colons, pipes, whitespace only)
    /// Group 3: all data rows
    fileprivate static let regex =
        "^([^\\n]*\\|[^\\n]*\\n)([ \\t]*\\|?[ \\t]*:?-{3,}:?[ \\t]*" +
        "(?:\\|[ \\t]*:?-{3,}:?[ \\t]*)*\\|?[ \\t]*\\n)((?:[^\\n]*\\|[^\\n]*(?:\\n|$))+)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var columnPadding: CGFloat = 16

    /// Called on each cell's text content to apply inline element parsing (bold, italic, links, etc.).
    /// Set by CDMarkdownParser during initialization. Nil means cells render as plain text.
    internal var inlineParser: ((String) -> NSAttributedString)?

    open var regex: String {
        CDMarkdownTable.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex,
                                options: .anchorsMatchLines)
    }

    // MARK: - Cell Parsing

    private func parseCells(from line: String) -> [String] {
        let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = stripped.components(separatedBy: "|")
        // Remove empty strings produced by leading/trailing pipes
        if parts.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            parts.removeFirst()
        }
        if parts.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            parts.removeLast()
        }
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func parseAlignments(from separatorLine: String) -> [NSTextAlignment] {
        let cells = separatorLine.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return cells.map { cell in
            let left = cell.hasPrefix(":")
            let right = cell.hasSuffix(":")
            if left, right {
                return .center
            }
            if right {
                return .right
            }
            return .left
        }
    }

    // MARK: - Attribute Helpers

    private var boldAttributes: [CDAttributedStringKey: AnyObject] {
        var attrs = attributes
        if let font {
            attrs[.font] = font.bold() as AnyObject
        } else if let existingFont = attrs[.font] as? CDFont {
            attrs[.font] = existingFont.bold() as AnyObject
        }
        return attrs
    }

    // MARK: - Match

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange = match.nsRange(atIndex: 0)
        let nsString = attributedString.string as NSString

        let headerLine = nsString.substring(with: match.nsRange(atIndex: 1))
        let separatorLine = nsString.substring(with: match.nsRange(atIndex: 2))
        let dataBlock = nsString.substring(with: match.nsRange(atIndex: 3))

        let headerCells = parseCells(from: headerLine)
        let alignments = parseAlignments(from: separatorLine)
        let dataRows = dataBlock
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { parseCells(from: $0) }

        let columnCount = max(headerCells.count, dataRows.map(\.count).max() ?? 0)
        guard columnCount > 0 else { return }

        let columnWidths = measureColumnWidths(headerCells: headerCells, dataRows: dataRows, columnCount: columnCount)
        let tableStyle = makeTableStyle(columnWidths: columnWidths, alignments: alignments)
        let result = buildTableRows(headerCells: headerCells,
                                    dataRows: dataRows,
                                    columnCount: columnCount,
                                    tableStyle: tableStyle)

        // Replace the original table block with the rebuilt attributed string
        attributedString.replaceCharacters(in: fullRange, with: result)
    }

    // MARK: - Column Layout

    /// Measures the maximum rendered width of each column. Cells are measured using the
    /// post-unescape rendered text (not the raw, possibly UTF16-hex-escaped cell string)
    /// so that a column containing e.g. inline code is sized to what's actually drawn.
    private func measureColumnWidths(headerCells: [String], dataRows: [[String]], columnCount: Int) -> [CGFloat] {
        func renderedText(for cell: String) -> String {
            inlineParser?(cell).string ?? cell
        }

        var columnWidths = [CGFloat](repeating: columnPadding, count: columnCount)
        for (columnIndex, cell) in headerCells.enumerated() where columnIndex < columnCount {
            let columnWidth = renderedText(for: cell).sizeWithAttributes(boldAttributes).width + columnPadding
            columnWidths[columnIndex] = max(columnWidths[columnIndex], columnWidth)
        }
        for row in dataRows {
            for (columnIndex, cell) in row.enumerated() where columnIndex < columnCount {
                let columnWidth = renderedText(for: cell).sizeWithAttributes(attributes).width + columnPadding
                columnWidths[columnIndex] = max(columnWidths[columnIndex], columnWidth)
            }
        }
        return columnWidths
    }

    private func makeTableStyle(columnWidths: [CGFloat], alignments: [NSTextAlignment]) -> NSParagraphStyle {
        // Build tab stops from cumulative column offsets
        var tabStops = [NSTextTab]()
        var offset: CGFloat = 0
        for (columnIndex, width) in columnWidths.enumerated() {
            let alignment = columnIndex < alignments.count ? alignments[columnIndex] : .left
            tabStops.append(NSTextTab(textAlignment: alignment, location: offset))
            offset += width
        }
        let tableStyle = NSMutableParagraphStyle()
        tableStyle.tabStops = tabStops
        tableStyle.defaultTabInterval = columnWidths.first ?? 80
        return tableStyle
    }

    // MARK: - Row Building

    private func makeCellContent(_ text: String, isBold: Bool) -> NSAttributedString {
        guard inlineParser != nil, !text.isEmpty else {
            let cellAttributes = isBold ? boldAttributes : attributes
            return NSAttributedString(string: text, attributes: cellAttributes)
        }
        // Parse inline markdown in cell content
        let parsed = NSMutableAttributedString(attributedString: inlineParser!(text))
        if isBold {
            // Bold the header row if no explicit font was set by inline parsing
            parsed.enumerateAttribute(.font,
                                      in: NSRange(location: 0, length: parsed.length)) { value, range, _ in
                if let font = value as? CDFont {
                    parsed.addAttribute(.font, value: font.bold(), range: range)
                }
            }
        }
        return parsed
    }

    private func makeRow(_ cells: [String], isBold: Bool, columnCount: Int, tableStyle: NSParagraphStyle) -> NSAttributedString {
        let rowString = NSMutableAttributedString()
        for columnIndex in 0 ..< columnCount {
            if columnIndex > 0 {
                rowString.append(NSAttributedString(string: "\t"))
            }
            let text = columnIndex < cells.count ? cells[columnIndex] : ""
            rowString.append(makeCellContent(text, isBold: isBold))
        }
        rowString.append(NSAttributedString(string: "\n"))
        let rowRange = NSRange(location: 0, length: rowString.length)
        rowString.addAttribute(.paragraphStyle, value: tableStyle, range: rowRange)
        return rowString
    }

    private func buildTableRows(headerCells: [String],
                                dataRows: [[String]],
                                columnCount: Int,
                                tableStyle: NSParagraphStyle) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(makeRow(headerCells, isBold: true, columnCount: columnCount, tableStyle: tableStyle))
        for row in dataRows {
            result.append(makeRow(row, isBold: false, columnCount: columnCount, tableStyle: tableStyle))
        }
        return result
    }
}
