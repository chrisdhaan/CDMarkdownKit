<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/.github/cdmarkdownkit.png" alt="CDMarkdownKit" width="850" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/.github/github.png" alt="Star CDMarkdownKit On Github" />
    </a>
    <a href="http://stackoverflow.com/questions/tagged/cdmarkdownkit">
        <img src="https://raw.githubusercontent.com/chrisdhaan/CDMarkdownKit/master/.github/stackoverflow.png" alt="Stack Overflow" />
    </a>
</p>

<p align="center">
    <a href="https://travis-ci.org/chrisdhaan/CDMarkdownKit">
        <img src="http://img.shields.io/travis/chrisdhaan/CDMarkdownKit.svg?style=flat" alt="CI Status">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/v/CDMarkdownKit.svg?style=flat" alt="Version">
    </a>
    <a href="https://github.com/Carthage/Carthage">
        <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/l/CDMarkdownKit.svg?style=flat" alt="License">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/p/CDMarkdownKit.svg?style=flat" alt="Platform">
    </a>
</p>

<br>

This Swift framework handles standard markdown parsing along with the ability to parse custom elements.

For a demonstration of the capabilities of CDMarkdownKit; run the iOS Example project after cloning the repo.

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
    - [Initialization](#initialization)
    - [Customization](#customization)
    - [Supported Markdown Elements](#supported-markdown-elements)
    - [CDMarkdownTextView](#cdmarkdowntextview)
    - [CDMarkdownLabel](#cdmarkdownlabel)
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

- iOS 8.0+ / macOS 10.11+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 8.1+
- Swift 3.0+

---

## Installation

### Installation via CocoaPods

CDMarkdownKit is available through [CocoaPods](http://cocoapods.org). CocoaPods is a dependency manager that automates and simplifies the process of using 3rd-party libraries like CDMarkdownKit in your projects. You can install CocoaPods with the following command:

```ruby
gem install cocoapods
```

To integrate CDMarkdownKit into your Xcode project using CocoaPods, simply add the following line to your Podfile:

```ruby
pod 'CDMarkdownKit', '1.2.0'
```

Afterwards, run the following command:

```ruby
pod install
```

### Installation via Carthage

CDMarkdownKit is available through [Carthage](https://github.com/Carthage/Carthage). Carthage is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage via [Homebrew](http://brew.sh) with the following commands:

```ruby
brew update
brew install carthage
```

To integrate CDMarkdownKit into your Xcode project using Carthage, simply add the following line to your Cartfile:

```ruby
github "chrisdhaan/CDMarkdownKit" == 1.2.0
```

Afterwards, run the following command:

```ruby
carthage update
```

Next, add the built CDMarkdownKit.framework into your Xcode project.

### Installation via Swift Package Manager

CDMarkdownKit is available through the [Swift Package Manager](https://swift.org/package-manager). The Swift Package Manager is a tool for automating the distribution of Swift code.

The Swift Package Manager is in early development, but CDMarkdownKit does support its use on supported platforms. Until the Swift Package Manager supports non-host platforms, it is recommended to use CocoaPods, Carthage, or Git Submodules to build iOS, watchOS, and tvOS apps.

The Swift Package Manager is integrated into the Swift compiler.

To integrate CDMarkdownKit into your Xcode project using The Swift Package Manager, simply add the following line to your Package.swift file:

```swift
dependencies: [
    .Package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", "1.2.0")
]
```

Afterwards, run the following command:

```ruby
swift package fetch
```

### Installation via Git Submodule

CDMarkdownKit is available through [Git Submodule](https://git-scm.com/docs/git-submodule) Git Submodule allows you to keep another Git repository in a subdirectory of your repository.

If your project is not initialized as a git repository, navigate into your top-level project directory, and install Git Submodule with the following command:

```git
git init
```

To integrate CDMarkdownKit into your Xcode project using Git Submodule, simply run the following command:

```git
git submodule add https://github.com/chrisdhaan/CDMarkdownKit.git
```

Afterwards, open the new **CDMarkdownKit** folder, and drag the **CDMarkdownKit.xcodeproj** into the **Project Navigator** of your Xcode project. A common location for the **CDMarkdownKit.xcodeproj** is directly below the **Products** folder.

Next, select your application project in the **Project Navigator** to navigate to the target configuration window and select the application target under the **Targets** heading in the sidebar. In the tab bar at the top of that window, open the **General** panel. Click on the **+** button under the **Embedded Binaries** section. You will see two different CDMarkdownKit.xcodeproj folders, each with a version of the CDMarkdownKit.framework nested inside a Products folder. It does not matter which Products folder you choose from, select the CDMarkdownKit.framework for iOS.

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
                                      backgroundColor: UIColor.lightGray)
// Customize elements
/// Bold
markdownParser.bold.color = UIColor.cyan
markdownParser.bold.backgroundColor = UIColor.purple
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

## Credits

CDMarkdownKit was influenced by [MarkdownKit](https://github.com/ivanbruel/MarkdownKit), a markdown parsing library developed by Ivan Bruel.

CDMarkdownKit adds the following functionalities:
- Fixed header element parsing
- Image element parsing
- Ability to customize font for all elements
- Ability to customize color for all elements
- Ability to customize background color for all elements
- Ability to customize paragraph style for all elements
- UITextView with the ability to round background text color corners for code, syntax, or all elements
- UILabel with the ability to round background text color corners for code, syntax, or all elements
- macOS, tvOS, and watchOS support

## License

CDMarkdownKit is available under the MIT license. See the LICENSE file for more info.

---
