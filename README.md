<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/Documentation/cdmarkdownkit.png" alt="CDMarkdownKit" width="850" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/Documentation/github.png" alt="Star CDMarkdownKit On Github" />
    </a>
    <a href="http://stackoverflow.com/questions/tagged/cdmarkdownkit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/Documentation/stackoverflow.png" alt="Stack Overflow" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit/actions/workflows/ci.yml">
        <img src="https://github.com/chrisdhaan/CDMarkdownKit/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://github.com/chrisdhaan/CDMarkdownKit/releases">
        <img src="https://img.shields.io/github/release/chrisdhaan/CDMarkdownKit.svg" alt="GitHub Release">
    </a>
    <a href="https://www.swift.org">
        <img src="https://img.shields.io/badge/Swift-5.3_5.4_5.5_5.6_5.7-orange?style=flat" alt="Swift Versions">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/p/CDMarkdownKit.svg?style=flat" alt="Platforms">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/v/CDMarkdownKit.svg?style=flat" alt="CocoaPods Compatible">
    </a>
    <a href="https://github.com/Carthage/Carthage">
        <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible">
    </a>
    <a href="https://www.swift.org/package-manager">
        <img src="https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat" alt="Swift Package Manager Compatible">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/l/CDMarkdownKit.svg?style=flat" alt="License">
    </a>
</p>

<br>

This Swift framework handles standard markdown parsing along with the ability to parse custom elements.

