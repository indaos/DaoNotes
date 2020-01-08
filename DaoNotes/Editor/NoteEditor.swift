//
//  NoteEditor.swift
//  Notes2
//
//  Created by Denis Mikaya on 12.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI
import LocalAuthentication
import Combine


struct UserList: View {
    @EnvironmentObject var store:Storage
    @Binding var isPresented:Bool
    var localid:Int64
    @State private var values: [String] = Array<String>(repeating: "", count: 100)
    @State private var shared: [Bool] = Array<Bool>(repeating: true, count: 100)
    @State var isLoading:Bool=true
    
    
    func hideModal( ) {
        let window = UIApplication.shared.windows.first
        window?.rootViewController?.dismiss(animated: true)
    }
    
    func doShareThisRecord() {
        self.store.doShareofRecord(localid: localid,values: values,shared: shared)
        values = Array<String>(repeating: "", count: 100)
        shared = Array<Bool>(repeating: true, count: 100)
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    self.doShareThisRecord()
                    self.hideModal()
                }) {
                    HStack {
                        Image(systemName: "arrow.left.square")
                            .foregroundColor(.primary).scaleEffect(1.5)
                            .frame(width: 30,height: 30)
                        Text("Share and get back")
                    }
                    
                }
            }
            VStack(alignment: .center) {
                HStack {
                    Button(action: {
                        self.isLoading.toggle()
                        self.store.addSharedUserToCache()
                        self.isLoading.toggle()
                    }) {
                        CircleButton(icon: "plus.square")
                    }
                }
            }.frame(width: UIScreen.main.bounds.width)
            HStack{
                Spacer()
                Text("Users who have permissions to edit the note").font(.subheadline)
                Spacer()
            }
            AwaitingView(isShow: $isLoading) {
                List {
                    ForEach(self.store.getSharedUsersFor(id: self.localid,loading: self.$isLoading),id:\.self.id) {  (index,name,profileid) in
                        HStack {
                            TextField(name,text: self.$values[index] ).onAppear {
                                DispatchQueue.main.async {
                                    self.values[index]=name
                                }
                            }
                            Button(action: {
                                self.shared[index].toggle()
                            }) {
                                CircleButton(icon: self.shared[index] ? "checkmark":"")
                            }
                        }
                    }
                }
            }
        }
    }
}


struct NoteEditor: View {
   
    @EnvironmentObject var store:Storage
    
    @State var refresh:Bool=false
    @State var showImagePicker: Bool = false
    @State var image: UIImage? = nil
    @State  var cell=[String](repeating: "", count: 100)
    @Binding var itemId:Int?
    @State var isSharedUserPresented:Bool = false
    @State var detectText=false
    @State var locked=false
    @State var values:[Bool] = Array<Bool>(repeating: true, count: 10)
    
    var pointer=0
    var note:Note?
    var hh:(_ b:Bool)->Void

    
    init( hh: @escaping (_ b:Bool)->Void,note: Note,itemid:Binding<Int?>) {
        
        self.hh=hh
        hh(true)
        note.resetFocus()
        
        _itemId=itemid
        if itemId == nil || itemId == -1 {
            self.note = nil
            return
        }
        self.note=note
        pointer=note.body.count
        _locked=State(initialValue:note.locked)
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = DaoColorSheme.getDefBackground()
    }
    
    init(hh: @escaping (_ b:Bool)->Void) {
        self.hh=hh
        hh(true)
        _itemId = .constant(1)
        note=Note()
        note!.add("AAAAAAgfdgdsfg\n\ntertert")
        note!.add(3, ncol: 3, text: "2,3,4,6,7,8,9,1,2")
        note!.add("100+2000*(200+1)-3\ntwertert\n")
        pointer=note!.body.count
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = DaoColorSheme.getDefBackground()
    }
    
    
    func toUInt8(_ v:Int) ->UInt8 {
        return UInt8(v)
    }
    
