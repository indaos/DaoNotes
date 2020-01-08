//
//  ColorSheme.swift
//  DaoNotes
//
//  Created by Denis Mikaya on 26.12.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI
import Combine

class DaoColorSheme {
    
    static let bodyBackground = UIColor( displayP3Red: 249/255, green: 249/255, blue:  242/255,alpha: 1.0 )
    static let headerBackground = UIColor( displayP3Red: 242/255, green: 242/255, blue:  239/255,alpha: 1.0 )
    static let colorsNames = ["black", "darkGray", "lightGray","gray","red","green","blue","cyan","yellow","magenta","orange","purple","brown"]
    
    static func   getDefBackground() -> UIColor {
        return bodyBackground;
    }
    
    static func   getDefHeadBackground() -> UIColor {
        return headerBackground;
    }
       
    static func getColor(_ name:String) -> UIColor {
        var color_name=name
        if name.contains(":") {
            color_name=name.components(separatedBy:":")[1]
        }
        switch color_name {
        case  "black": return      UIColor.black
        case  "darkGray": return  UIColor.darkGray
        case  "lightGray": return  UIColor.lightGray
        case  "white": return   UIColor( displayP3Red: 218/255, green: 227/255, blue:  221/255,alpha: 1.0 )
        case  "gray": return    UIColor.gray
        case  "red": return     UIColor( displayP3Red: 161/255, green: 68/255, blue:  2/255,alpha: 1.0 )
        case  "green": return   UIColor( displayP3Red: 25/255, green: 94/255, blue:  50/255,alpha: 1.0 )
        case  "blue": return    UIColor( displayP3Red: 20/255, green: 36/255, blue:  105/255,alpha: 1.0 )
        case  "cyan": return    UIColor( displayP3Red: 18/255, green: 136/255, blue:  119/255,alpha: 1.0 )
        case  "yellow": return  UIColor( displayP3Red: 180/255, green: 189/255, blue:  100/255,alpha: 1.0 )
        case  "magenta": return UIColor( displayP3Red: 201/255, green: 109/255, blue:  160/255,alpha: 1.0 )
        case  "orange": return  UIColor( displayP3Red: 197/255, green: 204/255, blue:  120/255,alpha: 1.0 )
        case  "purple": return  UIColor( displayP3Red: 209/255, green: 105/255, blue:  113/255,alpha: 1.0 )
        case  "brown": return   UIColor( displayP3Red: 140/255, green: 113/255, blue:  53/255,alpha: 1.0 )
        default: return UIColor.black
        }
    }
}
