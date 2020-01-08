//
//  CKClient.swift
//  Notes2
//
//  Created by Denis Mikaya on 22.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import Foundation
import CloudKit
import UIKit
import SQLite


struct sharedRecord {
    var id:String
    var user:String
    var sharedid:String
    var shared:String
    var owner:String
    var edited:[Double:String]
    var wasShared=true
    
    var cachedDescription:String?=nil
    
    mutating func addModificationLine(user:String) {
        edited[Date().timeIntervalSince1970]=user
    }
    
    func getModifications() -> [String] {
        let sortedDic = edited.sorted { (aDic, bDic) -> Bool in
            return aDic.key < bDic.key
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        var res=[String]()
        for (k,v) in sortedDic {
            res.append(dateFormatter.string(from: Date(timeIntervalSince1970: (TimeInterval(k) )) )+":"+v)
        }
        return res
    }
    
    static func modificationToString(_ str:[String]) ->String {
        var res=""
        var isfirstline=true
        for s in str {
            if isfirstline {
                isfirstline=false
            } else {
                res+="\n"
            }
            res+=s
        }
        return res
    }
    
    static func parseModificationString(_ str:String) ->[Double:String]{
        var res:[Double:String]=[:]
        let lines=str.components(separatedBy: "\n")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        for l in lines {
            let a=l.components(separatedBy: ":")
            let d=dateFormatter.date(from: a[0])?.timeIntervalSince1970
            res[d!]=a[1]
        }
        return res
    }
    
    func getDecription() -> String {
        if cachedDescription != nil {
            return cachedDescription!
        }
        let a=getModifications()
        var res=""
        var nLine=0
        for s in a.reversed() {
            res+=s+"\n"
            nLine+=1
            if nLine == 3 {
                break
            }
        }
        return res
    }
    
}

class CKClient  {
    var container : CKContainer
    var publicDB : CKDatabase
    var privateDB : CKDatabase
    var sharedDB : CKDatabase
    var cStatus:CKAccountStatus = .restricted
    
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
        createCustomZone(zoneName: "notesdb") { returnRecord, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func getWarningMessage() -> String {
        if cStatus == .couldNotDetermine {
            return "You are not signed into iCloud!"
        } else if cStatus == .noAccount {
            return "You are not signed into iCloud!\nPlease try again"
        } else if cStatus == .restricted {
            return "iCloud setting are restricted!"
        }
        return ""
    }
    
    func getCloudAccStaus()  {
        CKContainer.default().accountStatus { status, error in
            if error != nil {
                self.cStatus = .couldNotDetermine
            } else {
                self.cStatus=status
            }
        }
    }
    
    func createCustomZone(zoneName:String,completionHandler:@escaping (CKRecordZone?, Error?)->Void) {
        let customZone = CKRecordZone(zoneName:zoneName)
        privateDB.save(customZone, completionHandler: ({returnRecord, error in
            completionHandler(returnRecord, error)
        }))
    }
    
    func getRecordID(_ id:String,owner:String?=nil) -> CKRecord.ID {
        let zoneID = CKRecordZone.ID(zoneName: "notesdb", ownerName: owner == nil ? CKRecordZone.ID.default.ownerName : owner!)
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        return recordID
    }
    
    func getDefaultRecordID(_ id:String) -> CKRecord.ID {
        let zoneID = CKRecordZone.ID(zoneName: "_defaultZone", ownerName: CKRecordZone.ID.default.ownerName)
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        return recordID
    }
    
    func buildRecord(type:String,zone:String,arg1:[String:Any]) ->CKRecord {
        var noteRecord : CKRecord?=nil
        
        if let cloudId=arg1["cloud_id"] {
            if (cloudId as! String).count > 1  {
                let ckRecordZoneID = CKRecordZone.ID(zoneName: "notesdb")
                let ckRecordID = CKRecord.ID(recordName: cloudId as! String, zoneID: ckRecordZoneID)
                noteRecord = CKRecord(recordType: "note", recordID: ckRecordID)
            }
        } else {
            noteRecord = CKRecord(recordType: type,zoneID: CKRecordZone(zoneName:zone).zoneID)
        }
        for (key,value) in arg1 {
            if value is String {
                noteRecord?.setValue(value as! String, forKey: key)
            } else if value is Int64 {
                noteRecord?.setValue(value as! Int64, forKey: key)
            } else if value is Int {
                noteRecord?.setValue(Int64((value as! Int)), forKey: key)
            } else if value is [UInt8] {
                noteRecord?.setValue(value as! [UInt8], forKey: key)
            } else if value is Date {
                noteRecord?.setValue(value as! Date, forKey: key)
            }
        }
        noteRecord?.setValue(Storage.getOwner(), forKey: "owner")
        let cks=Note.checkSum(bytes: arg1["bytes"] as! [UInt8])
        noteRecord?.setValue(Int(cks), forKey: "checksum")
        
        return noteRecord!
    }
    
    func buildRecord(noteRecord:CKRecord,arg1:[String:Any]) ->CKRecord {
        for (key,value) in arg1 {
            if value is String {
                noteRecord.setValue(value as! String, forKey: key)
            } else if value is Int64 {
                noteRecord.setValue(value as! Int64, forKey: key)
            } else if value is [UInt8] {
                noteRecord.setValue(value as! [UInt8], forKey: key)
            } else if value is Date {
                noteRecord.setValue(value as! Date, forKey: key)
            } else if value is Int {
                noteRecord.setValue(value as! Int, forKey: key)
            }
        }
        return noteRecord
    }
    
    func buildNote(record:CKRecord) ->Note  {
        
        let id=record.object(forKey: "msid") as! Int64
        let sec_id=record.object(forKey: "sid") as! Int64
        let bytes=record.object(forKey: "bytes") as! [UInt8]
        let date=record.modificationDate!.timeIntervalSince1970
        let cks=record.object(forKey: "checksum") as! Int
        let note=Note(local_id:id,section_id: sec_id,bytes: bytes,update: date)
        note.cloud_id=record.recordID.recordName
        note.checksum=cks
        
        return note
    }
    
    func buildDic(_ note:Note) ->[String:Any] {
        var res:[String:Any]=[:]
        res["msid"]=note.id
        res["cloud_id"]=note.cloud_id
        res["sid"]=note.section
        res["bytes"]=note.toBytes()
        return res
    }
    

    
    func addUser( name:String,completion: @escaping (Bool)->Void) {
        let record = CKRecord(recordType: "User")
        record.setValue(name.lowercased(), forKey: "name")
        self.publicDB.save(record, completionHandler: { (record, error) -> Void in
            if let error = error {
                completion(false)
            }
            else {
                print("user name \(name) saved!")
                completion(true)
            }
        })
    }
    
    
    func userExist( name:String,completion: @escaping (Int)->Void ) {
        let predicate = NSPredicate(format: "name = %@",name.lowercased())
        let query = CKQuery(recordType: "User", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: CKRecordZone.ID.default,
                         completionHandler: ({results, error in
                            if error != nil {
                                completion(0)
                            } else {
                                if results!.count > 0 {
                                    if let _ = results, let firstRecord = results?.first {
                                        if firstRecord.creatorUserRecordID?.recordName == CKCurrentUserDefaultName {
                                            completion(1)
                                        } else {
                                            completion(2)
                                        }
                                    }
                                } else {
                                    completion(3)
                                }
                            }
                         }))
    }

    
    
    func addNote( isPublic:Bool,type:String,zone:String,arg1:[String:Any],completion: @escaping (String?)->Void) {
        
        let noteRecord=buildRecord(type: type,zone: zone,arg1: arg1)
        let modifyRecordsOperation = CKModifyRecordsOperation(
            recordsToSave: [noteRecord],
            recordIDsToDelete: nil)
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        modifyRecordsOperation.modifyRecordsCompletionBlock =
            { records, recordIDs, error in
                if let e = error {
                    print("\(e)")
                    completion(nil)
                } else {
                    completion(records?[0].recordID.recordName)
                }
        }
        if !isPublic {
            privateDB.add(modifyRecordsOperation)
        } else {
            publicDB.add(modifyRecordsOperation)
        }
    }
    
    
    func modNote(shared:Bool,recordId:String,owner:String?,arg1:[String:Any],completion: @escaping (String?)->Void)  {
        
        let db=shared ? sharedDB : privateDB
        
        db.fetch(withRecordID: getRecordID(recordId,owner: owner)) { updatedRecord, error in
            if let e = error {
            }
            guard let record = updatedRecord else {
                return
            }
            let id=record.object(forKey: "msid")
            let modRecord=self.buildRecord(noteRecord: record,arg1: arg1)
            db.save(modRecord) { rec, error in
                if let e = error {
                    print("\(e)")
                } else {
                    if rec != nil {
                        completion(rec!.recordID.recordName)
                    }
                }
            }
        }
    }
    
  
    func delNote(recordId:String) {
        _ = CKRecord(recordType: "note",zoneID: CKRecordZone(zoneName:"notesdb").zoneID)
        privateDB.delete(withRecordID: getRecordID(recordId),
                         completionHandler: ({returnRecord, error in
                            if let err = error {
                                print("\(err)")
                            } else {
                            }
                         }))
        
    }
    
    func getNoteCloudId( localid:Int64,completion: @escaping (String)->Void)  {
        let predicate = NSPredicate(format: "msid = \(localid)")
        let query = CKQuery(recordType: "note", predicate: predicate)
        privateDB.perform(query, inZoneWith: CKRecordZone(zoneName:"notesdb").zoneID,
                          completionHandler: ({results, error in
                            if (error != nil) {
                                completion("")
                            } else {
                                if results!.count > 0 {
                                    completion(results![0].recordID.recordName)
                                } else {
                                    completion("")
                                }
                            }
                          }))
    }
    
    func getNotes(last:Double?=nil, completion:@escaping (Bool,[Note]?)->Void) {
        
        var predicate = NSPredicate(value: true)
        if last != nil {
            predicate = NSPredicate(format: "modifiedAt > %@ AND owner = %@",NSDate(timeIntervalSince1970:last!),Storage.getOwner())
        } else {
            predicate = NSPredicate(format: "owner = %@",Storage.getOwner())
        }
        let query = CKQuery(recordType: "note", predicate: predicate)
        
        privateDB.perform(query, inZoneWith: CKRecordZone(zoneName:"notesdb").zoneID,
                          completionHandler: ({results, error in
                            if (error != nil) {
                                completion(true,nil)
                            } else {
                                if results!.count > 0 {
                                    var rec_list:Array<Note>=Array()
                                    for res in results! {
                                        rec_list.append(self.buildNote(record: res))
                                    }
                                    completion(false,rec_list)
                                } else {
                                    print("result: \(results!.count)")
                                    completion(false,nil)
                                }
                            }
                          }))
    }
    

    
    func deleteSharingProfile(recordId: String) {
        publicDB.delete(withRecordID:  getDefaultRecordID(recordId)) { (recordID, error) in
        }
    }
    
    
    func shareLocalRecordToUser(userID:String,recordId: String,completion:@escaping (String?,String)->Void) {
        
        let predicate = NSPredicate(format: "recordID = %@",getRecordID(recordId))
        let query = CKQuery(recordType: "note", predicate: predicate)
        privateDB.perform(query, inZoneWith: nil,
                          completionHandler: ({results, error in
                            if (error != nil) {
                            } else {
                                if results!.count > 0 {
                                    let recordToShare=results![0]
                                    let share = CKShare(rootRecord: recordToShare)
                                    share.publicPermission = .readWrite
                                    let modOp: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave:  [recordToShare,share], recordIDsToDelete: nil)
                                    modOp.savePolicy =  .allKeys
                                    modOp.modifyRecordsCompletionBlock = { records, recordIDs, error in
                                        if let error = error  {
                                        }
                                        else {
                                            if let anURL = share.url {
                                                let record = CKRecord(recordType: "profile")
                                                record.setValue(userID.lowercased(), forKey: "userID")
                                                record.setValue(recordToShare.recordID.recordName,forKey: "shrecordID")
                                                record.setValue(anURL.absoluteString, forKey: "shared_url")
                                                
                                                record.setValue(Storage.getOwner(),forKey: "owner")
                                                record.setValue([String(Date().timeIntervalSince1970)+","+Storage.getOwner()], forKey: "edited")
                                                
                                                self.publicDB.save(record, completionHandler: { (record, error) -> Void in
                                                    if let error = error {
                                                    }
                                                    else {
                                                        completion(anURL.absoluteString,record!.recordID.recordName)
                                                    }
                                                })
                                            }
                                        }
                                    }
                                    self.privateDB.add(modOp)
                                }
                            }}))
        
    }
    
    
    func getAllSharedForUser(username:String,completion: @escaping (_ users:[sharedRecord] ) -> Void) {
        let predicate = NSPredicate(format: "userID = %@",username.lowercased())
        let sort = NSSortDescriptor(key: "modificationDate", ascending: false)
        
        let query = CKQuery(recordType: "profile", predicate: predicate)
        query.sortDescriptors=[sort]
        
        publicDB.perform(query, inZoneWith: CKRecordZone.ID.default,
                         completionHandler: ({results, error in
                            if (error != nil) {
                            } else {
                                var rec_list=[sharedRecord]()
                                if results!.count > 0 {
                                    for res in results! {
                                        var dict=[Double:String]()
                                        let arr:[String]=(res["edited"] ?? [","]) as! [String]
                                        for d in arr {
                                            let v=d.components(separatedBy: ",")
                                            if v.count==2 && v[0].count > 0 && v[1].count > 0 {
                                                dict[Double(v[0])!]=v[1]
                                            } else {
                                                dict[Double(Date().timeIntervalSince1970)]="unknown"
                                            }
                                        }
                                       // let a=res["userID"]
                                       // let b=res["shared_url"]
                                       // let c=res["shrecordID"]
                                       // let d=res["owner"]
                                        
                                        let sr = sharedRecord(id: res.recordID.recordName,user: res["userID"] ?? "",
                                                              sharedid: res["shared_url"] ?? "",
                                                              shared: res["shrecordID"] ?? "", owner: res["owner"] ?? "", edited: dict)
                                        rec_list.append(sr)
                                    }
                                    completion(rec_list)
                                } else {
                                    completion(rec_list)
                                }
                            }
                         }))
    }
    
