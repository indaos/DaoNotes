//
//  Note.swift
//  Notes2
//
//  Created by Denis Mikaya on 25.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import SwiftUI
import Combine
import SQLite
import VisionKit
import Vision

enum ObjectTags : UInt8 {
    case text = 0x1
    case image = 0x2
    case table = 0x3
    case hidden = 0x4
}

public class NoteObject :  Identifiable {
    public var id:Int=0
    private var buffer:[UInt8]?
    
    init() {
    }
    func getId() ->Int {
        return id
    }
    func toBytes() -> [UInt8]? {
        return buffer
    }
    
    static func bytesToInteger<Type>(_ from: [UInt8]) -> Type where Type: BinaryInteger {
        return from.withUnsafeBufferPointer({
            UnsafeRawPointer($0.baseAddress!).load(as: Type.self)
        })
    }
    
    func toByteArray<Type>(_ value: Type) -> [UInt8] {
        var unsafeValue = value
        
        return withUnsafePointer(to: &unsafeValue) {
            return $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Type>.size, { pointer in
                return [UInt8](UnsafeBufferPointer(start: pointer, count: MemoryLayout<Type>.size))
            })
        }
    }
    
    static func readInt(_ bytes:  [UInt8], offset: inout Int) -> Int? {
        guard bytes.count >= offset + MemoryLayout<Int>.size else { return nil }
        
        let bytesForInt: [UInt8] = Array(bytes[offset..<offset + MemoryLayout<Int>.size])
        let value: Int = bytesToInteger(bytesForInt)
        
        offset += MemoryLayout<Int>.size
        
        return value
    }
    
    static func readArray(_ bytes:  [UInt8], offset: inout Int, capacity: Int, endOffset: Int) -> [UInt8]? {
        
        if offset < endOffset {
            let arr=bytes[offset...(offset+capacity-1)]
            offset += arr.count
            return Array(arr)
        }
        return nil
    }
    
    func debugString() {
        print("element:\(type(of: self))")
        if self is NoteText {
            print(":"+(self as! NoteText).text)
        } else if self is NoteImage {
            print(":\((self as! NoteImage).image!.size)")
        } else if self is NoteTable {
            let table=(self as! NoteTable)
            print(":\(table.text),\(table.nrow),\(table.ncol)")
        }
    }
}


public class NoteHiddenText : NoteObject {
    
    var text:String=""
    
    init( text:String) {
        self.text=text
    }
    
    init(newid: Int, text:String) {
        super.init()
        id=newid
        self.text=text
    }
    
    init (pk:Int,bytes:[UInt8]) {
        super.init()
        id=pk
        text=String(data: Data(bytes),encoding: .utf8)!
    }
    
    override func toBytes() -> [UInt8]? {
        var array = Array(text.utf8)
        array.insert(contentsOf: toByteArray(array.count), at: 0)
        array.insert(contentsOf: toByteArray(ObjectTags.hidden.rawValue), at: 0)
        return array
    }
    
}


public class NoteText : NoteObject {
    
    var text:String=""
    var desc:String=""
    
    init( text:String) {
        self.text=text
    }
    
    init(newid: Int, text:String) {
        super.init()
        id=newid
        self.text=text
        self.desc=text
    }
    
    init (pk:Int,bytes:[UInt8],bytes2:[UInt8]) {
        super.init()
        id=pk
        text=String(data: Data(bytes),encoding: .utf8)!
        if bytes2.count > 0 {
            desc=String(data: Data(bytes2),encoding: .utf8)!
        }
    }
    
    override func toBytes() -> [UInt8]? {
        var array = Array(text.utf8)
        array.insert(contentsOf: toByteArray(array.count), at: 0)
        array.insert(contentsOf: toByteArray(ObjectTags.text.rawValue), at: 0)
        
        let array2 = Array(desc.utf8)
        array.append(contentsOf: toByteArray(array2.count))
        array.append(contentsOf: array2)
        
        return array
    }
    
    
    
}

public class NoteImage : NoteObject {
    
    var image:UIImage?
    var width:CGFloat=159
    var height:CGFloat=150
    
    init( image: UIImage) {
        self.image=image
    }
    
