//
//  ImagePicker.swift
//  Notes2
//
//  Created by Denis Mikaya on 03.09.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI

class ImageZoomView: UIScrollView, UIScrollViewDelegate {
    
    var imageView: UIImageView!
    var gestureRecognizer: UITapGestureRecognizer!
    var initWidth:CGFloat?
    var initHeight:CGFloat?
    
    convenience init(image: UIImage?) {
        self.init(frame: ImageZoomView.setupImagePosition(width: image!.size.width,height: image!.size.height))
        
        var imageToUse: UIImage
        
        if let image = image {
            imageToUse = image
        } else if let url = Bundle.main.url(forResource: "image", withExtension: "jpeg"),
            let data = try? Data(contentsOf: url),
            let fileImage = UIImage(data: data) {
            imageToUse = fileImage
        } else {
            fatalError("No image was passed in and failed to find an image at the path.")
        }
        initWidth=image?.size.width
        initHeight=image?.size.height
        imageView = UIImageView(image: imageToUse)
        imageView.contentMode = .scaleAspectFill
        initAdjustSize()
        addSubview(imageView)
        setupScrollView(image: imageToUse)
        setupGestureRecognizer()
    }
    
    
    static func setupImagePosition( width:CGFloat,height:CGFloat) ->CGRect{
        var new_width=width
        var new_height=height
        var starty:CGFloat=0.0
        
        if new_width > UIScreen.main.bounds.width  {
            let r=new_width/UIScreen.main.bounds.width
            new_width=UIScreen.main.bounds.width
            new_height=new_height/r
        }
        if new_height > UIScreen.main.bounds.height  {
            new_height=UIScreen.main.bounds.height
        }
        if new_height < UIScreen.main.bounds.height {
            starty=(UIScreen.main.bounds.height-new_height)/2
        }
        return CGRect(x: 0, y: starty, width: new_width, height: new_height)
    }

    public func initAdjustSize()  {
        self.frame=ImageZoomView.setupImagePosition(width:initWidth!,height: initHeight!)
        imageView.frame=self.frame
    }

    func setupScrollView(image: UIImage) {
        delegate = self
        
        minimumZoomScale = 1.0
        maximumZoomScale = 2.0
    }
    
    func setupGestureRecognizer() {
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        gestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(gestureRecognizer)
    }

    @IBAction func handleDoubleTap() {
        if zoomScale == 1 {
            zoom(to: zoomRectForScale(maximumZoomScale, center: gestureRecognizer.location(in: gestureRecognizer.view)), animated: true)
        } else {
            setZoomScale(1, animated: true)
        }
    }

    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    

    
    public func adjustFrameToCenter() {
        
        var frameToCenter = imageView.frame
        print("\(frameToCenter.size.width) \(UIScreen.main.bounds.width)")
        
        if frameToCenter.size.width <  UIScreen.main.bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        print("\(frameToCenter.size.height) \(UIScreen.main.bounds.height)")
        if frameToCenter.size.height <  UIScreen.main.bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 10
        }
        
        imageView.frame = frameToCenter
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
           adjustFrameToCenter()
       }
}


struct ImageViewer: UIViewRepresentable {
     var image: UIImage?

     func makeUIView(context: UIViewRepresentableContext<ImageViewer>) -> UIScrollView {
        let imageView = ImageZoomView(image: image)
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }
    
    func isLandscape() ->Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, windowScene.activationState == .foregroundActive, let window = windowScene.windows.first else { return  false}
        switch windowScene.interfaceOrientation {
        case .unknown:
            return false
        case .portrait:
            return false
        case .portraitUpsideDown:
            return false
        case .landscapeLeft:
            return true
        case .landscapeRight:
            return true
        @unknown default:
            return false
        }
    }

    func updateUIView(_ uiView: UIScrollView, context: UIViewRepresentableContext<ImageViewer>) {
    }
    
    
}


struct ImagePanel: View {

    var image: UIImage? = nil
    @State var width:CGFloat=150
    @State var height:CGFloat=150
    var delete_handler:() -> Void
    var changesize_handler:(_ w:CGFloat,_ h:CGFloat) -> Void
    @State var islandscape:Bool=false
    @State var expandx=true
    @State var expandy=true

    func showModal() {
         let window = UIApplication.shared.windows.first
        window?.rootViewController?.present(UIHostingController(rootView:ImageViewer(image: self.image).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)), animated: true)
        
    }
    
    func changeSize(_ horizontal:Bool=true) {
        if horizontal {
            let delta=(UIScreen.main.bounds.width-width)/4
            if width < UIScreen.main.bounds.width-50 {
                if width < 80 {
                    expandx=true
                }
            } else {
                expandx=false
            }
            width+=expandx ? delta : -delta
            if width < 50 {
                width=50
                expandx=true
            }
        } else {
            let delta=(UIScreen.main.bounds.height-height)/4
            if height < UIScreen.main.bounds.height-50 {
                if height < 50 {
                    expandy=true
                }
            } else {
                expandy=false
            }
            height+=expandy ? delta : -delta
            if height < 50 {
                height = 50
                expandy=true
            }
        }
        
    }
    
    var body: some View {
        VStack {
            HStack {
                CButton(label: "arrow.left.and.right") {
                        self.changeSize()
                    self.changesize_handler(self.width,self.height)
                }.cornerRadius(5).scaleEffect(0.8)
                
                CButton(label: "arrow.up.and.down") {
                        self.changeSize(false)
                    self.changesize_handler(self.width,self.height)
                }.cornerRadius(5).scaleEffect(0.8)
                
                CButton(label: "xmark.circle.fill") {
                    self.delete_handler()
                }.cornerRadius(5).scaleEffect(0.8)
            }
            if image != nil {
                Image(uiImage: image!).resizable().frame(width: self.width, height: self.height).onTapGesture {
                    self.showModal()
                }
            }
        }.frame(width: self.width, height: self.height+50)
            .background(Color(DaoColorSheme.getDefHeadBackground()))
    }
}


struct ImagePicker: UIViewControllerRepresentable {

    @Binding var isShown: Bool
    @Binding var image: UIImage?
    var handler: (()->Void)?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        @Binding var isShown: Bool
        @Binding var image: UIImage?
        var handler: (()->Void)?

        init(isShown: Binding<Bool>, image: Binding<UIImage?>,hh:(()->Void)?) {
            _isShown = isShown
            _image = image
            handler = hh
        }
        

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            image = uiImage 
            isShown = false
            if handler != nil {
                handler!()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isShown = false
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, image: $image,hh: handler)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

}


struct ImagePicker_Panel: View {
    
    @State var showImagePicker: Bool = false
    @State var image: UIImage? = nil
    
    var body: some View {
        ZStack {
            VStack {
                Button(action: {
                    withAnimation {
                        self.showImagePicker.toggle()
                    }
                }) {
                    Text("Show image picker")
                }
                ImagePanel(image: self.image,delete_handler: {} ,changesize_handler: {_,_ in } )
                
            }
            if (showImagePicker) {
                ImagePicker(isShown: $showImagePicker, image: $image,handler: {
                    print("done")
                })
            }
        }
    }
    
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker_Panel()
    }
}
