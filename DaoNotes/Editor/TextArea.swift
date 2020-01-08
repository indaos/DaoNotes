//
//  TextArea.swift
//  Notes2
//
//  Created by Denis Mikaya on 02.09.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI

class AutoResizableText : UITextView {
    var maxHeight: CGFloat = 0.0
    var coordinator:TextAreaCoordinator? = nil
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("\(self.bounds.size.height) \(self.intrinsicContentSize.height)")
        if (self.bounds.size.height+5 < self.intrinsicContentSize.height) {
            coordinator!.handler!("paste")
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let width:CGFloat = self.frame.size.width
        let size:CGSize = self.sizeThatFits(CGSize.init(width: width, height: CGFloat(MAXFLOAT)))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }
    
    override func paste(_ sender: Any?) {
        if UIPasteboard.general.image != nil  && coordinator != nil {
            if coordinator!.handler != nil {
                coordinator!.note?.past_image(coordinator!.notePartId,image: UIPasteboard.general.image)
                coordinator!.handler!("paste")
                return
            }
        }
        super.paste(sender)
    }
    
}

struct TextFieldView: UIViewRepresentable {
    @EnvironmentObject var store:Storage
    
    @Binding var text: String
    var value:String=""
    var coordinator:TextAreaCoordinator
    
    func makeCoordinator() -> TextAreaCoordinator {
        coordinator.setView(mview: self)
        return coordinator
    }
    
    
    func makeUIView(context: Context) -> UITextView {
        let view = AutoResizableText()
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.delegate = context.coordinator
        view.backgroundColor=DaoColorSheme.getDefBackground() //UIColor( displayP3Red: 254, green: 246, blue:  226,alpha: 1.0 )
        view.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5);
        view.contentSize = view.frame.size
        view.showsHorizontalScrollIndicator = false;
        view.isScrollEnabled = false
        view.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5);
        view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500), for: NSLayoutConstraint.Axis.horizontal)
        view.contentInsetAdjustmentBehavior = .never
        view.coordinator=self.coordinator
        
        
        view.contentSize.width = 1.0
        view.bounces = false
        
        if let res=self.store.loadSettings() {
            let fontsize=Double(res["fontsize"] as! Int)
            view.font = UIFont(name: "Helvetica", size: CGFloat(fontsize))
        } else {
            view.font = UIFont(name: "Helvetica", size: 12)
        }
        
        if coordinator.isTable {
            view.returnKeyType = UIReturnKeyType.done
        }
        view.text = self.text
        coordinator.ptr=view
        coordinator.addAccessoryView()
        
        
        if coordinator.isTable {
            view.text=self.value
        } else {
            view.attributedText=TextAreaCoordinator.fromHtml(html: self.value)
            print("**** 1 init: \(self.value)")
            
        }
        
        let interaction = UIContextMenuInteraction(delegate: coordinator)
        view.addInteraction(interaction)
        
        view.textContainer.lineBreakMode = .byCharWrapping
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
}



struct TextFindView: UIViewRepresentable {
    @EnvironmentObject var store:Storage
    var value:String=""
    var coordinator:FindFieldCoordinator
    
    func makeCoordinator() -> FindFieldCoordinator {
        coordinator.setView(mview: self)
        coordinator.setInitValue(txt: value)
        return coordinator
    }
    
  
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.delegate = context.coordinator
        view.backgroundColor=DaoColorSheme.getDefBackground()  //UIColor( displayP3Red: 254, green: 246, blue:  226,alpha: 1.0 )
        view.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5);
        view.contentSize = view.frame.size
        view.showsHorizontalScrollIndicator = false;
        view.isScrollEnabled = false
        view.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5);
        view.contentInsetAdjustmentBehavior = .never
        if let res=self.store.loadSettings() {
            let fontsize=Double(res["fontsize"] as! Int)
            view.font = UIFont(name: "Helvetica", size: CGFloat(fontsize))
        } else {
            view.font = UIFont(name: "Helvetica", size: 12)
        }
        coordinator.ptr=view
        coordinator.addAccessoryView()
        
        
        return view
    }

    
  func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)

  }
  
}



struct TextFind :View {
    @EnvironmentObject var store:Storage
    @State var text_space :String = ""
    var initval:String
    var text_cr:FindFieldCoordinator
    
    var body: some View {
        TextFindView( value:initval,
                      coordinator:text_cr)
            .onTapGesture {
        }
    }
}

struct TextArea :View {
    @EnvironmentObject var store:Storage
    @State var text_space :String
    var initval:String
    var text_cr:TextAreaCoordinator
    
    var body: some View {
        TextFieldView(text: self.$text_space,
                      value:initval,
                      coordinator:text_cr)
            .onTapGesture {
        }
    }
}

struct TextAreaContentView: View {
    @State var cell1:String=""
    @State var cell2:String=""
    
    var body: some View {
        VStack {
            TextFind(initval:"Statement",
                     text_cr: FindFieldCoordinator())
        }.frame(width:100,height: 40)
            .background(Color.gray)
    }
}

struct TextArea_Previews: PreviewProvider {
    static var previews: some View {
        TextAreaContentView().environmentObject(Storage(is_debug: true))
    }
}
