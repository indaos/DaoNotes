//
//  SectionEditor.swift
//  Notes2
//
//  Created by Denis Mikaya on 29.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI




struct SectionEditor: View {
    @EnvironmentObject var store:Storage

    @State var name = ""
    @State var name_child = ""
    @State var cloud_mode:Int = 0
    @State var submit = false
    @State var namePrompt:String="Please choose color"
    @State var selectedColor:Int = 0
    @State var selectedMainColor:Int = 0
    @State var listItems =  Array<String>()
    @State var isedit = false
    @State var selectedItem:String?
    
    var sec:NSection

    init(_ section: NSection,_ childs:[String]) {
        self.sec=NSection(section.id, name: section.name, type: section.type)
        name=section.name
        cloud_mode=section.type
        let indexColor=getColorIndex(section.color)
        self._selectedMainColor=State<Int>(initialValue: indexColor)
        
        _listItems=State(initialValue: childs)
        
    }
    
    func getColorIndex(_ name:String) -> Int {
        for i in DaoColorSheme.colorsNames.indices {
            if DaoColorSheme.colorsNames[i] == name {
                return i
            }
        }
        return 0
    }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var btnBack : some View { Button(action: {
        self.sec.name=self.name
        self.sec.type=self.cloud_mode
        self.sec.color=DaoColorSheme.colorsNames[self.selectedMainColor]
        self.store.saveSection(section: self.sec)
        var ch = Array<(String,String)>()
        for c in self.listItems {
            let a=c.components(separatedBy:":")
            ch.append( (a[0],a[1]) )
        }
        self.store.saveChildsFor(parent_id: self.sec.id,childs: ch)
        
        self.presentationMode.wrappedValue.dismiss()
    }) {
        HStack {
            Image(systemName: "arrow.left.square")
                .foregroundColor(.primary).scaleEffect(1.5)
                .frame(width: 30,height: 30)
            Text("Save and get back")
        }
        }
    }
    
    func modifySelectedItem(_ s:String) {
        let count=listItems.count
        for i in 0..<count {
            if listItems[i] == selectedItem! {
                listItems[i] = s
            }
        }
    }
    
    var body: some View {
        
        Form {
            Section(header: Text("Main Section")) {
                TextField("Name: ", text: $name)
                
                Picker(selection: $selectedMainColor, label: Text(self.namePrompt)) {
                    ForEach(0 ..< DaoColorSheme.colorsNames.count) {
                        Text(DaoColorSheme.colorsNames[$0]).foregroundColor(Color(DaoColorSheme.getColor(DaoColorSheme.colorsNames[$0])))
                    }
                }
                
                Picker(selection: $cloud_mode, label:
                    Text("Type of Cloud")
                    , content: {
                        Text("Only Local").tag(0)
                        Text("Backup to iCloud").tag(1)
                        Text("Only shared to me").tag(2)
                })
            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all))
            Section(header: Text("Subsections")) {
                TextField("Name: ", text: $name_child)
                
                
                Picker(selection: $selectedColor, label: Text(self.namePrompt)) {
                    ForEach(0 ..< DaoColorSheme.colorsNames.count) {
                        Text(DaoColorSheme.colorsNames[$0]).foregroundColor(Color(DaoColorSheme.getColor(DaoColorSheme.colorsNames[$0])))
                    }
                }
                
                HStack{
                    CircleButton(icon: "plus.square").cornerRadius(5).onTapGesture {
                        withAnimation {
                            if self.listItems.count < 4 {
                                self.listItems.append( self.name_child+":"+DaoColorSheme.colorsNames[self.selectedColor] )
                            }
                        }
                    }
                    if self.isedit {
                        CircleButton(icon: "tray.and.arrow.down").cornerRadius(5).onTapGesture {
                            withAnimation {
                                if self.listItems.count < 4 {
                                    self.modifySelectedItem( self.name_child+":"+DaoColorSheme.colorsNames[self.selectedColor])
                                }
                                self.isedit=false
                            }
                        }
                    }
                    
                }
                List {
                    ForEach(self.listItems,id: \.self) { item in
                        ZStack {
                            Rectangle()
                                .fill(Color(DaoColorSheme.getColor(item)))
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width-40, height: 25)
                            Text(item)
                                .foregroundColor(Color.white)
                                .padding(.horizontal)
                        }
                        .onTapGesture {
                            self.isedit=true
                            self.selectedItem=item
                            let a=item.components(separatedBy:":")
                            self.name_child=a[0]
                            self.selectedColor=self.getColorIndex(a[1])
                        }
                    }.onDelete(perform: self.deleteItem)
                }
            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all))
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: btnBack)
        .onAppear() {
            self.name=self.sec.name
        }
    }
    
    
    private func deleteItem(at indexSet: IndexSet) {
        self.listItems.remove(atOffsets: indexSet)
    }
}

struct SectionEditor_Previews: PreviewProvider {
    static var previews: some View {
        SectionEditor(NSection(0, name: "Section1", type: 0),[""]).environmentObject(Storage(is_debug: true))
    }
}