    func getAllSharingsOfiCloudRecord( recordId:String,completion: @escaping (_ users:[sharedRecord] ) -> Void)  {
        let predicate = NSPredicate(format: "shrecordID = %@",recordId)
        let query = CKQuery(recordType: "profile", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: CKRecordZone.ID.default,
                         completionHandler: ({results, error in
                            if (error != nil) {
                            } else {
                                var rec_list=[sharedRecord]()
                                if results!.count > 0 {
                                    for res in results! {
                                        var dict=[Double:String]()
                                        let arr:[String]=res["edited"]!
                                        for d in arr {
                                            let v=d.components(separatedBy: ",")
                                            dict[Double(v[0])!]=v[1]
                                        }
                                        let shr = sharedRecord(id: res.recordID.recordName,user: res["userID"]!,
                                                               sharedid: res["shared_url"]!,
                                                               shared: res["shrecordID"]!, owner: res["owner"]!, edited: dict)
                                        rec_list.append(shr)
                                    }
                                    completion(rec_list)
                                } else {
                                    print("result: \(results!.count)")
                                    completion(rec_list)
                                }
                            }
                         }))
    }

    
    func loadShared(surl:String,completion:@escaping ([Note]?,String)->Void) {
        let anURL = URL(string: surl)!
        
        let op = CKFetchShareMetadataOperation(shareURLs: [anURL])
        op.perShareMetadataBlock = { shareURL, shareMetadata, error in
            if let error = error {
                print(error)
                completion([],"")
            }
            else if let shareMetadata = shareMetadata {
                if shareMetadata.participantStatus == .accepted {
                    let predicate = NSPredicate(format: "recordID = %@",shareMetadata.rootRecordID)
                    let owner  = shareMetadata.ownerIdentity.userRecordID?.recordName
                    let query = CKQuery(recordType: "note", predicate: predicate)
                    let zone = CKRecordZone.ID(zoneName: "notesdb", ownerName: (owner)!)
                    
                    let db =  self.sharedDB  //owner ==CKCurrentUserDefaultName ?  self.privateDB : self.sharedDB
                    
                    db.perform(query, inZoneWith: zone, completionHandler: { (records, error) in
                        if let error = error {
                            print(error)
                            completion([],"")
                        }
                        else if let records = records, let firstRecord = records.first {
                            
                            var rec_list:Array<Note>=Array()
                            for res in records {
                                rec_list.append(self.buildNote(record: res))
                            }
                            completion(rec_list,owner!)
                        }
                    })
                }
                else if shareMetadata.participantStatus == .pending {
                    let acceptOp = CKAcceptSharesOperation(shareMetadatas: [shareMetadata])
                    acceptOp.qualityOfService = .userInteractive
                    acceptOp.perShareCompletionBlock = { meta, share, error in
                        if let error = error {
                            print(error)
                            completion([],"")
                        }
                        else if let share = share {
                            
                            var predicate = NSPredicate(format: "recordID = %@",shareMetadata.rootRecordID)
                            let owner  = shareMetadata.ownerIdentity.userRecordID?.recordName
                            let query = CKQuery(recordType: "note", predicate: predicate)
                            let zone = CKRecordZone.ID(zoneName: "notesdb", ownerName: (owner)!)
                            let db =  self.sharedDB
                            
                            db.perform(query, inZoneWith: zone, completionHandler: { (records, error) in
                                if let error = error {
                                    print(error)
                                    completion([],"")
                                }
                                else if let records = records, let firstRecord = records.first {
                                    var rec_list:Array<Note>=Array()
                                    for res in records {
                                        rec_list.append(self.buildNote(record: res))
                                    }
                                    completion(rec_list,owner!)
                                }
                            })
                            
                            
                        }
                    }
                    self.container.add(acceptOp)
                }
            }
        }
        op.fetchShareMetadataCompletionBlock = { error in
            if let error = error {
                print(error)
            }
        }
        container.add(op)
    }
    
    
    
