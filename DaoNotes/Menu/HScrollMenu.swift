//
//  HScrollMenu.swift
//  Notes2
//
//  Created by Denis Mikaya on 10.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI


struct HScrollMenu: View {
    @EnvironmentObject var store:Storage
    @State  var prevPosition: CGFloat = 0
    @State  var scrollOffset: CGFloat = 100
    @Binding var refreshLoading:Bool
    
    var body: some View {
        ZStack{
            HStack{
                ForEach(self.store.sections) { sect in
                    ContentCardView(section: sect,scrollOffset: self.$scrollOffset, prevScrollOffset: self.$prevPosition,refreshLoading: self.$refreshLoading)
                }
            }.offset(x: self.scrollOffset,y: 0).animation(.easeOut)
            
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
        }
    }
}


struct MenuItemView: View {
    @EnvironmentObject var store:Storage
    var id:Int64
    
    func getImageName() ->String {
        let n=store.getSection(id)!.isnew
        switch n {
        case 1..<10 :
            return "0"+String(n)+".circle.fill"
        case 10..<51:
            return String(n)+".circle.fill"
        default:
            return "50.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0.0) {
            if store.getSection(id)!.type == NSection.types.CLOUD.VALUE() {
                    Image(systemName: "icloud.and.arrow.up").resizable().frame(width: 40, height: 40)
           } else if  store.getSection(id)!.type==NSection.types.CHAIN.VALUE() {
                HStack {
                  Image(systemName: "link.icloud").resizable().frame(width: 50, height: 40)
                    if  store.getSection(id)!.isnew > 0 {
                        Image(systemName: getImageName()).resizable().frame(width: 35, height: 35).foregroundColor(Color.red)
                            .blendMode(.multiply)
                    }
                }
           } else if  store.getSection(id)!.type==NSection.types.LOCAL.VALUE(){
              Image(systemName: "tray.and.arrow.down").resizable().frame(width: 40, height: 40)
           }else {
              Image(systemName: "tray.and.arrow.down").resizable().frame(width: 40, height: 40)
           }
            Text(store.getSection(id)!.name).frame(width: 200, height: 40,alignment: .center)
           .font(.subheadline)
           .multilineTextAlignment(.center)

       }
       .padding(.all)
       .background(Color("background"))
       .frame(width: 200, height: 100,alignment: .center)
    }
    
}


struct  MenuView: View {
    @EnvironmentObject var store:Storage
    @State var show = false
    @State var viewState = CGSize.zero
    var ids:Int64
    
    var body: some View {
        ZStack {
            CardView()
                .background(isSelected() ?  Color("icons"): Color("gradient2"))
                .cornerRadius(15)
                .offset(x: 0, y: isSelected() ? -12 :0)
                .scaleEffect(0.8)
                .blendMode(.hardLight)
                .animation(.easeInOut(duration: 0.5))
                .offset(x: viewState.width, y: viewState.height)
                .frame( height: 40)
            CardView()
                .background(isSelected() ?  Color("icons") : Color("icons"))
                .cornerRadius(15)
                .offset(x: 0, y: isSelected() ? -5 : 0)
                .scaleEffect(0.8)
                .blendMode(.hardLight)
                .animation(.easeInOut(duration: 0.2))
                .offset(x: viewState.width, y: viewState.height)
                .frame( height: 40)
            MenuItemView(id: ids)
                .cornerRadius(15)
                .offset(x: 0, y: isSelected() ? 20 : 0)
                .scaleEffect(isSelected() ? 0.8: 0.7)
                .rotationEffect(Angle(degrees: isSelected() ? 0 : 0))
                .animation(.easeInOut(duration: 0.2))
                .onTapGesture(count:1) {
                    self.store.selectedSection=self.ids
                    self.store.reloadNotes(section_id: self.store.selectedSection)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.viewState = value.translation
                        self.store.selectedSection=self.ids
                        self.store.reloadNotes(section_id: self.store.selectedSection)
                }
                .onEnded { _ in
                    self.viewState = CGSize.zero
                    self.store.selectedSection=self.ids
                    self.store.reloadNotes(section_id: self.store.selectedSection)
                }
            )
        }
    }
    
    func isSelected() -> Bool {
        return  self.store.selectedSection == self.ids
    }
}


struct CardView: View {
   var body: some View {
      return VStack {
         Text("")
      }
      .frame(width: 130, height: 40)
   }
}



#if DEBUG
struct HScrollMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Text("AAAAAA").offset(x:0,y:-100)
            HScrollMenu(refreshLoading: .constant(false)).environmentObject(Storage(is_debug: true))
        }
    }
}
#endif
