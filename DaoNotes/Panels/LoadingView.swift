//
//  LoadingView.swift
//  Notes2
//
//  Created by Denis Mikaya on 26.09.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isGoing: Bool
    func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: UIViewRepresentableContext<ActivityIndicator>) {
        isGoing ? uiView.startAnimating() : uiView.stopAnimating()
    }
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: .large)
    }
}

struct AwaitingView<Content>: View where Content: View {
    
    @Binding var isShow: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShow)
                    .blur(radius: self.isShow ? 5 : 0)
                    HStack {
                        ActivityIndicator(isGoing: .constant(true))
                    }
                    .foregroundColor(Color.primary)
                    .cornerRadius(50)
                    .opacity(self.isShow ? 1 : 0)
                    .frame(width: 100,
                       height: 100)
            }
        }
    }
    
}

struct AwaitingView_Previews: PreviewProvider {
    static var previews: some View {
        AwaitingView(isShow: .constant(true)) {
            Text("A")
        }
    }
}
