//
//  ContentView.swift
//  Notes2
//
//  Created by Denis Mikaya on 06.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI


public struct Parallelogram: Shape {

    public var topLeftAngle: Angle

    public init(topLeftAngle: Angle) {
        self.topLeftAngle = topLeftAngle
    }
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let offset = abs(CGFloat(tan(topLeftAngle.radians - .pi / 2)) * rect.height)

        if topLeftAngle.degrees <= 90 {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width - offset, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: offset, y: rect.height))
        } else {
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width - offset, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        path.closeSubpath()
        return path
    }

}

struct MenuCardView : View {
    var section_id:Int64 = 1
    var title:String
    var main_color: Color
    var own_color: Color
    var type:Int
    var isnew:Int
    @State var selected:Bool=false
    
    var body: some View {
        ZStack {
                Parallelogram(topLeftAngle: Angle(degrees: 92))
                .fill(LinearGradient(gradient:  Gradient(colors: [  own_color, main_color]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(10)
                .frame(width: 170, height: 90).shadow(radius: 0.8)
               Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(width: 140, height: 40,alignment: .center)
            if self.type == NSection.types.LOCAL.VALUE() {
                Image(systemName: "tray.and.arrow.down")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .offset(x: 50,y: -27)
                    .foregroundColor(Color.white)
            }else if self.type == NSection.types.CLOUD.VALUE(){
                Image(systemName: "icloud.and.arrow.up")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .offset(x: 50,y: -25)
                    .foregroundColor(Color.white)
            }else if self.type == NSection.types.CHAIN.VALUE() {
                Image(systemName: "link.icloud")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .offset(x: 50,y: -25)
                    .foregroundColor(Color.white)
            }
            if self.isnew > 0 {
                Image(systemName: getImageName())
                .resizable()
                .frame(width: 35, height: 35)
                .offset(x: -50,y: -35)
                .foregroundColor(Color.white)
                .blendMode(.multiply)
            }
        }.shadow(radius: 6)
    }
    
    func getImageName() ->String {
        var n=self.isnew
        if n > 50 {
           n=50
        }
        if n>0 && n<10 {
            return "0"+String(n)+".circle.fill"
        } else if  n >= 10 {
            return String(n)+".circle.fill"
        }
        return ""
    }
}

struct  MenuCardItem : Identifiable {
    var id:Int
    var title:String
    var sectionId:Int64
    var sectionType:Int
    var offset:Int
    var offsetExpanded:Int
    var color:Color
    let type:Int
    let isnew:Int
}



struct ContentCardView : View {
    @EnvironmentObject var store:Storage
    
    var  section:NSection
    @State var hasChildren: Bool?=false
    @State var expanded: Bool?=false
    @Binding  var scrollOffset: CGFloat
    @Binding  var prevScrollOffset: CGFloat
    @Binding  var refreshLoading: Bool


    func getMenuList1() -> [MenuCardItem] {
        let res = [MenuCardItem(id:0,title:  "Local ",sectionId: 2,sectionType: 2,
                                offset: -30,offsetExpanded: -240,color:getColor("green"),
                                type: 0, isnew: 0),
                   MenuCardItem(id:2,title: "iCloud ",sectionId: 3,sectionType: 0,
                                offset: -20,offsetExpanded: -160,
                                color:getColor("black"),
                                type: 0, isnew: 0),
                   MenuCardItem(id:3,title: "Shared ",sectionId: 4,
                                sectionType: 0,offset: -10,
                                offsetExpanded: -80,color:getColor("blue"),
                                type: 0, isnew: 0),
                   MenuCardItem(id:4,title: "Misc my notes here and there",sectionId: 1,
                                sectionType: 0,offset: 0,
                                offsetExpanded: 0,color:getColor(""),
                                type: 0, isnew: 0)]
        return res
    }
    
    func getColor(_ name:String) ->Color {
        return Color(DaoColorSheme.getColor((name.count==0) ? "black" : name))
    }
    
    
    func getOffset(_ item:MenuCardItem) -> CGSize {
        return CGSize(width: 0,height: (self.isSelected() && self.expanded! ) ? item.offsetExpanded : item.offset)
    }
    
    func getMenuList( ) -> [MenuCardItem] {
        var menu=Array<MenuCardItem>()
        let childs = self.store.loadChildSections(parent_id: section.id)
         var counter=0
         var o1:Int = -10
         var o2:Int = -80
         for c in childs {
            menu.append(MenuCardItem(id: counter,title: c.name,sectionId: c.id,sectionType: c.type,offset: o1,offsetExpanded: o2,color: getColor(c.color), type: c.type, isnew: c.isnew))
             o1-=10
             o2-=80
            counter+=1
         }
        if counter > 0 {
            self.hasChildren=true
        }
         menu.reverse()
        menu.append(MenuCardItem(id: counter,title:section.name,sectionId: section.id,sectionType: 0,offset: 0,offsetExpanded: 0,color: getColor(section.color), type: section.type, isnew: section.isnew))
         return menu
     }

    func isSelected() -> Bool {
          return  self.store.selectedSection == self.section.id
    }
    
    func isSelected2() -> Bool {
        return  hasChildren! && self.store.selectedSection == self.section.id
     }

    var body: some View {
        ZStack {
            ForEach(self.getMenuList()) { item in 
                if item.offset == 0 {
                    MenuCardView(section_id: item.sectionId, title: item.title,main_color: Color(self.store.getMainColor()), own_color: item.color,type: item.type,isnew: item.isnew,selected: self.isSelected())
                        .scaleEffect(self.isSelected() ? 1.1 : 1)
                            .gesture(
                                DragGesture(coordinateSpace: .global).onChanged { value in
                                    self.scrollOffset = (self.prevScrollOffset + value.translation.width)
                                }.onEnded { value in
                                    self.scrollOffset = (self.prevScrollOffset + value.translation.width)
                                    self.prevScrollOffset=self.scrollOffset
                                }.exclusively(before: TapGesture().onEnded({
                                    self.store.setRefreshList(refresh: self.$refreshLoading)
                                    self.store.selectedSection=item.sectionId
                                    self.store.reloadNotes(section_id: self.store.selectedSection)
                                    self.expanded!.toggle()  
                                }))
                    ).animation(.spring())
                } else {
                    MenuCardView(section_id: item.sectionId,title: item.title,main_color: item.color, own_color: item.color,type: item.type,isnew: item.isnew)
                        .scaleEffect(self.isSelected() ? 1 : 0.90)
                        .offset(self.getOffset(item))
                        .onTapGesture {
                            self.store.selectedSection=item.sectionId
                            self.store.reloadNotes(section_id: self.store.selectedSection)
                            self.expanded!.toggle()
                        }
                }
            }
           .frame(height:self.isSelected2() ? 600 : 100)
        }
        .animation(.spring() )
    }
    
  
}



#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentCardView(section: NSection(1, name: "Test Section", type: 0),scrollOffset: .constant(0), prevScrollOffset: .constant(0), refreshLoading: .constant(false)).environmentObject(Storage(is_debug: true))
    }
}
#endif
