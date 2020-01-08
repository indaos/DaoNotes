//
//  SectionsPanel.swift
//  Notes2
//
//  Created by Denis Mikaya on 28.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI

struct SectionsPanel: View {
    
    @EnvironmentObject var store:Storage
    @Binding var showingModal:Bool
    
    @State var whatfind  = ""
    
    func getChilds(_ sec_id:Int64)  ->[String]{
        var res=Array<String>()
        let childs = self.store.loadChildSections(parent_id: sec_id)
        for c in childs {
            res.append(c.name+":"+c.color)
        }
        return res
    }
    
    @Environment(\.editMode) var mode
    @State var isEditMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.store.sections) { item in
                    NavigationLink(destination: SectionEditor(item,self.getChilds(item.id))
                        .environmentObject(self.store)){
                            HStack(spacing: 12.0) {
                                Image(systemName: item.type == NSection.types.LOCAL.VALUE() ?"tray.and.arrow.down" : "icloud.and.arrow.up" )
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .lineLimit(2)
                                        .lineSpacing(4)
                                        .font(.subheadline)
                                        .frame(height: 50.0)
                                    
                                    Text(item.getTypeAsString())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                }
                            }
                    }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all))
                }.onMove(perform: move)
                    .onDelete(perform: delete)
            }
            .environment(\.editMode, self.$isEditMode)
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        self.showingModal=false
                    }) {
                        CircleButton(icon: "xmark.square")
                    }
                    Spacer()
                    Image(systemName: "magnifyingglass").resizable().frame(width: 20, height: 20)
                    TextField("Find",text: $whatfind).background(Color(red: 211 / 255, green: 211 / 255, blue: 211 / 255)).frame(width:150)
                    
                },
                trailing: HStack {
                    Button(action: {
                        self.store.addSection()
                    }) {
                        CircleButton(icon: "plus.circle")
                    }
                    Button(action: {
                        if (self.$isEditMode.wrappedValue == EditMode.active ) {
                            self.$isEditMode.wrappedValue=EditMode.inactive
                        } else {
                            self.$isEditMode.wrappedValue=EditMode.active
                        }
                    }) {
                        if (self.$isEditMode.wrappedValue == EditMode.active ) {
                            CircleButton(icon: "checkmark.circle")
                        } else {
                            CircleButton(icon: "text.badge.minus")
                        }
                    }
                }
                
            )
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        self.store.sections.move(fromOffsets: source, toOffset: destination)
        var i=0
        for c in self.store.sections {
            c.prio=Double(i)
            store.saveSection(section: c)
            i+=1
        }
    }
    
    func delete(at : IndexSet) {
        self.store.deleteSection(index: at.first!)
    }
}

struct SectionsPanel_Previews: PreviewProvider {
    
    static var previews: some View {
        SectionsPanel(showingModal: .constant(true)).environmentObject(Storage(is_debug: true))
    }
}
