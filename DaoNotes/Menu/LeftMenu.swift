//
//  LeftMenu.swift
//  Notes2
//
//  Created by Denis Mikaya on 29.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI


let menuData = [
   Menu(title: "Sections", icon: "list.bullet.below.rectangle"),
   Menu(title: "Settings", icon: "gear"),
]


struct LeftMenu: View {
    @EnvironmentObject var store:Storage
    
    var menu = menuData
    @Binding var show: Bool
    @State var showModal = false
    @State var sectionMenu = 0
    @State var showSections = false
    @State var showSettings = false
    @State var showiCloud = false
    @State var settings:[String:Any]?
    
    var body: some View {
        return HStack {
            VStack {
                
                ForEach(menu) { item in
                    if item.title == "Sections" {
                        Button(action: {
                            self.sectionMenu = 0
                            self.showModal.toggle() } ) {
                                MenuRow(image: item.icon, text: item.title)
                        }
                    }  else if item.title == "Settings" {
                        Button(action: {
                            self.sectionMenu = 1
                            self.showModal.toggle()
                            self.settings=self.store.loadSettings()
                        }
                        ) {
                            MenuRow(image: item.icon, text: item.title)
                        }
                    } else if item.title == "iCloud" {
                        Button(action: {
                            self.sectionMenu = 2
                            self.showModal.toggle() } ) {
                                MenuRow(image: item.icon, text: item.title)
                        }
                    } else {
                        MenuRow(image: item.icon, text: item.title)
                    }
                }
                Divider()
                MenuRow(image: "xmark.square",text: "Close")
                Spacer()
            }
            .padding(.top, 20)
            .padding(30)
            .frame(minWidth: 0, maxWidth: 360,minHeight: 0,maxHeight: 300)
            .background(Color(DaoColorSheme.getDefBackground() ))
            .cornerRadius(30)
            .padding(.trailing, 60)
            .shadow(radius: 20)
            .rotation3DEffect(Angle(degrees: show ? 0 : 60), axis: (x: 0, y: -100.0, z: 0))
            .animation(.default)
            .offset(x: show ? UIScreen.main.bounds.width-260 : 360+UIScreen.main.bounds.width,y: -UIScreen.main.bounds.height/2+200)
            .onTapGesture(count:1) {
                self.show.toggle()
                self.store.reloadSections()
            }
            Spacer()
                .sheet(isPresented: self.$showModal) {
                    if self.sectionMenu == 0 {
                        SectionsPanel(showingModal: self.$showModal).environmentObject(self.store)
                    } else
                        if self.sectionMenu == 1 {
                            SettingsPanel(showingModal: self.$showModal,settings: self.settings ?? [:]).environmentObject(self.store)
                        } else
                            if self.sectionMenu == 2 {
                                iCloudPanel(showingModal: self.$showModal).environmentObject(self.store)
                    }
            }
        }
        .padding(.top, 40)
    }
}



struct MenuRow: View {
    
    var image = "creditcard"
    var text = "My Account"
    
    var body: some View {
        return HStack(spacing: 25) {
            Image(systemName: image)
                .imageScale(.medium)
                .foregroundColor(Color("icons"))
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}


struct Menu: Identifiable {
    var id = UUID()
    var title: String
    var icon: String
}



struct LeftMenu_Previews: PreviewProvider {
    
    static var previews: some View {
        Text("")
    }
}