    init(newid: Int, image: UIImage) {
        super.init()
        id=newid
        self.image=image
    }
    
    init(pk:Int, bytes:[UInt8]) {
        super.init()
        id=pk
        var offset = 0
        
        let w=NoteObject.readInt(bytes, offset: &offset)
        let h=NoteObject.readInt(bytes, offset: &offset)
        if w! > 0 {
            width=CGFloat(w!)
        }
        if h! > 0 {
            height=CGFloat(h!)
        }
        let arr_bytes=NoteObject.readArray(bytes, offset: &offset, capacity: bytes.count-16, endOffset: bytes.count)
        image=UIImage(data: Data.fromDatatypeValue(Blob(bytes: arr_bytes!)))!
    }
    
    override func toBytes() -> [UInt8]? {
        let dimg = image!.jpegData(compressionQuality: 1.0)
        var array=[UInt8]()
        array.reserveCapacity((dimg!.count+1+8+8+8))
        array.append(contentsOf: toByteArray(ObjectTags.image.rawValue))
        array.append(contentsOf: toByteArray(dimg!.count+16))
        array.append(contentsOf: toByteArray(Int(width)))
        array.append(contentsOf: toByteArray(Int(height)))
        array.append(contentsOf: dimg!)
        return array
        
    }
}

public class NoteTable : NoteObject {
    
    var nrow:UInt8=0
    var ncol:UInt8=0
    var text:String=""
    
    init( ncol:UInt8,nrow:UInt8, text:String) {
        self.ncol=ncol
        self.nrow=nrow
        self.text=text
    }
    
    init(newid: Int, ncol:UInt8,nrow:UInt8, text:String) {
        super.init()
        id=newid
        self.ncol=ncol
        self.nrow=nrow
        self.text=text
    }
    
    init (pk:Int,bytes:[UInt8]) {
        super.init()
        id=pk
        self.ncol=bytes[0]
        self.nrow=bytes[1]
        text=String(data: Data(bytes[2...bytes.count-1]),encoding: .utf8)!
    }
    
    override func toBytes() -> [UInt8]? {
        var array = Array(text.utf8)
        let all_length=array.count+2
        array.insert(contentsOf: toByteArray(nrow), at: 0)
        array.insert(contentsOf: toByteArray(ncol), at: 0)
        array.insert(contentsOf: toByteArray(all_length), at: 0)
        array.insert(contentsOf: toByteArray(ObjectTags.table.rawValue), at: 0)
        return array
    }
}


enum NotesTypes: Int {
    case DB_LOCAL = 0
    case DB_CLOUD = 1
    case DB_CLOUD_CHAIN = 2
}


class NSection :   ObservableObject, Identifiable,Comparable{
    
    enum types:Int {
        case LOCAL=0
        case CLOUD=1
        case CHAIN=2
        
        func VALUE() ->Int {
            return self.rawValue
        }
    }
    
    let id:Int64
    @Published var name:String
    @Published var type:Int
    var isnew:Int=0
    var date:Double=0
    var perent_id:Int64=0
    var color:String=""
    var prio:Double=0
    
    
    init(_ id:Int64,name:String,type:Int,isnew:Int=0,perent_id:Int64=0){
        self.id=id
        self.name=name
        self.type=type
        self.isnew=isnew
        self.perent_id=perent_id
        self.prio=Double(id)
    }
    
    
    func getTypeAsString() -> String {
        switch(type) {
        case 0: return "Local"
        case 1: return "iCloud"
        case 2: return "Shared"
        default:
            return "Local"
        }
    }
    
    public static func < (lhs: NSection, rhs: NSection) -> Bool {
        return lhs.id < rhs.id
    }
    
    static func == (lhs: NSection, rhs: NSection) -> Bool {
        return  lhs.id == rhs.id
    }
    
}

class Note :  Identifiable,Comparable{
    var id:Int64
    var cloud_id:String? = ""
    var body:[NoteObject]
    var section:Int64
    var date:Double? = 0
    
    var listText:String?=""
    var contentType:Int = 2
    var coordinators:[Any]=Array()
    var savedLocaly:Bool=true
    var checksum:Int=0
    
