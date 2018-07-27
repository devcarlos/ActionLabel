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

typealias ActionFilterPredicate = ((String) -> Bool)

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
            regex = try? NSRegularExpression(pattern: hashtagPattern, options: [.caseInsensitive])
        case .Mention:
            regex = try? NSRegularExpression(pattern: mentionPattern, options: [.caseInsensitive])
        case .URL:
            regex = try? NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive])
        case .None: break
        }
        
        guard let validRegex = regex else { return [] }
        return validRegex.matches(in: text, options: [], range: range)
    }
}

struct ActionBuilder {
    
    static func getElementsByType(type: ActionType, fromText text: String, range: NSRange, filterPredicate: ActionFilterPredicate? = nil) -> [(range: NSRange, element: ActionElement)] {
        let parsedElements = ActionParser.getElementsByType(type: type, fromText: text, range: range)
        let nsstring = text as NSString
        var elements: [(range: NSRange, element: ActionElement)] = []
        
        for element in parsedElements where element.range.length > 2 {
            let range = NSRange(location: element.range.location + 1, length: element.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") || word.hasPrefix("#") {
                word.remove(at: word.startIndex)
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
                let word = nsstring.substring(with: element.range).trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    @IBInspectable public var mentionColor: UIColor = .blue {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var mentionSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var hashtagColor: UIColor = .blue {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var hashtagSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var URLColor: UIColor = .blue {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var URLSelectedColor: UIColor? {
        didSet { updateLabel(parseText: false) }
    }
    @IBInspectable public var lineSpacing: Float = 0 {
        didSet { updateLabel(parseText: false) }
    }
    
    // MARK: methods
    public func mentionHandler(handler: @escaping (String) -> ()) {
        mentionHandler = handler
    }
    
    public func hashtaghandler(handler: @escaping (String) -> ()) {
        hashtagHandler = handler
    }
    
    public func linkHandler(handler: @escaping (NSURL) -> ()) {
        linkHandler = handler
    }
    
    public func filterMention(predicate: @escaping (String) -> Bool) {
        mentionFilterPredicate = predicate
        updateLabel()
    }
    
    public func filterHashtag(predicate: @escaping (String) -> Bool) {
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
    
    public override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    
    // MARK: - customization
    public func customize(block: (_ label: ActionLabel) -> ()) -> ActionLabel {
        _customizing = true
        block(self)
        _customizing = false
        updateLabel()
        return self
    }
    
    // MARK: - Auto layout
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        textContainer.size = CGSize(width: superSize.width, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: size.width, height: ceil(size.height))
    }
    
    // MARK: - touch events
    func onTouch(touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved:
            if let element = elementAtLocation(location: location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(isSelected: false)
                    selectedElement = element
                    updateAttributesWhenSelected(isSelected: true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(isSelected: false)
                selectedElement = nil
            }
        case .ended:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .Mention(let userHandle): didTapMention(username: userHandle)
            case .Hashtag(let hashtag): didTapHashtag(hashtag: hashtag)
            case .URL(let url): didTapStringURL(stringURL: url)
            case .None: ()
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                self.updateAttributesWhenSelected(isSelected: false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .cancelled:
            updateAttributesWhenSelected(isSelected: false)
            selectedElement = nil
        default:
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
        isUserInteractionEnabled = true
    }
    
    private func updateLabel(parseText: Bool = true) {
        if _customizing { return }
        // clean up previous Action elements
        guard let attributedText = attributedText, attributedText.length > 0 else {
            clearActionElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(attrString: attributedText)
        
        if parseText {
            clearActionElements()
            parseTextAndExtractActionElements(attrString: mutAttrString)
        }
        
        self.addLinkAttribute(mutAttrString: mutAttrString)
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
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// add link attribute
    private func addLinkAttribute(mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
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
        let urlElements = ActionBuilder.getElementsByType(type: .URL, fromText: textString, range: textRange)
        ActionElements[.URL]?.append(contentsOf: urlElements)
        
        //HASHTAGS
        let hashtagElements = ActionBuilder.getElementsByType(type: .Hashtag, fromText: textString, range: textRange, filterPredicate: hashtagFilterPredicate)
        ActionElements[.Hashtag]?.append(contentsOf: hashtagElements)
        
        //MENTIONS
        let mentionElements = ActionBuilder.getElementsByType(type: .Mention, fromText: textString, range: textRange, filterPredicate: mentionFilterPredicate)
        ActionElements[.Mention]?.append(contentsOf: mentionElements)
    }
    
    
    /// add line break mode
    private func addLineBreak(attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
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
        
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
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
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
        for element in ActionElements.flatMap({ $0.1 }) {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    
    
    //MARK: - Handle UI Responder touches
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesMoved(touches, with: event)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        onTouch(touch: touch)
        super.touchesCancelled(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesEnded(touches, with: event)
    }
    
    //MARK: - ActionLabel handler
    private func didTapMention(username: String) {
        guard let mentionHandler = mentionHandler else {
            delegate?.didSelectText(text: username, type: .Mention)
            return
        }
        mentionHandler(username)
    }
    
    private func didTapHashtag(hashtag: String) {
        guard let hashtagHandler = hashtagHandler else {
            delegate?.didSelectText(text: hashtag, type: .Hashtag)
            return
        }
        hashtagHandler(hashtag)
    }
    
    private func didTapStringURL(stringURL: String) {
        guard let urlHandler = linkHandler, let url = NSURL(string: stringURL) else {
            delegate?.didSelectText(text: stringURL, type: .URL)
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
