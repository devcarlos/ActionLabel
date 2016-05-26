//
//  RegexManager.swift
//  ActionLabel
//
//  Created by Carlos Alcala on 5/25/16.
//  Copyright © 2016 Carlos Alcala. All rights reserved.
//

import Foundation

enum ActionElement {
    case Mention(String)
    case Hashtag(String)
    case URL(String)
    case None
}

public enum ActionType {
    case Mention
    case Hashtag
    case URL
    case None
}

typealias ActionFilterPredicate = (String -> Bool)

struct ActionParser {
    
    static let linkPattern = "(^|[\\s.:;?\\-\\]<\\(])" +
        "((https?://|www\\.|pic\\.)[-\\w;/?:@&=+$\\|\\_.!~*\\|'()\\[\\]%#,☺]+[\\w/#](\\(\\))?)" +
    "(?=$|[\\s',\\|\\(\\).:;?\\-\\[\\]>\\)])"
    
    static let hashtagPattern = "(?:^|\\s|$)#[\\p{L}0-9_]*"
    
    static let mentionPattern = "(?:^|\\s|$|[.])@[\\p{L}0-9_]*"
    
    static func getElementsByType(type: ActionType, fromText text: String, range: NSRange) -> [NSTextCheckingResult] {
        
        var regex:NSRegularExpression?
        
        switch type {
        case .Hashtag:
            regex = try? NSRegularExpression(pattern: hashtagPattern, options: [.CaseInsensitive])
        case .Mention:
            regex = try? NSRegularExpression(pattern: mentionPattern, options: [.CaseInsensitive])
        case .URL:
            regex = try? NSRegularExpression(pattern: linkPattern, options: [.CaseInsensitive])
        case .None: break
        }
        
        guard let validRegex = regex else { return [] }
        return validRegex.matchesInString(text, options: [], range: range)
    }
}

struct ActionBuilder {
    
    static func getElementsByType(type: ActionType, fromText text: String, range: NSRange, filterPredicate: ActionFilterPredicate? = nil) -> [(range: NSRange, element: ActionElement)] {
        let parsedElements = ActionParser.getElementsByType(type, fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActionElement)] = []
        
        for element in parsedElements where element.range.length > 2 {
            let range = NSRange(location: element.range.location + 1, length: element.range.length - 1)
            var word = nsstring.substringWithRange(range)
            if word.hasPrefix("@") || word.hasPrefix("#") {
                word.removeAtIndex(word.startIndex)
            }
            
            var newElement: ActionElement?
            
            switch type {
            case .Hashtag:
                if filterPredicate?(word) ?? true {
                    newElement = ActionElement.Hashtag(word)
                }
            case .Mention:
                if filterPredicate?(word) ?? true {
                    newElement = ActionElement.Mention(word)
                }
            case .URL:
                let word = nsstring.substringWithRange(element.range)
                    .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                newElement = ActionElement.URL(word)
            
            case .None: break
            }
            
            if let validElement = newElement {
                elements.append((element.range, validElement))
            }
            
        }
        return elements
    }
}

public protocol ActionLabelDelegate: class {
    func didSelectText(text: String, type: ActionType)
}

@IBDesignable public class ActionLabel: UILabel {
    
    // MARK: properties
    public weak var delegate: ActionLabelDelegate?
    