    func modPacket(_ notes:[Note]) {
        var records=Array<CKRecord>()
        for n in notes {
            let dic=self.buildDic(n)
            let noteRecord=buildRecord(type: "note",zone: "notesdb",arg1: dic)
            records.append(noteRecord)
        }
        let modifyRecordsOperation = CKModifyRecordsOperation(
            recordsToSave: records,
            recordIDsToDelete: nil)
        
        modifyRecordsOperation.savePolicy = .allKeys;
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.modifyRecordsCompletionBlock =
            { records, recordIDs, error in
                if let e = error {
                    print("\(e)")
                } else {
                }
        }
        privateDB.add(modifyRecordsOperation)
    }
    
    
    func syncing(_ section:Int64,dblocal:DBClient,last_sync:Double,completion:@escaping ( _ last_date:Double )->Void) {
        
        var last:Double?=nil
        if last_sync > 0 {
            last=last_sync
        }
        var oldest:Double=0
        
        getNotes(last: last) { (isError, notes) in
            if notes != nil && notes!.count>0 {
                var local_dic:[Int64:Note]=[:]
                let local:Array<Note>=dblocal.loadNotesAfter(section,last: last)
                for loc_n in local  {
                    local_dic[loc_n.id]=loc_n
                    if loc_n.date! > oldest {
                        oldest=loc_n.date!
                    }
                }
                var notes_packet=Array<Note>()
                for n in notes! {
                    if section==n.section{
                        if local_dic[n.id] == nil {
                            let local_id=dblocal.addNote(n)
                            n.id=local_id
                            notes_packet.append(n)
                        } else {
                            let d_loc = Date(timeIntervalSince1970: TimeInterval(local_dic[n.id]!.date!))
                            let d_cloud = Date(timeIntervalSince1970: TimeInterval(n.date!))
       
                            let seconds = Int(d_loc.timeIntervalSince1970-d_cloud.timeIntervalSince1970)
                            if local_dic[n.id]!.checksum != n.checksum && seconds > 1 {
                                var hasn_cid=false
                                if local_dic[n.id]!.cloud_id?.count == 0 {
                                    hasn_cid=true
                                }
                                local_dic[n.id]!.cloud_id=n.cloud_id
                                notes_packet.append(local_dic[n.id]!)
                                if hasn_cid {
                                    dblocal.modNote(local_dic[n.id]!)
                                }
                            } else if local_dic[n.id]!.checksum != n.checksum && seconds < 0 {
                                dblocal.modNote(n)
                            }
                            local_dic[n.id]=nil
                        }
                    }
                }
                for (key,value) in local_dic {
                    if value != nil {
                        notes_packet.append(value)
                    }
                }
                self.modPacket(notes_packet)
            }
            completion(oldest)
        }
    }
    
    
    public static let subscriptionID = "cloudkit-note-changes"
    private let subscriptionSavedKey = "ckSubscriptionSaved"
    