    func toInt(_ v:UInt8) ->Int {
        return Int(v)
    }
   
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var btnBack : some View { Button(action: {
        if self.store.mathMode {
            self.store.mathMode.toggle()
        }
        self.note!.refreshValues()
        if self.note!.savedLocaly {
            self.store.saveContent(self.note!)
        }
        if self.store.isCloudSection() || self.store.isSharedSection() {
            self.store.markNoteAsRead(note: self.note!)
            self.store.saveiCloudContent(self.note!)
        }
        self.itemId = -1
        self.note?.body = []
        UITableView.appearance().separatorStyle = .singleLine
        self.hh(false)
        self.store.setMenuActive(true)
        
    }) {
        HStack {
            Image(systemName: "arrow.left.square")
                .foregroundColor(.primary).scaleEffect(1.5)
                .frame(width: 30,height: 30)
            Text("Save and get back")
        }
        }
    }
    
    
    func showModal( nid:Int64) {
        let window = UIApplication.shared.windows.first
        window?.rootViewController?.present(UIHostingController(rootView: UserList(isPresented: self.$isSharedUserPresented,localid: nid).environmentObject(self.store)), animated: true)
        
    }
    

    func doAuth( h: @escaping (_ res:Bool) -> Void) ->Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Touch ID identification needed"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        h(true)
                    } else {
                       h(false)
                    }
                }
            }
            return false
        } else {
            return true
        }
    }
    
    @State var currentDragImage="photo.on.rectangle"
    @State var isLoading=false
    @State private var dragOffset: CGSize = CGSize(width: 1000,height: 1000)
    
    var body: some View {
        AwaitingView(isShow: $isLoading) {
            ZStack {
                Rectangle().foregroundColor( Color(DaoColorSheme.getDefBackground() )).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        if self.values[0] {
                            Button(action: {
                                self.store.mathMode.toggle()
                                self.store.refresh.toggle()
                            }){
                                CircleButton(icon: self.store.mathMode ? "cursor.rays":"x.squareroot").cornerRadius(5)
                            }
                        }
                        if self.values[1] {
                            
                            Button(action: {
                                self.note!.add(2, ncol: 2, text: "")
                                self.note!.add(" ")
                                self.refresh.toggle()
                            }) {
                                CircleButton(icon: "table").cornerRadius(5)
                            }
                        }
                        
                        if self.values[3] {
                            
                            Button(action: {
                                self.showImagePicker.toggle()
                            }) {
                                CircleButton(icon: "camera").cornerRadius(5)
                            }
                        }
                        if self.values[4] {
                            
                            Button(action: {
                                self.detectText=true
                                self.showImagePicker.toggle()
                            }) {
                                CircleButton(icon: "doc.text.viewfinder")
                            }
                        }
                        if self.values[2] {
                            Button(action: {
                                self.note!.add(2, ncol: 100, text: "")
                                self.note!.add(" ")
                                self.refresh.toggle()
                            }) {
                                CircleButton(icon: "globe").cornerRadius(5)
                            }
                        }
                        if self.values[5] {
                            
                            Button(action: {
                                self.isSharedUserPresented.toggle()
                                self.showModal(nid: self.note!.id)
                            }) {
                                CircleButton(icon: "icloud.circle").cornerRadius(5)
                                
                            }
                        }
                        if self.values[6] {
                            Button(action: {
                                self.note!.locked.toggle()
                                self.refresh.toggle()
                            }) {
                                CircleButton(icon: self.note!.locked ? "lock.fill" : "lock").cornerRadius(5)
                            }
                        }
                    }
                    if self.note != nil  && self.itemId ?? -1 != -1 {
                        List {
                            VStack(spacing: 0) {
                                if self.refresh {
                                    //     Text("")
                                }
                                ForEach(self.note!.body) { item in
                                    Group {
                                        if item is NoteText {
                                            TextArea(text_space: self.cell[item.id],
                                                     initval: (item as! NoteText).text,
                                                     text_cr: self.note!.getTextCoordinator(item.id).setHandler(hh:{ txt in
                                                        self.refresh.toggle()
                                                     }))
                                                .frame(width:UIScreen.main.bounds.width)
                                        } else if item is NoteTable {
                                            TableView(refr: self.$refresh,crarray: self.note!.getTableCoordinator(item.id),
                                                      initable: (item as! NoteTable),
                                                      ondelete: {
                                                        self.note!.deleteElement(id: item.getId())
                                                        self.note!.tryToJoinTexts()
                                                        self.refresh.toggle()
                                            }).gesture(DragGesture(coordinateSpace: .global)
                                                .onChanged { value in
                                                    self.currentDragImage="rectangle.on.rectangle"
                                                    self.dragOffset = CGSize(width: value.location.x-UIScreen.main.bounds.width/2-50,height: value.location.y-UIScreen.main.bounds.height/2-50)
                                                    print(value.translation)
                                            }
                                            .onEnded {
                                                if $0.translation.height < -10 {
                                                    self.note!.objectMoveUp(id:  item.getId())
                                                    self.store.refresh.toggle()
                                                } else  if $0.translation.height > 10 {
                                                    self.note!.objectMoveDown(id:  item.getId())
                                                    self.store.refresh.toggle()
                                                }
                                                self.dragOffset=CGSize(width: 1000,height: 1000)
                                            })
                                        } else if item is NoteImage {
                                            ImagePanel(image: (item as! NoteImage).image!,width: (item as! NoteImage).width,height: (item as! NoteImage).height,
                                                       delete_handler: {
                                                        self.note!.deleteElement(id: item.getId())
                                                        self.note!.tryToJoinTexts()
                                                        self.store.refresh.toggle()
                                            },changesize_handler: { w,h in
                                                (item as! NoteImage).width=w
                                                (item as! NoteImage).height=h
                                            } ).gesture(DragGesture(coordinateSpace: .global)
                                                .onChanged { value in
                                                    self.currentDragImage="photo.on.rectangle"
                                                    self.dragOffset = CGSize(width: value.location.x-UIScreen.main.bounds.width/2-50,height: value.location.y-UIScreen.main.bounds.height/2-50)
                                            }
                                            .onEnded {
                                                if $0.translation.height < -10 {
                                                    self.note!.objectMoveUp(id:  item.getId())
                                                    self.store.refresh.toggle()
                                                } else  if $0.translation.height > 10 {
                                                    self.note!.objectMoveDown(id:  item.getId())
                                                    self.store.refresh.toggle()
                                                }
                                                self.dragOffset=CGSize(width: 1000,height: 1000)
                                            })
                                        }
                                    }
                                    
                                } // foreach
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                                Text("").frame(height: 50)
                            }.background(Color(DaoColorSheme.getDefBackground()).edgesIgnoringSafeArea(.all))
                                .padding(EdgeInsets(top: -10,leading: 0,bottom: -10,trailing: 0))
                                .frame(width:UIScreen.main.bounds.width).offset(x: self.locked ? 1000 : 0)
                        }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            // .border(Color.white,width: 0)
                            .padding(EdgeInsets(top: 10,leading: -20,bottom: 0,trailing: 0))
                        
                    }

            }.navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: self.btnBack)
            .padding(0)
                .onAppear() {
                    self.store.setMenuActive(false)
                    var settings=self.store.loadSettings()
                    if settings != nil && settings!.count > 0 {
                        let vs:String=settings?["values"] as! String
                        let varr=vs.components(separatedBy: ",")
                        var i = 0
                        for v in varr {
                            let b=Bool(v)
                            self.values[i]=b ?? false
                            i+=1
                        }
                    }
                    if self.note!.locked {
                        if self.doAuth(h: { isok in
                            if !isok {
                                self.presentationMode.wrappedValue.dismiss()
                            } else {
                                self.locked=false
                            }
                        }) {
                            self.locked=false
                        }
                    }
            }.onTapGesture {
                self.note?.requestFocusForTheLastField()
                print("*** tap")
            }
            if (self.showImagePicker) {
                ImagePicker(isShown: self.$showImagePicker, image: self.$image,handler: {
                    if self.image != nil {
                        if self.detectText {
                            self.isLoading.toggle()
                            DispatchQueue.main.async {
                                self.note?.add(self.image!,detect: true)
                                self.isLoading.toggle()
                            }
                        } else {
                            self.note?.add(self.image!)
                        }
                        self.note!.add(" ")
                        
                    }
                })
            }
            Image(systemName: self.currentDragImage).resizable().frame(width:50,height: 50).offset(self.dragOffset)
            
            
            }
        }
    }
}

#if DEBUG
struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditor(hh:{_ in}).environmentObject(Storage(is_debug: true))
    }
}
#endif