    @IBInspectable public var mentionColor: UIColor = .blueColor() {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var mentionSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var hashtagColor: UIColor = .blueColor() {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var hashtagSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var URLColor: UIColor = .blueColor() {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var URLSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var lineSpacing: Float = 0 {
        didSet { updateLabel(parseText: false) }
    }
    
    // MARK: methods
    public func mentionHandler(handler: (String) -> ()) {
        mentionHandler = handler
    }
    
    public func hashtaghandler(handler: (String) -> ()) {
        hashtagHandler = handler
    }
    
    public func linkHandler(handler: (NSURL) -> ()) {
        linkHandler = handler
    }
    
    public func filterMention(predicate: (String) -> Bool) {
        mentionFilterPredicate = predicate
        updateLabel()
    }
    
    public func filterHashtag(predicate: (String) -> Bool) {
        hashtagFilterPredicate = predicate
        updateLabel()
    }
    
    // MARK: - override UILabel properties
    override public var text: String? {
        didSet { updateLabel() }
    }
    
    override public var attributedText: NSAttributedString? {
        didSet { updateLabel() }
    }
    
    override public var font: UIFont! {
        didSet { updateLabel(parseText: false) }
    }
    
    override public var textColor: UIColor! {
        didSet { updateLabel(parseText: false) }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet { updateLabel(parseText: false)}
    }
    
    public override var numberOfLines: Int {
        didSet { textContainer.maximumNumberOfLines = numberOfLines }
    }
    
    public override var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }
    
    // MARK: - init functions
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setupLabel()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        updateLabel()
    }
    
    public override func drawTextInRect(rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackgroundForGlyphRange(range, atPoint: newOrigin)
        layoutManager.drawGlyphsForGlyphRange(range, atPoint: newOrigin)
    }
    
    
    // MARK: - customization
    public func customize(block: (label: ActionLabel) -> ()) -> ActionLabel{
        _customizing = true
        block(label: self)
        _customizing = false
        updateLabel()
        return self
    }
    
    // MARK: - Auto layout
    public override func intrinsicContentSize() -> CGSize {
        let superSize = super.intrinsicContentSize()
        textContainer.size = CGSize(width: superSize.width, height: CGFloat.max)
        let size = layoutManager.usedRectForTextContainer(textContainer)
        return CGSize(width: size.width, height: ceil(size.height))
    }
    
    // MARK: - touch events
    func onTouch(touch: UITouch) -> Bool {
        let location = touch.locationInView(self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .Began, .Moved:
            if let element = elementAtLocation(location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedElement = element
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedElement = nil
            }
        case .Ended:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .Mention(let userHandle): didTapMention(userHandle)
            case .Hashtag(let hashtag): didTapHashtag(hashtag)
            case .URL(let url): didTapStringURL(url)
            case .None: ()
            }
            
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) {
                self.updateAttributesWhenSelected(false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .Cancelled:
            updateAttributesWhenSelected(false)
            selectedElement = nil
        case .Stationary:
            break
        }
        
        return avoidSuperCall
    }
    
    // MARK: - private properties
    private var _customizing: Bool = true
    
    private var mentionHandler: ((String) -> ())?
    private var hashtagHandler: ((String) -> ())?
    private var linkHandler: ((NSURL) -> ())?
    
    private var mentionFilterPredicate: ((String) -> Bool)?
    private var hashtagFilterPredicate: ((String) -> Bool)?
    
    private var selectedElement: (range: NSRange, element: ActionElement)?
    private var heightCorrection: CGFloat = 0
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()
    internal lazy var ActionElements: [ActionType: [(range: NSRange, element: ActionElement)]] = [
        .Mention: [],
        .Hashtag: [],
        .URL: [],
    ]
    
    // MARK: - helper functions
    private func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        userInteractionEnabled = true
    }
    