    var  share:sharedRecord?
    var cache_mark:Bool?=false
    var locked:Bool=false
    var wasFocus:Bool = false
    var owner:String?=nil
    var wasRead=false
    
    init(_ note:Note) {
        self.id=note.id
        self.cloud_id=note.cloud_id
        self.section=note.section
        self.date=note.date
        self.listText=note.listText
        self.contentType=note.contentType
        self.savedLocaly=note.savedLocaly
        self.share=note.share
        self.locked=note.locked
        self.owner = note.owner
        body=Array<NoteObject>()
        for i in note.body {
            body.append(i)
        }
        for j in note.coordinators {
            coordinators.append(j)
        }
    }
    
    init() {
        id=0;
        body=Array()
        section=0
        date = Date().timeIntervalSince1970
        
    }
    
    init(local_id:Int64,section_id:Int64,bytes:[UInt8],update:Double=0) {
        id=local_id;
        section=section_id
        date = (update == 0) ? Date().timeIntervalSince1970 : update
        
        var offset=0
        body=Array<NoteObject>()
        var  idpk:Int=0
        
        while offset < bytes.count {
            
            let type=bytes[offset]
            offset+=1
            guard type != nil else { return }
            
            let length=NoteObject.readInt(bytes, offset: &offset)
            if length == 0 {
                return
            }
            let arr_bytes=NoteObject.readArray(bytes, offset: &offset, capacity: length!, endOffset: bytes.count)
            
            switch(ObjectTags(rawValue:  UInt8(type))) {
            case .text:
                _=addTextCoordinator()
                let length2=NoteObject.readInt(bytes, offset: &offset)
                if length2 == nil {
                    body.append(NoteText(newid:idpk,text: ""))
                } else {
                    var arr_bytes2:[UInt8]?=[]
                    if  length2! > 0 {
                        arr_bytes2=NoteObject.readArray(bytes, offset: &offset, capacity: length2!, endOffset: bytes.count)
                    }
                    body.append(NoteText(pk:idpk,bytes: arr_bytes!,bytes2: arr_bytes2!))
                }
            case .image:
                addEmptyCoordinator()
                body.append(NoteImage(pk:idpk,bytes: arr_bytes!))
                contentType = contentType | 4
            case .table:
                addTableCoordinator()
                body.append(NoteTable(pk:idpk,bytes: arr_bytes!))
                contentType = contentType | 8
            default:
                addTextCoordinator()
                body.append(NoteHiddenText(pk:idpk,bytes: arr_bytes!))
            }
            idpk+=1
        }
    }
    
    init(_ local_id:Int64,section_id:Int64,body:[NoteObject],update:Double=0){
        self.id=local_id
        self.body=body
        self.section=section_id
        self.date=update
    }
    
    func resetFocus() {
        wasFocus=false
    }
    
    func getHistory() ->String {
        if share != nil {
            return share!.getDecription()
        } else {
            return ""
        }
    }
    
    func isInCloud() ->Bool {
        return cloud_id?.count ?? 0 > 1
    }
    
    func getTextCoordinator(_ at:Int) -> TextAreaCoordinator {
        if !wasFocus {
            (coordinators[at] as! TextAreaCoordinator).ptr?.becomeFirstResponder()
            wasFocus=true
        }
        return coordinators[at] as! TextAreaCoordinator
    }
    
    func getTableCoordinator(_ at:Int) -> [TextAreaCoordinator] {
        return coordinators[at] as! [TextAreaCoordinator]
    }
    
    func addEmptyCoordinator() {
        coordinators.append("")
    }
    
    func addTextCoordinator() -> Int {
        coordinators.append(TextAreaCoordinator(self,isTable: false))
        if coordinators[body.count] is TextAreaCoordinator {
            (coordinators[body.count] as! TextAreaCoordinator).notePartId=body.count
        }
        return coordinators.count-1
    }
    
    func addTableCoordinator() -> Int {
        var arr=Array<TextAreaCoordinator>()
        for _ in 0..<100{
            arr.append(TextAreaCoordinator(self,isTable: true))
        }
        coordinators.append(arr)
        return coordinators.count-1
    }
    
