//
//  NoteList.swift
//  Notes2
//
//  Created by Denis Mikaya on 11.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI


struct CButton: View {
    @State private var tapped = false
    let label: String
    let action: () -> ()
    
    var body: some View {
        let g = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged({ _ in
                withAnimation { self.tapped = true }
            })
            .onEnded({ _ in
                withAnimation { self.tapped = false }
                self.action()
            })
        
        return CircleButton(icon: label)
            .foregroundColor(Color(UIColor.link)
                .opacity(tapped ? 0.5 : 1.0))
            .gesture(g)
        
    }
}

struct CircleButton: View {
    @EnvironmentObject var store:Storage
    var icon = "person.crop.circle"
    
    var body: some View {
        return HStack {
            Image(systemName: icon)
                .foregroundColor(Color.white)
        }
        .frame(width: 40, height: 40)
        .background(LinearGradient(gradient:  Gradient(colors: [Color(self.store.getMainColor()), Color.gray]), startPoint: .top, endPoint: .bottom))
    }
}

struct ToolBar: View {
    
    @EnvironmentObject var store:Storage
    @Environment(\.editMode) var mode
    
    var handler:()->Void
    
    
    func checkSectionStatus() -> Bool {
        if self.store.selectedSection == -1 {
            return true
        }
        let s=self.store.getSection(self.store.selectedSection)
        if (self.store.cloud?.cStatus != .available  && s?.type != 0) || s?.type == 2 {
            return true
        }
        return false
    }
    
    func getCurrOpacity() ->Double {
        return (self.checkSectionStatus() ? 0 : 1)
    }
    
    var body: some View {
        HStack {
                Button(action: {
                    self.handler()
                    self.store.addRow(self.handler)
                }) {
                    CircleButton(icon: "plus.circle")
                }.disabled(self.checkSectionStatus()).cornerRadius(5).opacity(self.getCurrOpacity()) 
            }
    }

}


struct NoteList: View {
    
    
    @EnvironmentObject var store:Storage
    @State var whatfind = ""
    
    @State var showingItem:Int? = -1
    @State var isLoading:Bool=false
    @State private var showingAlert = false
    @State var isnew:Bool?=false
    
    var hh:(_ b:Bool)->Void
    
    init(hh: @escaping (_ b:Bool)->Void) {
        self.hh=hh
        UINavigationBar.appearance().backgroundColor = DaoColorSheme.getDefHeadBackground()
        UITableView.appearance().backgroundColor =  DaoColorSheme.getDefBackground()
        UITableView.appearance().separatorStyle = .singleLine
        
    }
    
    func getImageName(_ note:Note) ->String {
        if (note.contentType & 4) != 0 &&  (note.contentType & 8) != 0 {
            return "photo.on.rectangle"
        } else  if (note.contentType & 4) != 0 {
            return "photo"
            
        } else if (note.contentType & 8) != 0 {
            return "table"
            
        }
        return "rectangle.stack"
    }
    
    var body: some View {
        NavigationView {
            ZStack{
                Rectangle().foregroundColor( Color(DaoColorSheme.getDefBackground() )).edgesIgnoringSafeArea(.all)
                
                AwaitingView(isShow: $isLoading) {
                    List {
                        ForEach(self.store.getSectionNotes()) { item in
                            NavigationLink(destination: NoteEditor(hh: self.hh,note: item,itemid: self.$showingItem),
                                           tag: Int(item.id),selection: self.$showingItem) {
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 5.0) {
                                                    Image(systemName: self.store.isNewNote(note: item,isnew: self.$isnew)  ? "eye.slash" : self.getImageName(item))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 30, height: 30)
                                                        .foregroundColor(self.isnew! ? Color.red:Color.black) //.rotationEffect(Angle(degrees:90))
                                                    VStack(alignment: .leading) {
                                                        Button(self.store.getNote(item.id)!.getSomeText()) {
                                                            self.showingItem = Int(item.id)
                                                        }.font(self.isnew! ? .caption : .callout)
                                                        HStack {
                                                            Image(systemName: item.savedLocaly ? "square.and.arrow.down" : "square.stack.3d.up.slash").resizable().frame(width: 12, height: 12)
                                                            Image(systemName: item.isInCloud() ? "cloud" : "icloud.slash").resizable().frame(width: 12, height: 12)
                                                            Image(systemName: item.locked ? "lock" : "lock.slash").resizable().frame(width: 12, height: 12)
                                                            Text(self.store.isSharedSection() ? "Modified: " : self.store.getNote(item.id)!.dateToString())
                                                                .font(.footnote)
                                                                .fontWeight(self.isnew!  ? .bold : .none)
                                                                .foregroundColor(.gray)
                                                            
                                                        }
                                                    }
                                                }
                                                HStack{
                                                    Spacer()
                                                    Text(self.store.isSharedSection() ? self.store.getNote(item.id)!.getHistory() : "")
                                                        .font(.footnote)
                                                        .fontWeight(self.isnew!  ? .bold : .none)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                            }.listRowBackground(Color(DaoColorSheme.getDefBackground()).edgesIgnoringSafeArea(.all))
                        }
                        .onDelete { index in
                            self.store.deleteRow(index: index.first!)
                        }
                        
                    }.padding(EdgeInsets(top: 1,leading: 0,bottom: 100,trailing: 0))
                }
                HScrollMenu(refreshLoading: self.$isLoading).frame(width:UIScreen.main.bounds.width,height:120).offset(x:0,y:self.getMenuOffset())
                    .alert(isPresented: $showingAlert) {
                        let msg=self.store.cloud?.getWarningMessage()
                        return Alert(title: Text("Warning!"), message: Text(msg!) )
                }
                .navigationBarItems(
                    leading: HStack {
                        HStack (spacing: 10.0 ){
                            Image(systemName: "magnifyingglass").resizable().frame(width: 20, height: 20)
                            TextFind(initval: "",text_cr: FindFieldCoordinator().setHandler(hh:{ txt,isall in
                                self.store.filterSectionNotes(txt,isall)
                            }
                            )).frame(height:30).background(Color(red: 211 / 255, green: 211 / 255, blue: 211 / 255)).frame(width:210).overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            ToolBar(handler:{
                                self.isLoading.toggle()
                            })
                        }
                    }
                )
                    .onAppear{
                        if self.store.cloud?.cStatus != .available {
                            self.showingAlert=true
                        }
                }
            }
        }
    }
    
    func getMenuOffset() -> CGFloat {
        if UIScreen.main.bounds.height < 800 {
            return UIScreen.main.bounds.width-150
        } else {
            return UIScreen.main.bounds.width-100
        }
    }
}

#if DEBUG
struct NoteList_Previews: PreviewProvider {
    static var previews: some View {
        //showBottomMenu: .constant(true)
        NoteList(hh:{_ in }).environmentObject(Storage(is_debug: true))
    }
}
#endif
