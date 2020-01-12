//
//  TableView.swift
//  Notes2
//
//  Created by Denis Mikaya on 12.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI


struct TableView: View {
    @State  var cell=[String](repeating: "", count: 100)
    @EnvironmentObject var store:Storage
    @State private var currHeight: CGFloat = 0
    var delete_handler:() -> Void
    var coordinators:[TextAreaCoordinator]
    var table:NoteTable
    var initvalues=[String](repeating: "", count: 100)
    
    @State var num_col:Int=2
    @State var num_row:Int=2
    @State private var showingAlert = false
    
    @Binding var refresh:Bool
    
    
    
    init(refr:Binding<Bool> ,crarray:[TextAreaCoordinator],initable:NoteTable,ondelete: @escaping () -> Void) {
        delete_handler=ondelete
        coordinators=crarray
        let initstr=initable.text
        let ic=initstr.components(separatedBy: ",")
        for i in 0..<ic.count {
            initvalues[i]=ic[i]
        }
        table=initable
        _refresh=refr 
    }
    
    
    func calc_table() ->Void {
        var sum:Double=0
        
        for index in 0..<table.ncol*table.nrow {
            if  coordinators[Int(index)].ptr == nil {
                continue
            }
            if coordinators[Int(index)].ptr?.text == "VSUM" {
                var c:Int=Int(index-table.ncol)
                while (c>=0) {
                    let sv:String=coordinators[Int(c)].ptr?.text ??  ""
                    sum+=Double(sv) ?? 0
                    c-=Int(table.ncol)
                }
                coordinators[Int(index)].ptr?.text=String(sum)
            } else  if coordinators[Int(index)].ptr?.text == "HSUM" {
                var c:Int=Int(index-1)
                while (c>=0) {
                    let sv:String=coordinators[Int(c)].ptr?.text ??  ""
                    sum+=Double(sv) ?? 0
                    if c % Int(table.ncol) == 0 {
                        break
                    }
                    c-=1
                }
                coordinators[Int(index)].ptr?.text=String(sum)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack{
                Stepper(
                    onIncrement: {
                        self.num_col+=1
                        self.table.ncol=UInt8(self.num_col)
                },
                    onDecrement: {
                        self.num_col-=1
                        self.table.ncol=UInt8(self.num_col)
                },
                    label: { Text("") }
                ).frame(width:130).padding(EdgeInsets(top: 0,leading: 0,bottom: 0,trailing: 20))
                Image(systemName:"xmark").resizable().frame(width:20,height:20)
                Stepper(
                    onIncrement: {
                        self.num_row+=1
                        self.table.nrow=UInt8(self.num_row)
                },
                    onDecrement: {
                        self.num_row-=1
                        self.table.nrow=UInt8(self.num_row)
                },
                    label: { Text("") }
                ).frame(width:130).padding(EdgeInsets(top: 0,leading: -20,bottom: 0,trailing: 20))
                CButton(label: "xmark.circle.fill") {
                    self.showingAlert = true
                    
                }.cornerRadius(5).frame(width:30,height:30)
            }.aspectRatio(contentMode: .fill)
                .onAppear(){
                    self.num_col=Int(self.table.ncol)
                    self.num_row=Int(self.table.nrow)
            }.scaleEffect(0.8)
            
            
            GridLayout(maxCols:   self.num_col ,
                       maxRow: self.num_row ,
                       coordinators: self.coordinators,
                       minCellWidth: 50, spacing: 0,
                       numItems: 100,alignment: .center) { index, coordinator in
                        TextArea(text_space: self.cell[index],
                                 initval: self.initvalues[index],
                                 text_cr:coordinator.setHandler(hh:{ txt in
                                    print("action changes")
                                    self.calc_table()
                                 }))
                            .border(Color.black,width: 0.4)
            }
        }
        .frame(height: CGFloat(80+self.num_row*30)).background(Color(DaoColorSheme.getDefHeadBackground()))
        .alert(isPresented:$showingAlert) {
            Alert(title: Text("Are you want to delete this table?"), message: Text("There is no undo"), primaryButton: .destructive(Text("Delete")) {
                self.delete_handler()
                }, secondaryButton: .cancel())
        }
    }
}



#if DEBUG
struct TableView_Previews: PreviewProvider {
    static var previews: some View {
        TableView(refr: .constant(true),crarray: [TextAreaCoordinator(nil, isTable: true),
                                                  TextAreaCoordinator(nil, isTable: true),
                                                  TextAreaCoordinator(nil, isTable: true),
                                                  TextAreaCoordinator(nil, isTable: true),
                                                  TextAreaCoordinator(nil, isTable: true)],
                  initable: NoteTable(ncol: 2,nrow: 2,text: "1,2,3,4,5,6,7,8,9"),ondelete: {})
            .environmentObject(Storage(is_debug: true))
    }
}
#endif