    func deleteElement( id:Int) {
        if id < body.count {
            body.remove(at: id)
            coordinators.remove(at: id)
        }
    }
    
    
    func tryToJoinTexts()  ->Int {
        var result=0
        var wasJoin:Bool
        repeat {
            wasJoin=false
            for i in 0..<body.count-1 {
                if body[i] is NoteText
                    && body[i+1] is NoteText {
                    
                    let combination = NSMutableAttributedString()
                    combination.append(getTextCoordinator(i).ptr!.attributedText)
                    combination.append(NSMutableAttributedString(string: "\n"))
                    combination.append(getTextCoordinator(i+1).ptr!.attributedText)
                    
                    getTextCoordinator(i).ptr!.attributedText=combination
                    (body[i] as! NoteText).text = TextAreaCoordinator.toHtml(str: getTextCoordinator(i).ptr!.attributedText) ?? ""
                    
                    body.remove(at: i+1)
                    coordinators.remove(at: i+1)
                    
                    wasJoin=false
                    result+=1
                    break
                }
            }
        } while(wasJoin)
        
        for  i in 0..<body.count {
            body[i].id=i
        }
        return result
    }
    
    func objectMoveUp( id:Int) {
        if id == 0 {
            return
        }
        
        
        refreshValues()
        
        body[id].id-=1
        body[id-1].id+=1
        let otm=body[id]
        body[id]=body[id-1]
        body[id-1]=otm
        
        let ctm=coordinators[id]
        coordinators[id]=coordinators[id-1]
        coordinators[id-1]=ctm
        
        if coordinators[id] != nil && coordinators[id] is TextAreaCoordinator {
            (coordinators[id] as! TextAreaCoordinator).notePartId=id
        }
        if coordinators[id-1] != nil && coordinators[id-1] is TextAreaCoordinator {
            (coordinators[id-1] as! TextAreaCoordinator).notePartId=id-1
        }
        
        tryToJoinTexts()
        
    }
    
    func objectMoveDown( id:Int) ->Int {
        if id == body.count-1 {
            return -1
        }
        refreshValues()
        
        body[id].id+=1
        body[id+1].id-=1
        
        let otm=body[id]
        body[id]=body[id+1]
        body[id+1]=otm
        
        let ctm=coordinators[id]
        coordinators[id]=coordinators[id+1]
        coordinators[id+1]=ctm
        
        if coordinators[id] != nil && coordinators[id] is TextAreaCoordinator {
            (coordinators[id] as! TextAreaCoordinator).notePartId=id
        }
        if coordinators[id+1] != nil && coordinators[id+1] is TextAreaCoordinator {
            (coordinators[id+1] as! TextAreaCoordinator).notePartId=id+1
        }
        
        let res=tryToJoinTexts()
        for  i in 0..<body.count {
            body[i].id=i
        }
        
        return res
    }
    
    
    func getSomeText() -> String {
        var listText=findSomeText()
        if  listText.count > 0 {
            listText = listText.replacingOccurrences(of: "\n", with: " ")
            return listText
        }
        return ""
    }
    let icons=["doc.plaintext" , "doc.richtext","doc.append","table","keyboard","photo"]
    
    func getContentType() -> String {
        return icons[contentType]
    }
    
    func toBytes() -> [UInt8] {
        var res:[UInt8]=Array()
        for e in body {
            res += e.toBytes()!
        }
        return res
    }
    
    static func calculateCheckSum(crc:UInt8, byteValue: UInt8) -> UInt8 {
        let generator: UInt8 = 0x1D
        var newCrc = crc ^ byteValue
        for _ in 1...8 {
            if newCrc & 0x80 != 0 {
                newCrc = (newCrc << 1) ^ generator
            }
            else {
                newCrc <<= 1
            }
        }
        return newCrc
    }
    
    static func checkSum( bytes:[UInt8]) ->Int {
        // var checkSum: UInt8 = 0
        // for item in bytes {
        //    checkSum = calculateCheckSum(crc: checkSum, byteValue: UInt8(item))
        // }
        //return checkSum
        return bytes.count
    }
    
    
    func findSomeText() -> String {
        if locked {
            return "*****"
        }
        var text:String? = "><"
        for n in body {
            if n is NoteText {
                text=(n as! NoteText).desc
                if text?.count ?? 0 > 0 {
                    break
                }
            }
        }
        return text ?? ""
    }
    
