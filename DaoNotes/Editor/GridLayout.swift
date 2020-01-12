//
//  GridStack.swift
//
//  Created by Peter Minarik on 07.07.19.
//  Copyright © 2019 Peter Minarik. All rights reserved.
//

import SwiftUI




public struct GridLayout<Content>: View where Content: View {
    let maxRow:Int
    let maxCols:Int
    let minCellWidth: Double
    let spacing: Double
    let numItems: Int
    let alignment: HorizontalAlignment
    let content: (Int, TextAreaCoordinator) -> Content
    let coordinators:[TextAreaCoordinator]

    init( maxCols: Int,   maxRow: Int,
          coordinators: [TextAreaCoordinator], minCellWidth: Double,
          spacing: Double,  numItems: Int,
          alignment: HorizontalAlignment = .center,  @ViewBuilder content: @escaping (Int, TextAreaCoordinator) -> Content
    ) {
        self.maxCols=maxCols
        self.maxRow=maxRow
        self.minCellWidth = minCellWidth
        self.spacing = spacing
        self.numItems = numItems
        self.alignment = alignment
        self.content = content
        self.coordinators=coordinators
    }
    
    var items: [Int] {
        Array(0..<numItems).map { $0 }
    }
    
    func getColumnCount(availableWidth:Double)  ->Int {
        var columnsThatFit = Int((availableWidth - self.spacing ) / (self.minCellWidth + self.spacing ))
        let rwidth=Int(self.minCellWidth+self.spacing ) * self.maxCols+Int(self.spacing)
        if rwidth <= Int(availableWidth) {
            columnsThatFit = self.maxCols
        }
       return max(1, columnsThatFit)
    }
    
    func getColumnWidth(availableWidth:Double) ->Double {
        let columnCount=getColumnCount(availableWidth: availableWidth)
        let remainingWidth = availableWidth -  Double(columnCount + 1) * self.spacing
        return remainingWidth / Double(columnCount)
    }
    
    func chunked(_ array:Array<Int>,into size: Int,maxrows: Int) -> [[Int]] {
        stride(from: 0, to: min(array.count,maxrows)*size, by: size).map{
            Array(array[$0 ..< Swift.min($0 + size,array.count)])
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Group {
                VStack(alignment: .center, spacing: CGFloat(self.spacing)) {
                    ForEach(self.chunked(self.items,into:
                        self.getColumnCount(availableWidth: Double(geometry.size.width)),maxrows: self.maxRow), id: \.self) { row in
                            HStack(spacing: CGFloat(self.spacing)) {
                                ForEach(row,  id: \.self) { item in
                                    self.content(item,self.coordinators[item])
                                        .frame(width: CGFloat(self.getColumnWidth(availableWidth: Double(geometry.size.width))),height:30)
                                }
                            }.padding(.horizontal,CGFloat(self.spacing))
                                .padding(EdgeInsets(top: 0,leading: 5,bottom:0,trailing: 0))
                    }
                }
                Spacer()
            }
        }
    }
}

