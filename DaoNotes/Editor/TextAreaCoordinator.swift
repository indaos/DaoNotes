//
//  CoordinatorTF.swift
//  DaoNotes
//
//  Created by Denis Mikaya on 20.10.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import Foundation
import SwiftUI


class TextAreaCoordinator: NSObject, UITextViewDelegate,UIContextMenuInteractionDelegate {
      
        var note:Note?
        var isTable=false
        var ptr:UITextView? = nil
        var field: TextFieldView?
        var handler: ((_ txt:String)->Void)?
        var notePartId:Int = -1

        init(_ note:Note?,isTable:Bool) {
            self.note=note
            self.isTable=isTable
        }
    
        func setHandler(hh: @escaping(_ txt:String)->Void) -> TextAreaCoordinator {
            handler=hh
            return self
        }
    
       func setValue ( txt:String) ->TextAreaCoordinator {
            if ptr != nil   {
                ptr!.text=txt
            }
            return self
        }
    
        func setView( mview:TextFieldView){
            field=mview
        }
    
    
       func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
       {
            
            if handler != nil && isTable  {
                return UIContextMenuConfiguration(identifier: nil,
                                                  previewProvider: nil,
                                                  actionProvider: { [weak self] _ in
                  return self?.makeContextMenu()
                })
            } else {
                let cursorPosition = getCurrentCursorPosition((interaction.view as! UITextView))
                let result=checkString(string: field!.text,position:cursorPosition)
                if result.0 != nil && result.1 != nil && result.0.count > 0 && result.1.count > 0 {
                    return UIContextMenuConfiguration(identifier: nil,
                                                      previewProvider: nil,
                                                      actionProvider: { [weak self] _ in
                      return UIMenu(__title: "",
                              image: nil,
                              identifier: nil,
                              children: [
                                    UIAction(title: result.1,
                                    image: UIImage(systemName: "circle")) { _ in
                                              let url: NSURL = URL(string: result.0)! as NSURL
                                              UIApplication.shared.open(url as URL)
                                        }
                                  ])
                    })
                }
            }
            return nil
        }
    
       private func makeContextMenu() -> UIMenu {
        let vert = UIAction(title: "VERTICAL",
                                image: UIImage(systemName: "sum")) { _ in
                                    if self.handler != nil {
                                        self.setValue(txt:"VSUM")
                                        self.handler!("")
                                    }
           }

        let horz = UIAction(title: "HORIZONTAL",
                                  image: UIImage(systemName: "sum")) { _ in
                                    if self.handler != nil {
                                        self.setValue(txt:"HSUM")
                                        self.handler!("")
                                    }
           }

            return UIMenu(__title: "",
                     image: nil,
                     identifier: nil,
                     children: [vert, horz])
        }
    

    
    func textViewDidBeginEditing(_ textView: UITextView) {
        ptr=textView
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        field!.text = textView.text
        selectThings(string: field!.text,textView: textView)
        
        if handler != nil {
            handler!(textView.text)
        }
        
    }
    
  

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if isTable && text == "\n" {
            textView.resignFirstResponder()
        }
        
