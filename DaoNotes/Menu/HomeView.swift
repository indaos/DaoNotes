//
//  HomeView.swift
//  Notes2
//
//  Created by Denis Mikaya on 12.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @State var show = false
    @State var disableMenu = false
    @State var viewState = CGSize.zero
    
    var body: some View {
        ZStack {
            NoteList(hh: { b in
            }).disabled(show)
            MenuButton(show: $show).position(x: UIScreen.main.bounds.width-15, y: 20)
                .animation(.spring()).disabled(disableMenu)
            LeftMenu(show: $show)
        }
    }
}


struct MenuButton: View {
    @Binding var show: Bool
    @EnvironmentObject var store:Storage
    
    var body: some View {
        return ZStack(alignment: .topLeading) {
            Button(action: {
                if self.store.isMenuActive() {
                    self.show.toggle()
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "list.dash")
                        .foregroundColor(.white)
                }
                .padding(.trailing, 18)
                .frame(width: 60, height: 40)
                .background(LinearGradient(gradient:  Gradient(colors: [Color.gray,Color(store.getMainColor())]), startPoint: .top, endPoint: .bottom))
            }.cornerRadius(30)
            Spacer()
        }
    }
}



#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(Storage(is_debug: true))
    }
}
#endif
