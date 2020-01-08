//
//  iCloudPanel.swift
//  Notes2
//
//  Created by Denis Mikaya on 12.09.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI
import Foundation

struct iCloudPanel: View {
    
    @EnvironmentObject var store:Storage
    
    @Binding var showingModal:Bool
    @State var id:Int64 = -1
    @State var name = ""
    @State var nadd = false
    @State var nmod = false
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Sharing User ID")) {
                    TextField("Name: ", text: $name)
                }
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $nadd) {
                        Text("Add a new ")
                    }
                    Toggle(isOn: $nmod) {
                        Text("Modifications")
                    }
                }.onAppear(){
                    if let res=self.store.loadSettings() {
                        self.id=res["id"] as! Int64
                        self.name=res["name"] as! String
                    }
                }
            }
            .navigationBarItems(
                leading:
                Button(action: {
                    self.showingModal.toggle()
                    if !self.showingModal {
                        self.store.saveSettings(["name":self.name])
                    }
                }) {
                    CircleButton(icon: "xmark.square")
                }
            )
        }
    }
    
    func delete(at : IndexSet) {
        self.store.deleteSection(index: at.first!)
    }
}

struct iCloudPanel_Previews: PreviewProvider {
    
    static var previews: some View {
        iCloudPanel(showingModal: .constant(true)).environmentObject(Storage(is_debug: true))
    }
}
