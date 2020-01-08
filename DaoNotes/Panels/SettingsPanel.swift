//
//  SettingsPanel.swift
//  Notes2
//
//  Created by Denis Mikaya on 12.09.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI
import Foundation

struct SettingsPanel: View {
    
    @EnvironmentObject var store:Storage
    
    @Binding var showingModal:Bool
    @State var namePrompt:String="Color icons:"
    @State var id:Int64 = -1
    @State var name = ""
    @State var sliderValue:Double = 14.0
    @State  var selectedMainColor: Int = 6
    @State var showingAlert:Bool = false
    @State var values:[Bool] = Array<Bool>(repeating: true, count: 10)

    var minimumValue = 12.0
    var maximumvalue = 24.0
    var settings:[String:Any]
    
    init(showingModal:Binding<Bool>,settings:[String:Any]) {
          self._showingModal=showingModal
          self.settings=settings
            if settings.count > 0  {
                self._selectedMainColor = State<Int>(initialValue: self.settings["color"] as! Int)
            }
    }
    
    func getSliderValue() ->String {
        return String(format:"%.1f",Double(sliderValue))
    }
    
    
    var body: some View {
        NavigationView {
           Form {
                Section(header: Text("Sharing User ID")) {
                    TextField("Name: ", text: $name)
                }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all))
                 Section(header: Text("Default font size and color")) {
                    Slider(value: $sliderValue, in: minimumValue...maximumvalue,step: 2.0)
                    Text("Size: "+self.getSliderValue())
                    
                    Picker(selection: $selectedMainColor, label: Text(self.namePrompt)) {
                        ForEach(0 ..< DaoColorSheme.colorsNames.count) {
                                 Text(DaoColorSheme.colorsNames[$0]).foregroundColor(Color(DaoColorSheme.getColor(DaoColorSheme.colorsNames[$0])))
                             }
                    }
                    
                 }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all))
                Section(header: Text("Features")) {
                    List{
                        HStack {
                            Image(systemName: self.values[0] ? "checkmark.circle" : "circle").onTapGesture {
                                self.values[0].toggle()
                            }.frame(width:50,height:50)
                            Text("Math mode")
                        }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                                Image(systemName: self.values[1] ? "checkmark.circle" : "circle").onTapGesture {
                                    self.values[1].toggle()
                                }.frame(width:50,height:50)
                            Text("Table")

                            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                                Image(systemName: self.values[2] ? "checkmark.circle" : "circle").onTapGesture {
                                    self.values[2].toggle()
                                }.frame(width:50,height:50)
                            Text("Translator table")

                            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                                Image(systemName: self.values[3] ? "checkmark.circle" : "circle").onTapGesture {
                                    self.values[3].toggle()
                                }.frame(width:50,height:50)
                            Text("Photo")

                            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                                Image(systemName: self.values[4] ? "checkmark.circle" : "circle").onTapGesture {
                                    self.values[4].toggle()
                                }.frame(width:50,height:50)
                            Text("Photo with OCR")

                        }.listRowBackground(Color(DaoColorSheme.getDefBackground()).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                                Image(systemName: self.values[5] ? "checkmark.circle" : "circle").onTapGesture {
                                    self.values[5].toggle()
                                }.frame(width:50,height:50)
                            Text("Share")

                            }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                        HStack {
                           Image(systemName: self.values[6] ? "checkmark.circle" : "circle").onTapGesture {
                                self.values[6].toggle()
                            }.frame(width:50,height:50)
                            Text("Lock")

                        }.listRowBackground(Color(DaoColorSheme.getDefBackground() ).edgesIgnoringSafeArea(.all)).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 40))
                    }
                    
                }
             }
           .background(Color(DaoColorSheme.getDefBackground()))
            .navigationBarItems(
                    leading:
                        Button(action: {
                                var sv=""
                                for b in self.values {
                                    if sv.count>0 {
                                        sv+=","
                                    }
                                    sv+=String(b)
                                }
                            if self.store.cloud?.cStatus != .available {
                                self.showingModal.toggle()
                                self.store.saveSettings(["id":self.id,"name":self.name,
                                                     "fontsize":Int(self.sliderValue),
                                                     "values":sv,"color":self.selectedMainColor])
                            } else {
                                self.store.checkUser(name:self.name,handler: { code in
                                    if  code == 3 {
                                            self.store.addUser(name:self.name,handler: {  added  in
                                                if added {
                                                    self.showingModal.toggle()
                                                    self.store.saveSettings(["id":self.id,"name":self.name,
                                                                         "fontsize":Int(self.sliderValue),
                                                                         "values":sv,"color":self.selectedMainColor])
                                                }
                                            })
                                        } else if  code == 1 {
                                            self.showingModal.toggle()
                                            self.store.saveSettings(["id":self.id,"name":self.name,
                                                                 "fontsize":Int(self.sliderValue),
                                                                 "values":sv,"color":self.selectedMainColor])
                                        } else if  code == 2 {
                                               self.showingAlert.toggle()
                                        }
                                    })
                            }
                        }) {
                            CircleButton(icon: "xmark.square")
                        }
            ).onAppear(){
                if self.settings.count > 0 {
                    self.id=self.settings["id"] as! Int64
                    self.name=self.settings["name"] as! String
                    self.sliderValue=Double(self.settings["fontsize"] as! Int)
                    let vs:String=self.settings["values"] as! String
                    let varr=vs.components(separatedBy: ",")
                    var i = 0
                    for v in varr {
                        let b=Bool(v)
                        self.values[i]=b ?? false
                        i+=1
                    }
               }
            }
        }.alert(isPresented:self.$showingAlert) {
            return Alert(title: Text("Username already exits!"), message: Text("Please choose another") )
        }

    }

}

struct SettingsPanel_Previews: PreviewProvider {

    static var previews: some View {
        SettingsPanel(showingModal: .constant(true),settings: [:]).environmentObject(Storage(is_debug: true))
    }
}