For a demonstration of the capabilities of CDMarkdownKit; run the iOS Example project after cloning the repo.

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Contributing](#contributing)
- [Usage](#usage)
    - [Initialization](#initialization)
    - [Customization](#customization)
    - [Supported Markdown Elements](#supported-markdown-elements)
    - [CDMarkdownTextView](#cdmarkdowntextview)
    - [CDMarkdownLabel](#cdmarkdownlabel)
- [Author](#author)
- [Credits](#credits)
- [License](#license)

---

## Features

- [x] Markdown Parsing
    - [x] Italic
    - [x] Bold
    - [x] Header
    - [x] Quote
    - [x] List
    - [x] Code
    - [x] Syntax
    - [x] Link
    - [x] Image
- [x] UITextView With Markdown Formatting
- [x] UILabel With Markdown Formatting
- [x] Platform Support
  - [x] iOS
  - [x] macOS
  - [x] tvOS
  - [x] watchOS
- [x] Documentation

---

## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Swift 5.3+

---

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate CDMarkdownKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'CDMarkdownKit', '2.5.1'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate CDMarkdownKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "chrisdhaan/CDMarkdownKit" == 2.5.1
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding CDMarkdownKit as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", .upToNextMajor(from: "2.5.1"))
]
```

### Git Submodule

If you prefer not to use any of the aforementioned dependency managers, you can integrate CDMarkdownKit into your project manually.

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add CDMarkdownKit as a git [submodule](https://git-scm.com/docs/git-submodule) by running the following command:

```git
git submodule add https://github.com/chrisdhaan/CDMarkdownKit.git
```

- Open the new `CDMarkdownKit` folder, and drag the `CDMarkdownKit.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `CDMarkdownKit.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `CDMarkdownKit.xcodeproj` folders each with two different versions of the `CDMarkdownKit.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `CDMarkdownKit.framework`.

- Select the top `CDMarkdownKit.framework` for iOS and the bottom one for macOS.

    > You can verify which one you selected by inspecting the build log for your project. The build target for `CDMarkdownKit` will be listed as either `CDMarkdownKit iOS`, `CDMarkdownKit macOS`, `CDMarkdownKit tvOS` or `CDMarkdownKit watchOS`.

- And that's it!

  > The `CDMarkdownKit.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

---

## Contributing

Before contributing to CDMarkdownKit, please read the instructions detailed in our [contribution guide](https://github.com/chrisdhaan/CDMarkdownKit/blob/master/CONTRIBUTING.md).

---

## Usage

### Initialization

```swift
// Create parser
let markdownParser = CDMarkdownParser()
// Parse markdown
let markdown = "This *framework* helps **with** parsing `markdown`."
label.attributedText = markdownParser.parse(markdown)
```

### Customization

```swift
// Create parser
let markdownParser = CDMarkdownParser(font: UIFont(name: "HelveticaNeue", size: 16),
                                      boldFont: UIFont(name: "HelveticaNeue-Bold", size: 16),
                                      italicFont: UIFont(name: "HelveticaNeue-Thin", size: 16),
                                      fontColor: UIColor.darkGray,
                                      backgroundColor: UIColor.lightGray,
                                      squashNewlines: false)
// Customize elements
/// Bold
markdownParser.bold.color = UIColor.cyan
markdownParser.bold.backgroundColor = UIColor.purple
markdownParser.bold.underlineColor = UIColor.red
markdownParser.bold.underlineStyle = .double
/// Header
markdownParser.header.color = UIColor.black
markdownParser.header.backgroundColor = UIColor.orange
/// List
markdownParser.list.color = UIColor.black
markdownParser.list.backgroundColor = UIColor.red
/// Quote
markdownParser.quote.color = UIColor.gray
markdownParser.quote.backgroundColor = UIColor.clear
/// Link
markdownParser.link.color = UIColor.blue
markdownParser.link.backgroundColor = UIColor.green
let linkParagraphStyle = NSMutableParagraphStyle()
linkParagraphStyle.paragraphSpacing = 20
linkParagraphStyle.paragraphSpacingBefore = 0
linkParagraphStyle.lineSpacing = 20.38
markdownParser.link.paragraphStyle = linkParagraphStyle
markdownParser.automaticLink.color = UIColor.blue
markdownParser.automaticLink.backgroundColor = UIColor.green
/// Italic
markdownParser.italic.color = UIColor.gray
markdownParser.italic.backgroundColor = UIColor.clear
/// Code
markdownParser.code.font = UIFont.systemFont(ofSize: 17)
markdownParser.code.color = UIColor.red
markdownParser.code.backgroundColor = UIColor.black
/// Syntax
markdownParser.syntax.font = UIFont.systemFont(ofSize: 15)
markdownParser.syntax.color = UIColor.lightGray
markdownParser.syntax.backgroundColor = UIColor.black
/// Image
markdownParser.image.size = CGSize(width: 100,
                                   height: 50)
/// Strikethrough
markdownParser.strikethrough.font = UIFont.systemFont(ofSize: 20)
markdownParser.strikethrough.color = UIColor.magenta
markdownParser.strikethrough.strikethroughColor = UIColor.darkGray
markdownParser.strikethrough.strikethroughStyle = .double
// Parse markdown
let markdown = "This *framework* helps **with** parsing `markdown`."
label.attributedText = markdownParser.parse(markdown)
```

### Supported Markdown Elements

```
*italic* or _italic_
**bold** or __bold__

# Header 1
## Header 2
### Header 3
#### Header 4
##### Header 5
###### Header 6

> Quote

* List
- List
+ List

`code`

```syntax```

[Link](url)
![Image](url)
```

### CDMarkdownTextView

**It is recommended that any CDMarkdownTextView objects be initialized programmatically** as it uses custom text drawing objects to render attributed strings.

A CDMarkdownTextView object will still render when initialized via a storyboard but the default behavior for the following properties will be overridden:

- ```isScrollEnabled = true```
- ```isSelectable = false```
- ```isEditable = false```

**These defaults are set to avoid crashes. There still may be unforeseen crashes that occur when initializing a CDMarkdownTextView object via a storyboard.**

#### Programmatic Example

```swift
let rect = CGRect(x: 20,
                  y: 10,
                  width: CGFloat(self.frame.size.width - 40),
                  height: CGFloat(self.frame.size.height - 30))
/// Create custom text container
let textContainer = NSTextContainer(size: rect.size)
/// Create custom layout manager
let layoutManager = CDMarkdownLayoutManager()
layoutManager.addTextContainer(textContainer)
/// Initialization
let textView = CDMarkdownTextView(frame: rect, 
                                  textContainer: textContainer, 
                                  layoutManager: layoutManager)
textView.translatesAutoresizingMaskIntoConstraints = false
/// Standard markdown UI formatting
textView.roundCodeCorners = true
textView.roundSyntaxCorners = true
/// Custom markdown UI formatting
textView.roundAllCorners = true
/// Add constraints so intrinsic content size is set correctly
let topConstraint = NSLayoutConstraint(item: textView,
                                       attribute: NSLayoutAttribute.top,
                                       relatedBy: NSLayoutRelation.equal,
                                       toItem: textView.superview,
                                       attribute: NSLayoutAttribute.bottom,
                                       multiplier: 1,
                                       constant: 10)
let leadingConstraint = NSLayoutConstraint(item: textView,
                                           attribute: NSLayoutAttribute.leading,
                                           relatedBy: NSLayoutRelation.equal,
                                           toItem: textView.superview,
                                           attribute: NSLayoutAttribute.leadingMargin,
                                           multiplier: 1,
                                           constant: 0)
let trailingConstraint = NSLayoutConstraint(item: textView,
                                            attribute: NSLayoutAttribute.trailing,
                                            relatedBy: NSLayoutRelation.equal,
                                            toItem: textView.superview,
                                            attribute: NSLayoutAttribute.trailingMargin,
                                            multiplier: 1,
                                            constant: 0)
let bottomConstraint = NSLayoutConstraint(item: self.bottomLayoutGuide,
                                          attribute: NSLayoutAttribute.top,
                                          relatedBy: NSLayoutRelation.equal,
                                          toItem: textView,
                                          attribute: NSLayoutAttribute.bottom,
                                          multiplier: 1,
                                          constant: 20)
self.view.addConstraints([topConstraint,
                          leadingConstraint,
                          trailingConstraint,
                          bottomConstraint])
/// Add to view hierarchy
self.view.addSubview(textView)
```

#### Storyboard Example

```swift
/// Initialization
@IBOutlet fileprivate weak var textView: CDMarkdownTextView!
/// Standard markdown UI formatting
self.textView.roundCodeCorners = true
self.textView.roundSyntaxCorners = true
/// Custom markdown UI formatting
self.textView.roundAllCorners = true
```

### CDMarkdownLabel

#### Programmatic Example

```swift
let size = self.frame.size
let rect = CGRect(x: 10, 
                  y: 10,
                  width: CGFloat(size.width - 20),
                  height: CGFloat(size.height - 20))
/// Initialization
let label = CDMarkdownLabel(frame: rect)
label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
/// Standard markdown UI formatting
label.roundCodeCorners = true
label.roundSyntaxCorners = true
/// Custom markdown UI formatting
label.roundAllCorners = true

self.view.addSubview(label)
```

#### Storyboard Example

```swift
/// Initialization
@IBOutlet fileprivate weak var label: CDMarkdownLabel!
/// Standard markdown UI formatting
self.label.roundCodeCorners = true
self.label.roundSyntaxCorners = true
/// Custom markdown UI formatting
self.label.roundAllCorners = true
```

---

## Author

Christopher de Haan, contact@christopherdehaan.me

---

## Credits

CDMarkdownKit was influenced by [MarkdownKit](https://github.com/ivanbruel/MarkdownKit), a markdown parsing library developed by Ivan Bruel.

CDMarkdownKit adds the following functionalities:
- Fixed header element parsing
- Image element parsing
- Strikethrough element parsing
- Ability to customize font for all elements
- Ability to customize color for all elements
- Ability to customize background color for all elements
- Ability to customize paragraph style for all elements
- Ability to customize underline color style for all elements
- Ability to customize underline style style for all elements
- UITextView with the ability to round background text color corners for code, syntax, or all elements
- UILabel with the ability to round background text color corners for code, syntax, or all elements
- macOS, tvOS, and watchOS support

---

## License

CDMarkdownKit is available under the MIT license. See the LICENSE file for more info.

---