        return true
    }
    
    
    static func toHtml( str: NSAttributedString) ->String?{
        do {
            let htmlData = try str.data(from: NSRange(location: 0, length: str.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.rtf]);
            return String.init(data: htmlData, encoding: String.Encoding.utf8)
        } catch {
            print("error:", error)
            return nil
        }
    }
    
    static func fromHtml(html: String) -> NSAttributedString?{
        let data = Data(html.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            return attributedString
        }
        return nil
    }
    
    
    func addAccessoryView() -> Void {
        let accessory: UIView = {
            let accessoryView = UIView(frame: .zero)
            accessoryView.backgroundColor = .lightGray
            accessoryView.alpha = 0.6
            return accessoryView
        }()
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: accessory.frame.size.width, height: 44))
        
        let bold = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: self, action: #selector(self.boldButtonTapped(button:)))
        let italic = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: self, action: #selector(self.italicButtonTapped(button:)))
        let underline = UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain, target: self, action: #selector(self.underButtonTapped(button:)))
        let strike = UIBarButtonItem(image: UIImage(systemName: "strikethrough"), style: .plain, target: self, action: #selector(self.strikeButtonTapped(button:)))
        
        let left = UIBarButtonItem(image: UIImage(systemName: "text.alignleft"), style: .plain, target: self, action: #selector(self.leftButtonTapped(button:)))
        let center = UIBarButtonItem(image: UIImage(systemName: "text.aligncenter"), style: .plain, target: self, action: #selector(self.centerButtonTapped(button:)))
        let right = UIBarButtonItem(image: UIImage(systemName: "text.alignright"), style: .plain, target: self, action: #selector(self.rightButtonTapped(button:)))
        let justify = UIBarButtonItem(image: UIImage(systemName: "text.justify"), style: .plain, target: self, action: #selector(self.justifyButtonTapped(button:)))
        
        let textbig = UIBarButtonItem(image: UIImage(systemName: "textformat.size"), style: .plain, target: self, action: #selector(self.textlargeButtonTapped(button:)))
        let textsmall = UIBarButtonItem(image: UIImage(systemName: "textformat"), style: .plain, target: self, action: #selector(self.textsmallButtonTapped(button:)))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let close = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeButtonTapped(button:)))
        
        
        toolBar.items = [spacer,bold,italic,underline,strike,left,center,right,justify,textbig,textsmall,close]
        toolBar.tintColor = UIColor.black
        ptr!.inputAccessoryView = toolBar
    }
    
    enum CheckStyle {
        case  none
        case  bold
        case  italic
        case  underline
        case  stikeeout
        case  left
        case  right
        case  center
        case  justified
    }

    @objc func closeButtonTapped(button:UIBarButtonItem) -> Void {
        ptr?.resignFirstResponder()
    }
    
    func changeFontSize( inc: Bool) {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            let attr = NSMutableAttributedString( attributedString: ptr!.attributedText.attributedSubstring(from: NSRange(location: location, length: length)))
            attr.enumerateAttributes(in: NSRange(0..<attr.length), options: []) { (attributes, range, _) -> Void in
                for (key, value) in attributes {
                    if key == NSAttributedString.Key.font  {
                        if let font = value as? UIFont {
                            var font1=font.withSize(font.pointSize + (inc ? 2.0 : -2.0))
                            ptr!.textStorage.addAttribute(NSAttributedString.Key.font, value:  font1, range: NSRange(location: location, length: length))
                        }
                    }
                }
            }
            ptr!.setNeedsLayout()
        }
    }
    
    func changeFontStyle( prop: NSAttributedString.Key,arg: CheckStyle) ->Bool {
        var result=false
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            let attr = NSMutableAttributedString( attributedString: ptr!.attributedText.attributedSubstring(from: NSRange(location: location, length: length)))
            attr.enumerateAttributes(in: NSRange(0..<attr.length), options: []) { (attributes, range, _) -> Void in
                for (key, value) in attributes {
                    if key == NSAttributedString.Key.font && key == prop {
                        if let font = value as? UIFont {
                            var font1=font
                            var symt=font.fontDescriptor.symbolicTraits
                            if arg == .bold {
                                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                                    symt.remove(.traitBold)
                                } else {
                                    symt.insert(.traitBold)
                                }
                            } else if arg == .italic {
                                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                                    symt.remove(.traitItalic)
                                } else {
                                    symt.insert(.traitItalic)
                                }
                            }
                            font1=UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(symt)!,size: font.pointSize)
                            ptr!.textStorage.addAttribute(NSAttributedString.Key.font, value:  font1, range: NSRange(location: location, length: length))
                        }
                    } else
                        if key == NSAttributedString.Key.underlineStyle && key == prop {
                            let i=value as? Int
                            if i==1 {
                                ptr!.textStorage.addAttribute(NSAttributedString.Key.underlineStyle,value: 0, range: NSRange(location: location, length: length))
                                result=true
                            }
                            break
                        } else
                            if key == NSAttributedString.Key.strikethroughStyle && key == prop {
                                let i=value as? Int
                                if i==1 {
                                    ptr!.textStorage.addAttribute(NSAttributedString.Key.strikethroughStyle,value: 0, range: NSRange(location: location, length: length))
                                    result=true
                                }
                                break
                            } else
                                if key == NSAttributedString.Key.paragraphStyle && key == prop {
                                    if let paragraph = value as? NSMutableParagraphStyle {
                                        switch (arg) {
                                        case .left: result=paragraph.alignment == .left
                                        case .right: result=paragraph.alignment == .right
                                        case .center: result=paragraph.alignment == .center
                                        case .justified: result=paragraph.alignment == .justified
                                        default:
                                            result=false
                                        }
                                        if result {
                                            break
                                        }
                                    }
                                    
                    }
                }
            }
        }
        return result
    }
      
    
    
    @objc func textlargeButtonTapped(button:UIBarButtonItem) -> Void {
        changeFontSize(inc: true)
    }
    
    @objc func textsmallButtonTapped(button:UIBarButtonItem) -> Void {
        changeFontSize(inc: false)
        
    }
    
    @objc func boldButtonTapped(button:UIBarButtonItem) -> Void {
        changeFontStyle(prop: NSAttributedString.Key.font, arg: .bold)
        
    }
    
    @objc func italicButtonTapped(button:UIBarButtonItem) -> Void {
        changeFontStyle(prop: NSAttributedString.Key.font, arg: .italic)
        
    }
    @objc func underButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.underlineStyle, arg: .right) {
                ptr!.textStorage.addAttribute(NSAttributedString.Key.underlineStyle,value: 1.0, range: NSRange(location: location, length: length))
            }
        }
    }
    @objc func strikeButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.strikethroughStyle, arg: .none) {
                ptr!.textStorage.addAttribute(NSAttributedString.Key.strikethroughStyle,value: 1.0, range: NSRange(location: location, length: length))
            }
        }
    }
    @objc func leftButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.paragraphStyle, arg: .none) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.baseWritingDirection = .leftToRight
                paragraph.alignment = .left
                ptr!.textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: NSRange(location: location, length: length))
            }
        }
    }
    @objc func rightButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.paragraphStyle, arg: .right) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.baseWritingDirection = .leftToRight
                paragraph.alignment = .right
                ptr!.textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: NSRange(location: location, length: length))
            }
        }
    }
    
    
    @objc func centerButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.paragraphStyle, arg: .center) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.baseWritingDirection = .leftToRight
                paragraph.alignment = .center
                ptr!.textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: NSRange(location: location, length: length))
            }
        }
    }
    
    @objc func justifyButtonTapped(button:UIBarButtonItem) -> Void {
        if let textRange = ptr!.selectedTextRange {
            let location = ptr!.offset(from: ptr!.beginningOfDocument, to: textRange.start)
            let length = ptr!.offset(from: textRange.start, to: textRange.end)
            var arg=false
            
            if !changeFontStyle( prop: NSAttributedString.Key.paragraphStyle, arg: .justified) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.baseWritingDirection = .leftToRight
                paragraph.alignment = .justified
                ptr!.textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: NSRange(location: location, length: length))
            }
        }
    }
    
    @objc func bulletButtonTapped(button:UIBarButtonItem) -> Void {
        // do you stuff with done here
    }
    
    
    
    func addBulletstyle(stringList: [String],
                        font: UIFont,
                        bullet: String = "\u{2022}",
                        indentation: CGFloat = 20,
                        lineSpacing: CGFloat = 2,
                        paragraphSpacing: CGFloat = 12,
                        textColor: UIColor = .gray,
                        bulletColor: UIColor = .green) -> NSAttributedString {
        
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: bulletColor]
        
        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)]
        paragraphStyle.defaultTabInterval = indentation
        
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        
        let bulletList = NSMutableAttributedString()
        for string in stringList {
            let formattedString = "\(bullet)\t\(string)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)
            
            attributedString.addAttributes(
                [NSAttributedString.Key.paragraphStyle : paragraphStyle],
                range: NSMakeRange(0, attributedString.length))
            
            attributedString.addAttributes(
                textAttributes,
                range: NSMakeRange(0, attributedString.length))
            
            let string:NSString = NSString(string: formattedString)
            let rangeForBullet:NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }
        
        return bulletList
    }
    
    
    
    @objc func updateTextView(notification: Notification)
    {
    }
    
    
    func checkString(string:String,position:Int) ->(String,String){
        let detectorType: NSTextCheckingResult.CheckingType = [.address, .phoneNumber,.link]
        do {
            let detector = try NSDataDetector(types: detectorType.rawValue)
            let results = detector.matches(in: string, options: [], range:
                NSRange(location: 0, length: string.utf16.count))
            
            for result in results {
                if let range = Range(result.range, in: string) {
                    let matchResult = string[range]
                    print("result: \(matchResult), range: \(result.range)")
                    if result.range.contains(position) {
                        switch (result.resultType) {
                        case .address:
                            let addr="http://maps.apple.com/maps?address=\(matchResult)"
                            let escapedString = addr.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
                            return (escapedString!,"Show on map")
                        case .phoneNumber:
                            return ("tel://\(matchResult)","Make a call")
                        case .link:
                            return ("\(matchResult)","Open in a browser")
                        default:
                            return ("","")
                        }
                    }
                }
            }
            
        } catch {
            print("handle error")
        }
        return ("","")
    }
      
    func selectThings(string:String,textView: UITextView) {
        let attr = NSMutableAttributedString(attributedString: textView.attributedText)
        let originalRange = NSMakeRange(0, attr.length)
        
        attr.enumerateAttributes(in: NSRange(0..<attr.length), options: []) { (attributes, range, _) -> Void in
            for (attribute, object) in attributes {
                
                if attribute == NSAttributedString.Key.foregroundColor {
                    attr.removeAttribute(attribute, range: range)
                }
            }
        }
        
        textView.textStorage.setAttributedString(attr)
        
        
        let detectorType: NSTextCheckingResult.CheckingType = [.address, .phoneNumber,.link]
        do {
            let detector = try NSDataDetector(types: detectorType.rawValue)
            let results = detector.matches(in: string, options: [], range:
                NSRange(location: 0, length: string.utf16.count))
            
            for result in results {
                if let range = Range(result.range, in: string) {
                    let matchResult = string[range]
                    print("result: \(matchResult), range: \(result.range)")
                    switch (result.resultType) {
                    case .address:
                        textView.textStorage.addAttribute(NSAttributedString.Key.foregroundColor,
                                                          value: UIColor.blue,range: result.range)
                    case .phoneNumber:
                        textView.textStorage.addAttribute(NSAttributedString.Key.foregroundColor,
                                                          value: UIColor.blue,range: result.range)
                    case .link:
                        textView.textStorage.addAttribute(NSAttributedString.Key.foregroundColor,
                                                          value: UIColor.blue,range: result.range)
                    default:
                        textView.textStorage.addAttribute(NSAttributedString.Key.foregroundColor,
                                                          value: UIColor.white,range: result.range)
                    }
                }
            }
            
        } catch {
            print("handle error")
        }
    }
    
    
    func getSubstring( text:String,start:Int,end:Int) ->String {
        if end < start {
            return ""
        }
        let startIndex = text.index(text.startIndex, offsetBy: start)
        let endIndex = text.index(text.startIndex, offsetBy: end)
        return String(text[startIndex...endIndex])
    }
    
    func getLastChar(_ textView: UITextView) ->String {
        var pos=getCurrentCursorPosition(textView)
        let s:String = textView.text!
        return getSubstring(text: s,start: pos-1,end: pos-1)
    }
    
    func findLastBreak(_ textView: UITextView,fromPos:Int) -> Int{
        let s:String = textView.text!
        var index=fromPos // s.count-1
        while index>=0 {
            let startIndex = s.index(s.startIndex, offsetBy: index)
            let b=s[startIndex...startIndex]
            if b == " " || b == "\n" || b=="\t" || b=="," || b==";" {
                return index
            }
            index-=1
        }
        return 0
    }
    
    func findLastNewLine(_ textView: UITextView,fromPos:Int) -> Int{
        let s:String = textView.text!
        var index=fromPos
        while index>=0 && index < s.count {
            let startIndex = s.index(s.startIndex, offsetBy: index)
            let b=s[startIndex...startIndex]
            if b == "\n"  {
                return index
            }
            index-=1
        }
        return 0
    }
    
    func getCurrentCursorPosition(_ textView: UITextView) -> Int {
        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: textView.selectedTextRange!.start)
        return cursorPosition
    }
    
    func selectText(_ textView: UITextView,start:Int,count:Int,color:UIColor) {
        textView.textStorage.addAttribute(NSAttributedString.Key.backgroundColor,
                                          value: color,range:  NSRange(location:start, length: count))
    }
    
    
}