    public func subscribeForPublic() {
        let predicate = NSPredicate(format: "userID = %@",Storage.getOwner())
        let subscription = CKQuerySubscription(recordType: "profile",
                                               predicate: predicate,
                                               subscriptionID: CKClient.subscriptionID,
                                               options: [CKQuerySubscription.Options.firesOnRecordCreation,
                                                         CKQuerySubscription.Options.firesOnRecordDeletion,
                                                         CKQuerySubscription.Options.firesOnRecordUpdate])
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        notificationInfo.shouldSendMutableContent = true
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else {
                return
            }
            UserDefaults.standard.set(true, forKey: self.subscriptionSavedKey)
        }
        operation.qualityOfService = .utility
        
        _ = CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    
    func unsubscribeAll() {
        publicDB.fetchAllSubscriptions(completionHandler: {subscriptions, error in
            for subscriptionObject in subscriptions! {
                if let  subscription: CKSubscription = subscriptionObject {
                    self.publicDB.delete(withSubscriptionID: subscription.subscriptionID,completionHandler: {subscriptionId, error in
                        if let e = error {
                            print("\(e)")
                        } else {
                            print("unsubscribed: \(subscriptionObject)")
                        }
                    })
                }
            }
        })
        
    }
    
    
    func addModificationLine(shr:sharedRecord) {
        
        let ckRecordZoneID = CKRecordZone.ID(zoneName: "_defaultZone")
        let ckRecordID = CKRecord.ID(recordName: shr.id, zoneID: ckRecordZoneID)
        let record = CKRecord(recordType: "profile", recordID: ckRecordID)
        
        record.setValue(shr.user, forKey: "userID")
        record.setValue(shr.shared,forKey: "shrecordID")
        record.setValue(shr.sharedid, forKey: "shared_url")
        record.setValue(shr.owner,forKey: "owner")
        
        var arr:[String]=[]
        for (k,v) in shr.edited {
            arr.append(String(k)+","+v)
        }
        arr.append(String(Date().timeIntervalSince1970)+","+Storage.getOwner())
        record.setValue(arr, forKey: "edited")
        
        
        let modifyRecordsOperation = CKModifyRecordsOperation(
            recordsToSave: [record],
            recordIDsToDelete: nil)
        
        modifyRecordsOperation.savePolicy = .allKeys;
        
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.modifyRecordsCompletionBlock =
            { records, recordIDs, error in
                if let e = error {
                } else {
                }
        }
        publicDB.add(modifyRecordsOperation)
    }
    
    
}
