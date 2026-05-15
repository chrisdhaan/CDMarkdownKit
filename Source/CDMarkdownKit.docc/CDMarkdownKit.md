# ``CDMarkdownKit``

A pure-Swift, zero-dependency framework for parsing Markdown text into `NSAttributedString`.

## Overview

CDMarkdownKit converts Markdown input into a fully attributed `NSAttributedString` in three phases:
escaping, element parsing, and unescaping. The result can be rendered in any `UILabel`,
`UITextView`, or the provided `CDMarkdownLabel` and `CDMarkdownTextView` subclasses (iOS/tvOS/visionOS),
which add rounded-corner background styling for code and syntax blocks.

## Topics

### Getting Started

- <doc:GettingStarted>

### Parsing

- ``CDMarkdownParser``

### Markdown Elements

- ``CDMarkdownBold``
- ``CDMarkdownItalic``
- ``CDMarkdownHeader``
- ``CDMarkdownList``
- ``CDMarkdownOrderedList``
- ``CDMarkdownQuote``
- ``CDMarkdownLink``
- ``CDMarkdownAutomaticLink``
- ``CDMarkdownImage``
- ``CDMarkdownCode``
- ``CDMarkdownSyntax``
- ``CDMarkdownStrikethrough``
- ``CDMarkdownTable``

### Protocols

- ``CDMarkdownElement``
- ``CDMarkdownStyle``
- ``CDMarkdownCommonElement``
- ``CDMarkdownLevelElement``
- ``CDMarkdownLinkElement``

### Cross-Platform Types

- ``CDFont``
- ``CDColor``
- ``CDImage``