    private func updateLabel(parseText parseText: Bool = true) {
        if _customizing { return }
        // clean up previous Action elements
        guard let attributedText = attributedText where attributedText.length > 0 else {
            clearActionElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(attributedText)
        
        if parseText {
            clearActionElements()
            parseTextAndExtractActionElements(mutAttrString)
        }
        
        self.addLinkAttribute(mutAttrString)
        self.textStorage.setAttributedString(mutAttrString)
        self.setNeedsDisplay()
    }
    
    private func clearActionElements() {
        selectedElement = nil
        for (type, _) in ActionElements {
            ActionElements[type]?.removeAll()
        }
    }
    
    private func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRectForTextContainer(textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// add link attribute
    private func addLinkAttribute(mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributesAtIndex(0, effectiveRange: &range)
        
        attributes[NSFontAttributeName] = font!
        attributes[NSForegroundColorAttributeName] = textColor
        mutAttrString.addAttributes(attributes, range: range)
        
        attributes[NSForegroundColorAttributeName] = mentionColor
        
        for (type, elements) in ActionElements {
            
            switch type {
            case .Mention: attributes[NSForegroundColorAttributeName] = mentionColor
            case .Hashtag: attributes[NSForegroundColorAttributeName] = hashtagColor
            case .URL: attributes[NSForegroundColorAttributeName] = URLColor
            case .None: ()
            }
            
            for element in elements {
                mutAttrString.setAttributes(attributes, range: element.range)
            }
        }
    }
    
    /// use regex check all link ranges
    private func parseTextAndExtractActionElements(attrString: NSAttributedString) {
        let textString = attrString.string
        let textLength = textString.utf16.count
        let textRange = NSRange(location: 0, length: textLength)
        
        //URLS
        let urlElements = ActionBuilder.getElementsByType(.URL, fromText: textString, range: textRange)
        ActionElements[.URL]?.appendContentsOf(urlElements)
        
        //HASHTAGS
        let hashtagElements = ActionBuilder.getElementsByType(.Hashtag, fromText: textString, range: textRange, filterPredicate: hashtagFilterPredicate)
        ActionElements[.Hashtag]?.appendContentsOf(hashtagElements)
        
        //MENTIONS
        let mentionElements = ActionBuilder.getElementsByType(.Mention, fromText: textString, range: textRange, filterPredicate: mentionFilterPredicate)
        ActionElements[.Mention]?.appendContentsOf(mentionElements)
    }
    
    
    /// add line break mode
    private func addLineBreak(attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributesAtIndex(0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = CGFloat(lineSpacing)
        
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    private func updateAttributesWhenSelected(isSelected: Bool) {
        guard let selectedElement = selectedElement else {
            return
        }
        
        var attributes = textStorage.attributesAtIndex(0, effectiveRange: nil)
        if isSelected {
            switch selectedElement.element {
            case .Mention(_): attributes[NSForegroundColorAttributeName] = mentionSelectedColor ?? mentionColor
            case .Hashtag(_): attributes[NSForegroundColorAttributeName] = hashtagSelectedColor ?? hashtagColor
            case .URL(_): attributes[NSForegroundColorAttributeName] = URLSelectedColor ?? URLColor
            case .None: ()
            }
        } else {
            switch selectedElement.element {
            case .Mention(_): attributes[NSForegroundColorAttributeName] = mentionColor
            case .Hashtag(_): attributes[NSForegroundColorAttributeName] = hashtagColor
            case .URL(_): attributes[NSForegroundColorAttributeName] = URLColor
            case .None: ()
            }
        }
        
        textStorage.addAttributes(attributes, range: selectedElement.range)
        
        setNeedsDisplay()
    }
    
    private func elementAtLocation(location: CGPoint) -> (range: NSRange, element: ActionElement)? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRectForGlyphRange(NSRange(location: 0, length: textStorage.length), inTextContainer: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndexForPoint(correctLocation, inTextContainer: textContainer)
        
        for element in ActionElements.map({ $0.1 }).flatten() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    
    
    //MARK: - Handle UI Responder touches
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, withEvent: event)
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesMoved(touches, withEvent: event)
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let touch = touches?.first else { return }
        onTouch(touch)
        super.touchesCancelled(touches, withEvent: event)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, withEvent: event)
    }
    
    //MARK: - ActionLabel handler
    private func didTapMention(username: String) {
        guard let mentionHandler = mentionHandler else {
            delegate?.didSelectText(username, type: .Mention)
            return
        }
        mentionHandler(username)
    }
    
    private func didTapHashtag(hashtag: String) {
        guard let hashtagHandler = hashtagHandler else {
            delegate?.didSelectText(hashtag, type: .Hashtag)
            return
        }
        hashtagHandler(hashtag)
    }
    
    private func didTapStringURL(stringURL: String) {
        guard let urlHandler = linkHandler, let url = NSURL(string: stringURL) else {
            delegate?.didSelectText(stringURL, type: .URL)
            return
        }
        urlHandler(url)
    }
}

extension ActionLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

