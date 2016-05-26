# ActionLabel ![Badge w/ Version](https://cocoapod-badges.herokuapp.com/v/ActionLabel/badge.png) [![Platform](https://img.shields.io/cocoapods/p/ActionLabel.svg)](http://cocoadocs.org/docsets/ActionLabel/) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Build Status](https://travis-ci.org/devcarlos/ActionLabel.svg)](https://travis-ci.org/devcarlos/ActionLabel) [![license MIT](https://img.shields.io/cocoapods/l/ActionLabel.svg)](http://opensource.org/licenses/MIT)

Custom UILabel replacement to recognize, colorize and allow custom action handlers for Hashtags (#), Mentions (@) and URLs (http/https).

## Features

* Swift 2+
* Support `#Hashtags`, `@Mentions` and http://links
* Replacement for `UILabel` to use in Posts
* Easy installation and customization

## Usage

```swift
import ActionLabel

let label = ActionLabel()

//Custom Label Setup
label.text = "Post text #with #multiple #hashtags and some users like @carlosalcala or @twitter. Links are also supported like  http://www.apple.com or http://www.twitter.com/carlosalcala"
label.textColor = .blackColor()
label.hashtagColor = .blueColor()
label.linkColor = .blueColor()
label.mentionColor = .blueColor()

//hashtag custom handler
label.hashtagHandler { hashtag in
  print("Tapped the \(hashtag) hashtag")
}

//set frame
label.frame = CGRect(x: 10, y: 100, width: view.frame.width - 20, height: 500)

//add to current view
view.addSubview(label)

```

## Install (iOS 8+)

### Carthage

Add the following to your `Cartfile` and follow [these instructions](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

```
github "devcarlos/ActionLabel"
```

### CocoaPods

To integrate ActionLabel into your project add the following to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'ActionLabel'
```

## Alternatives

`ActionLabel` is based mostly on `ActiveLabel` project but most of the recognition and regular expression logic has been rewritten, moved and improved to be a more [DRY Pattern](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself), module and single class to make this is a more simple control ready for customization.

* [ActiveLabel](https://github.com/optonaut/ActiveLabel.swift) (Swift) - UILabel drop-in replacement supporting Hashtags (#), Mentions (@) and URLs (http://) written in Swift
* [TTTAttributedLabel](https://github.com/TTTAttributedLabel/TTTAttributedLabel) (ObjC) - A drop-in replacement for UILabel that supports attributes, data detectors, links, and more
* [STTweetLabel](https://github.com/SebastienThiebaud/STTweetLabel) (ObjC) - A UILabel with #hashtag @handle and links tappable
* [AMAttributedHighlightLabel](https://github.com/rootd/AMAttributedHighlightLabel) (ObjC) - A UILabel subclass with mention/hashtag/link highlighting
* [KILabel](https://github.com/Krelborn/KILabel) (ObjC) - A simple to use drop in replacement for UILabel for iOS 7 and above that highlights links such as URLs, twitter style usernames and hashtags and makes them touchable


## License

`ActionLabel` is available under the MIT license. See the LICENSE file for more info.