    func add(_ text:String) {
        addTextCoordinator()
        body.append(NoteText(newid: Int(body.count),text: text))
        if listText?.count == 0 {
            listText=text
        }
        date = Date().timeIntervalSince1970
    }
    
    
    func addHidden(_ text:String) {
        addTextCoordinator()
        for b in body {
            if b is NoteHiddenText {
                (b as! NoteHiddenText).text+=" "+text
            }
        }
        body.append(NoteHiddenText(newid: Int(body.count),text: text))
        date = Date().timeIntervalSince1970
    }
    
    
    func add(_ image:UIImage,detect:Bool=false) {
        if detect {
            doRecognition(image: image)
        }
        addEmptyCoordinator()
        body.append(NoteImage(newid: Int(body.count),image: image))
        date = Date().timeIntervalSince1970
        contentType = contentType | 4
    }
    
    func add(_ nrow:UInt8,ncol:UInt8,text:String) {
        addTableCoordinator()
        body.append(NoteTable(newid: Int(body.count),ncol: ncol,nrow: nrow,text: text))
        date = Date().timeIntervalSince1970
        contentType = contentType | 8
    }
    
    
    func get(_ index:Int) -> NoteObject {
        return body[index]
    }
    
    func dateToString() -> String {
        let d = Date(timeIntervalSince1970: (TimeInterval(date!) )) // 1000
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let res=dateFormatter.string(from: d)
        return res
    }
    
    public static func < (lhs: Note, rhs: Note) -> Bool {
        return lhs.id < rhs.id
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return  lhs.id == rhs.id
    }
    
    func getSubstring( text:String,start:Int,end:Int) ->String {
        if end < start {
            return ""
        }
        let startIndex = text.index(text.startIndex, offsetBy: start)
        let endIndex = text.index(text.startIndex, offsetBy: end)
        return String(text[startIndex...endIndex])
    }
    
    func backRefreshValues() {
        for n in body {
            if n is NoteText {
                let c=getTextCoordinator(n.id)
                if  c.ptr != nil {
                    c.ptr!.attributedText=TextAreaCoordinator.fromHtml(html: (n as! NoteText).text)
                }
            }
        }
    }
    
    func requestFocusForTheLastField() {
        var last:NoteText?=nil
        for n in body {
            if n is NoteText {
                last=n as! NoteText
            }
        }
        if last != nil {
            wasFocus=false
            let c=getTextCoordinator(last!.id)
        }
    }
    
    func refreshValues() {
        for n in body {
            if n is NoteText {
                let c=getTextCoordinator(n.id)
                if  c.ptr != nil {
                    let str=c.ptr!.text!
                    let end = str.count > 20 ? 20 : str.count-1
                    (n as! NoteText).desc=getSubstring(text: str,start: 0,end: end)
                    (n as! NoteText).text = TextAreaCoordinator.toHtml(str: c.ptr!.attributedText) ?? ""
                }
            } else if n is NoteTable {
                let crarr=getTableCoordinator(n.id)
                if crarr.count > 0 {
                    var value=""
                    let table=(n as! NoteTable)
                    var isfirst=true
                    var num_cols=table.ncol
                    if num_cols >= 100 {
                        num_cols=2
                    }
                    for c in 0..<num_cols*table.nrow {
                        if !isfirst {
                            value+=","
                        } else {
                            isfirst=false
                        }
                        if crarr[Int(c)].ptr != nil {
                            value+=crarr[Int(c)].ptr!.text!
                        } else {
                            value+=""
                        }
                    }
                    (n as! NoteTable).text=value
                }
            }
        }
    }
    
    
    func doRecognition(image:UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            self.addHidden(detectedText)
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch {
        }
    }
    
    func past_image(_ partid:Int,image:UIImage?) {
        if image == nil {
            return
        }
        self.add(image!, detect: false)
        self.add("")
    }
    
}
