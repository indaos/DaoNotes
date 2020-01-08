//
//  CoordinatorTF.swift
//  DaoNotes
//
//  Created by Denis Mikaya on 20.10.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import Foundation
import SwiftUI


class FindFieldCoordinator: NSObject, UITextViewDelegate {
    
    var initvalue:String?=nil
    var handler: ((_ txt:String,_ all:Bool)->Void)?
    var ptr:UITextView? = nil
    var field: TextFindView?
    
    func setHandler(hh: @escaping(_ txt:String,_ all:Bool)->Void) -> FindFieldCoordinator {
        handler=hh
        return self
    }
    
    func setInitValue ( txt:String )  {
        initvalue=txt
    }
    
    func setView( mview:TextFindView){
        field=mview
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        if handler != nil {
            handler!(textView.text,searchGlobally)
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text=="\n" || textView.text.count > 28 {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if textView.text.count == 0 {
            textView.endEditing(true)
            return true
        }
        return false
    }
    
    func addAccessoryView() {
        let accessory: UIView = {
            let accessoryView = UIView(frame: .zero)
            accessoryView.backgroundColor = .lightGray
            accessoryView.alpha = 0.6
            return accessoryView
        }()
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: accessory.frame.size.width, height: 44))
        
        let done = UIBarButtonItem(image: UIImage(systemName: "xmark.square"), style: .plain, target: self, action: #selector(self.tapDone(button:)))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let mode = UIBarButtonItem(image: UIImage(systemName: "rectangle"), style: .plain, target: self, action: #selector(self.tapMode(button:)))
        let label1=ToolBarTitleItem(text: "Search mode (local/folders): ", font: .systemFont(ofSize: 12), color: .black)
        let label2=ToolBarTitleItem(text: "Dismiss: ", font: .systemFont(ofSize: 12), color: .black)
        
        toolBar.items = [spacer,label1,mode,spacer,label2,done]
        toolBar.tintColor = UIColor.black
        ptr!.inputAccessoryView = toolBar
        
    }
    
    @objc func tapDone(button:UIBarButtonItem){
        ptr!.text=""
        ptr!.becomeFirstResponder()
        self.ptr!.endEditing(true)
    }
    
    var  searchGlobally=false
    
    @objc func tapMode(button:UIBarButtonItem){
        searchGlobally.toggle()
        if searchGlobally {
            button.image=UIImage(systemName: "rectangle.on.rectangle")
        } else {
            button.image=UIImage(systemName: "rectangle")
        }
    }
}

class ToolBarTitleItem: UIBarButtonItem {
    
    init(text: String, font: UIFont, color: UIColor) {
        let label =  UILabel(frame: UIScreen.main.bounds)
        label.text = text
        label.sizeToFit()
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        super.init()
        customView = label
    }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}

