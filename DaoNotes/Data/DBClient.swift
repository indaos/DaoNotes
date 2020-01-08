//
//  DBClient.swift
//  Notes2
//
//  Created by Denis Mikaya on 08.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import Foundation
import SQLite

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.mobico.TodoShare"
    )!
  }
}


class DBClient {
    
    let dbFileMame:String="./notes.db"
    var db:Connection?
    
    public func connect() -> Bool {
        do {
            let documentsPath = FileManager.sharedContainerURL()
            db = try Connection((documentsPath.absoluteString)+"/"+self.dbFileMame)
        }catch {
            return false
        }
        if !createNotesTable() {
            return false
        }
        if !createSectTable() {
            return false
        }
        if !createSettingsTable() {
            return false
        }
        if !createSharedcacheTable() {
            return false
        }
        return true
    }

    private func dropTables() {
        let notes=Table("notes")
        let cat=Table("sections")
        let cld=Table("settings")
        let shr=Table("shared_cache")
        try! db?.run(notes.drop(ifExists: true))
        try! db?.run(notes.dropIndex(Expression<Double>("date"), ifExists: true))
        try! db?.run(cat.drop(ifExists: true))
        try! db?.run(shr.drop(ifExists: true))
    }
    
    private func createNotesTable() -> Bool {
        let notes=Table("notes")
        let id=Expression<Int64>("id")
        let body=Expression<SQLite.Blob>("body")
        let cat_id=Expression<Int>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        do {
            try db?.run(notes.create(ifNotExists: true) { t in
                t.column(id,primaryKey: true)
                t.column(cloud_id)
                t.column(body)
                t.column(cat_id)
                t.column(date)
                t.column(locked)
                t.column(checksum)
            })
            try db?.run(notes.createIndex(date ,ifNotExists: true))
        }catch {
            return false
        }
        return true
    }
    
    private func createSectTable() -> Bool {
        let cat=Table("sections")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let isnew=Expression<Int>("isnew")
        let date=Expression<Double>("date")
        let parent_id=Expression<Int64>("parent_id")
        let color=Expression<String?>("color")
        let prio=Expression<Double>("prio")
        do {
            try db?.run(cat.create(ifNotExists: true) { t in
                t.column(id,primaryKey: true)
                t.column(name)
                t.column(type)
                t.column(isnew)
                t.column(date)
                t.column(parent_id)
                t.column(color)
                t.column(prio)
            })
        }catch {
            return false
        }
        return true
    }
    
    private func createSettingsTable() -> Bool {
        let cat=Table("settings")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let fs=Expression<Int>("fontsize")
        let vs=Expression<String>("values")
        let clr=Expression<Int>("color")
        do {
            try db?.run(cat.create(ifNotExists: true) { t in
                t.column(id,primaryKey: true)
                t.column(name)
                t.column(fs)
                t.column(vs)
                t.column(clr)
            })
        }catch {
            return false
        }
        return true
    }
    
    private func createSharedcacheTable() -> Bool {
        let cat=Table("shared_cache")
        let id=Expression<Int64>("id")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let read=Expression<Bool>("read")
        let owner=Expression<String>("owner")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let shid=Expression<String>("shid")
        let shuser=Expression<String>("shuser")
        let shshared=Expression<String>("shshared")
        let shsharedid=Expression<String>("shsharedid")
        let showner=Expression<String>("showner")
        let edited=Expression<String>("edited")
        
        do {
            try db?.run(cat.create(ifNotExists: true) { t in
                t.column(shid,primaryKey: true)
                t.column(id)
                t.column(sec_id)
                t.column(read)
                t.column(owner)
                t.column(date)
                t.column(cloud_id)
                t.column(locked)
                t.column(checksum)
                t.column(edited)
                t.column(shuser)
                t.column(shshared)
                t.column(showner)
                t.column(shsharedid)
                t.column(body)
            })
        }catch {
            return false
        }
        return true
    }
    

    
    public func addNote(_  note:Note) -> Int64 {
        let notes = Table("notes")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let bytes=note.toBytes()
        let cks=Note.checkSum(bytes: bytes)
        
        let i = notes.insert(body <- SQLite.Blob(bytes: bytes),
                             sec_id <- note.section,
                             date <- note.date! ,
                             cloud_id <- note.cloud_id!,
                             checksum <- Int(cks),
                             locked<-note.locked)
        do {
            let rowid=try db?.run(i)
            return rowid ?? -1
        }catch {
            print("Error info: \(error)")
        }
        return -1
    }
    
    public func addNote(_ section_id:Int64,bytes:[UInt8],thisdate:Date?=nil) -> Int64 {
        let notes = Table("notes")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let now=thisdate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let cks=Note.checkSum(bytes: bytes)
        
        let i = notes.insert(body <- SQLite.Blob(bytes: bytes),
                             sec_id <- section_id,date <-  now ,
                             cloud_id <- "",
                             checksum <- Int(cks),
                             locked<-false)
        do {
            let rowid=try db?.run(i)
            return rowid ?? -1
        }catch {
            print("Error info: \(error)")
        }
        return -1
    }
       
      public func modNote(_ note:Note) -> Bool  {
        let notes = Table("notes")
        let body=Expression<SQLite.Blob>("body")
        let id=Expression<Int64>("id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let now=Date().timeIntervalSince1970
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let bytes=note.toBytes()
        let cks=Note.checkSum(bytes: bytes)
        
        let filteredTable = notes.filter(id == note.id)
        
        let i = filteredTable.update(body <- SQLite.Blob(bytes: bytes),
                                     cloud_id <- note.cloud_id!,
                                     date <-  now ,checksum <- Int(cks),
                                     locked<-note.locked)
        do {
            _=try db?.run(i)
        }catch {
            return false
        }
        return true
    }
       
    public func delNote(_ local_id: Int64) -> Bool  {
        let notes = Table("notes")
        let id=Expression<Int64>("id")
        let filteredTable = notes.filter(id == local_id)
        let i = filteredTable.delete()
        do {
            _=try db?.run(i)
        }catch {
            return false
        }
        return true
    }
    
    
    public func getNote(_ local_id:Int64) -> Note? {
        let notes = Table("notes")
        let id=Expression<Int64>("id")
        let body=Expression<Blob?>("body")
        let sec_id=Expression<Int64>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        
        for rec in try! db!.prepare(notes.select(id,body,
                                                 sec_id,date,
                                                 cloud_id,checksum,
                                                 locked)
            .filter(id == local_id)) {
                let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body]!.bytes,update: rec[date])
                note.cloud_id=rec[cloud_id]
                note.checksum=rec[checksum]
                note.locked=rec[locked]
                return note
        }
        
        return nil
    }
    
    public func loadNotesAfter(_ section_id:Int64,last:Double?=nil) -> Array<Note> {
        
        var rec_list:Array<Note>=Array()
        let notes = Table("notes")
        let id=Expression<Int64>("id")
        let body=Expression<Blob?>("body")
        let sec_id=Expression<Int64>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let last_tm:Double = last ?? 0

        for rec in try! db!.prepare(notes.select(id,
                                                 body,sec_id,
                                                 date,cloud_id,
                                                 checksum,locked)
            .filter(sec_id == section_id && date > last_tm)) {
                let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body]!.bytes,update: rec[date])
                note.cloud_id=rec[cloud_id]
                note.checksum=rec[checksum]
                note.locked=rec[locked]
                rec_list.append(note)
        }
        
        return rec_list
        
    }
    
    public func loadNotes(_ section_id:Int64) -> Array<Note> {
        
        var rec_list:Array<Note>=Array()
        let notes = Table("notes")
        let id=Expression<Int64>("id")
        let body=Expression<Blob?>("body")
        let sec_id=Expression<Int64>("section_id")
        let date=Expression<Double>("date")
        let cloud_id=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        
        for rec in try! db!.prepare(notes.select(id,body,
                                                 sec_id,date,
                                                 cloud_id,
                                                 checksum,locked)
            .filter(sec_id == section_id)) {
                let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body]!.bytes,update: rec[date])
                note.cloud_id=rec[cloud_id]
                note.checksum=rec[checksum]
                note.locked=rec[locked]
                rec_list.append(note)
        }
        
        return rec_list
    }
    
    public func filteredLoadNotes(_ section_id:Int64,isall: Bool,text:String) -> Array<Note> {
         
           var rec_list:Array<Note>=Array()
           let notes = Table("notes")
          
           let id=Expression<Int64>("id")
           let body=Expression<Blob?>("body")
           let sec_id=Expression<Int64>("section_id")
           let date=Expression<Double>("date")
           let cloud_id=Expression<String>("cloud_id")
           let locked=Expression<Bool>("locked")
           let checksum=Expression<Int>("checksum")
        
            var table=notes
            if !isall {
                table=notes.filter(sec_id == section_id)
            }

            for rec in try! db!.prepare(table.select(id,body,sec_id,date,cloud_id,checksum,locked)) {
              let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body]!.bytes,update: rec[date])
              note.cloud_id=rec[cloud_id]
              note.checksum=rec[checksum]
              note.locked=rec[locked]
              var toadd=false
              for n in note.body {
                  if n is NoteText {
                    if TextAreaCoordinator.fromHtml(html: (n as! NoteText).text)?.string.contains(text) ?? false {
                          toadd=true
                          break
                      }
                  }  else if n is NoteTable {
                      let table=(n as! NoteTable)
                      if table.text.contains(text) {
                          toadd=true
                          break
                      }
                  } else if n is NoteHiddenText {
                      if (n as! NoteHiddenText).text.contains(text) {
                          toadd=true
                          break
                      }
                  }
              }
              if toadd {
                  rec_list.append(note)
              }
            }
              
          
          return rec_list
      }
    
    
    public func addSection(_ txt: String, type:Int=0,pid:Int64 = 0,clr:String="") -> Int64 {
            let cat = Table("sections")
            let name=Expression<String?>("name")
            let types=Expression<Int>("type")
            let isnew=Expression<Int>("isnew")
            let date=Expression<Double>("date")
            let parent_id=Expression<Int64>("parent_id")
            let color=Expression<String?>("color")
            let prio=Expression<Double>("prio")
      
           var rowid:Int64=0
           let i = cat.insert(name <- txt,types <- type,isnew <- 0,date <- 0,parent_id <- pid,color <- clr,prio <- Double(0))
            do {
                 rowid=try db!.run(i)
            }catch {
                print("Error info: \(error)")
                return -1
            }
            modSection( rowid,newname: txt,type:type,prio: Double(rowid),clr:clr)
            return rowid;
        }
    
    public func modSection(_ local_id: Int64,prio: Double) -> Bool  {
              let cat = Table("sections")
              let id=Expression<Int64>("id")
              let prioritet=Expression<Double>("prio")

              let filteredTable = cat.filter(id == local_id)

              let i = filteredTable.update(prioritet<-prio)
              do {
                  let rowid=try db?.run(i)
              }catch {
                return false
              }
              return true;
          }
    
    public func modSection(_ local_id: Int64,newname: String,type:Int=0,prio: Double,clr:String="") -> Bool  {
              let cat = Table("sections")
              let name=Expression<String?>("name")
              let id=Expression<Int64>("id")
              let types=Expression<Int>("type")
              let color=Expression<String?>("color")
              let prioritet=Expression<Double>("prio")

              let filteredTable = cat.filter(id == local_id)

              let i = filteredTable.update(name <- newname,types <- type,color <- clr,prioritet <- prio)
              do {
                  let rowid=try db?.run(i)
              }catch {
                return false
              }
              return true;
          }
    
    
    public func modSectionSyncDate(_ local_id: Int64,last:Double) -> Bool  {
                 let cat = Table("sections")
                 let id=Expression<Int64>("id")
                 let date=Expression<Double>("date")

                 let filteredTable = cat.filter(id == local_id)

                 let i = filteredTable.update(date <- last)
                 do {
                     let rowid=try db?.run(i)
                 }catch {
                   return false
                 }
                 return true;
             }
    
    public func delAllChilds( local_id:Int64) -> Bool {
            let cat = Table("sections")
            let id=Expression<Int64>("id")
            let parent_id=Expression<Int64>("parent_id")

            let filteredTable = cat.filter(parent_id == local_id)

            let i = filteredTable.delete()
            do {
                let rowid=try db?.run(i)
            }catch {
              return false
            }
            return true;
        }
        
        public func delSection(_ local_id: Int64) -> Bool  {
                 let cat = Table("sections")
                 let id=Expression<Int64>("id")

                 let filteredTable = cat.filter(id == local_id)

                 let i = filteredTable.delete()
                 do {
                     let rowid=try db?.run(i)
                 }catch {
                   return false
                 }
                 return true;
             }
        
    public func loadSections() -> Array<NSection> {
        var rec_list:Array<NSection>=Array()
        let sections = Table("sections")
        
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let isnew=Expression<Int>("isnew")
        let date=Expression<Double>("date")
        let parent_id=Expression<Int64>("parent_id")
        let color=Expression<String?>("color")
        let prio=Expression<Double>("prio")
        
        for rec in try! db!.prepare(sections.select(id,name,
                                                    type,
                                                    isnew,
                                                    date,
                                                    parent_id,
                                                    color,prio)
            .filter(parent_id == 0)) {
                let sec=NSection(rec[id],name: rec[name]!,type: rec[type],isnew: rec[isnew],perent_id: rec[parent_id])
                sec.date=rec[date]
                sec.color=rec[color]!
                sec.prio=rec[prio]
                rec_list.append(sec)
        }
        
        return rec_list
    }
    
    public func  loadAllChilds() -> Array<NSection> {
        var rec_list:Array<NSection>=Array()
        let sections = Table("sections")
        
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let isnew=Expression<Int>("isnew")
        let date=Expression<Double>("date")
        let parent_id=Expression<Int64>("parent_id")
        let color=Expression<String?>("color")
        let prio=Expression<Double>("prio")
        
        for rec in try! db!.prepare(sections.select(id,name,
                                                    type,isnew,
                                                    date,parent_id,
                                                    color,prio)
            .filter(parent_id != 0)) {
                let sec=NSection(rec[id],name: rec[name]!,type: rec[type],isnew: rec[isnew],perent_id: rec[parent_id])
                sec.date=rec[date]
                sec.color=rec[color]!
                sec.prio=rec[prio]
                rec_list.append(sec)
        }
        
        return rec_list
    }
    
    public func loadChildSection(_ local_id:Int64) -> Array<NSection> {
        var rec_list:Array<NSection>=Array()
        let sections = Table("sections")
        
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let isnew=Expression<Int>("isnew")
        let date=Expression<Double>("date")
        let parent_id=Expression<Int64>("parent_id")
        let color=Expression<String?>("color")
        let prio=Expression<Double>("prio")
        
        for rec in try! db!.prepare(sections.select(id,
                                                    name,
                                                    type,
                                                    isnew,date,
                                                    parent_id,
                                                    color,prio)
            .filter(parent_id == local_id)) {
                let sec=NSection(rec[id],name: rec[name]!,type: rec[type],isnew: rec[isnew],perent_id: rec[parent_id])
                sec.date=rec[date]
                sec.color=rec[color]!
                sec.prio=rec[prio]
                rec_list.append(sec)
        }
        
        return rec_list
    }
    
       
    public func getSection(_ local_id:Int64) -> NSection? {
        let sections = Table("sections")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let date=Expression<Double>("date")
        let parent_id=Expression<Int64>("parent_id")
        let color=Expression<String?>("color")
        let prio=Expression<Double>("prio")
        
        for rec in try! db!.prepare(sections.select(id,name,
                                                    type,date,
                                                    parent_id,
                                                    color,
                                                    prio)
            .filter(id == local_id)) {
                let sec=NSection(rec[id],name: rec[name]!,type: rec[type])
                sec.date=rec[date]
                sec.perent_id=rec[parent_id]
                sec.color=rec[color]!
                sec.prio=rec[prio]
                return sec
        }
        
        return nil
    }
    
    
    public func isThereNewInSection( section_id:Int64) -> Int {
        let sections = Table("sections")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let type=Expression<Int>("type")
        let isnew=Expression<Int>("isnew")
        
        let table=sections.filter(id == section_id)
        
        for rec in try! db!.prepare(table.select(id,name,type,isnew)) {
            return rec[isnew]
        }
        return 0
    }
    
       
      public func setNewInSection(_ local_id: Int64)  ->Int {
                
                let n=isThereNewInSection(section_id: local_id)
                let cat = Table("sections")
               // let name=Expression<String?>("name")
                let id=Expression<Int64>("id")
               // let types=Expression<Int>("type")
                let isnew=Expression<Int>("isnew")
                let filteredTable = cat.filter(id == local_id)
                let i = filteredTable.update(isnew <- (n+1))
                do {
                    let _=try db?.run(i)
                }catch {
                  return 0
                }
                return n+1;
        }
    
    
    public func clearNewInSection(_ local_id: Int64)   {
                   let cat = Table("sections")
                   let name=Expression<String?>("name")
                   let id=Expression<Int64>("id")
                   let types=Expression<Int>("type")
                  let isnew=Expression<Int>("isnew")

                   let filteredTable = cat.filter(id == local_id)

                   let i = filteredTable.update(isnew <- 0)
                   do {
                       let rowid=try db?.run(i)
                   }catch {
                     return
                   }
                   return ;
           }
    
    public func loadSettings() -> [String:Any]? {
        let tset = Table("settings")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let fs=Expression<Int>("fontsize")
        let vs=Expression<String>("values")
        let clr=Expression<Int>("color")
        
        for rec in try! db!.prepare(tset.select(id,name,fs,vs,clr)) {
            var res:[String:Any]?=[:]
            res!["id"]=rec[id]
            res!["name"]=rec[name]
            res!["fontsize"]=rec[fs]
            res!["values"]=rec[vs]
            res!["color"]=rec[clr]
            return res
        }
        return nil
    }
    
    
    public func saveSettings(_ attrs:[String:Any]) ->Int64 {
        let tset = Table("settings")
        let id=Expression<Int64>("id")
        let name=Expression<String?>("name")
        let fs=Expression<Int>("fontsize")
        let vs=Expression<String>("values")
        let clr=Expression<Int>("color")
        
        do {
            if attrs["id"] as! Int64 == -1 {
                let i = tset.insert(name <- attrs["name"] as? String,
                                    fs <- attrs["fontsize"] as! Int,
                                    vs <- attrs["values"] as! String,
                                    clr<-attrs["color"] as! Int)
                let rowid=try db?.run(i)
                return rowid ?? -1
            } else {
                let filteredTable = tset.filter(id == attrs["id"] as! Int64)
                let i = filteredTable.update(name <- attrs["name"] as? String,
                                             fs <- attrs["fontsize"] as! Int,
                                             vs <- attrs["values"] as! String,
                                             clr<-attrs["color"] as! Int)
                try db?.run(i)
                return attrs["id"] as? Int64 ?? -1
             }
        }catch {
        }
        return -1
    }
    
    
    public func syncSharedCache(cloud:[Note]) {
        
        let local=loadSharedCache()
        var dict:[String:Note]=[:]
        for n in local {
            dict[n.share!.id]=n
        }
        let cache = Table("shared_cache")
        let i = cache.delete()
        do {
            try db?.run(i)
        }catch {
        }
        
        for n in cloud {
            var read=false
            let n2=dict[n.share!.id]
            if n2 != nil {
                read=n2!.wasRead
            }
            addSsharedCache(n)
        }
    }
    
    public func addSharedCache(_ nid:Int64,section_id:Int64,wasRead:Bool,owner:String,bytes:[UInt8],record_id:String ,cloud_id:String,desc:String,thisdate:Date?=nil) -> Int64 {
        let notes = Table("shared_cache")
        let id=Expression<Int64>("id")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let read=Expression<Bool>("read")
        let own=Expression<String>("owner")
        let recid=Expression<String>("recordid")
        let edited=Expression<String?>("edited")
        let date=Expression<Double>("date")
        let cid=Expression<String>("cloud_id")
        let now=thisdate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        let cks=Note.checkSum(bytes: bytes)
        
        let i = notes.insert(id<-nid,read<-wasRead,
                             own<-owner,body <- SQLite.Blob(bytes: bytes),
                             sec_id <- section_id,
                             date <-  now ,cid <- cloud_id,
                             checksum <- Int(cks),locked<-false,
                             recid<-record_id,edited<-desc)
        
        do {
            let rowid=try db?.run(i)
            return rowid ?? -1
        }catch {
            print("Error info: \(error)")
        }
        return -1
    }
    
    public func addSsharedCache(_ n:Note) -> Int64 {
        let notes = Table("shared_cache")
        let id=Expression<Int64>("id")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let read=Expression<Bool>("read")
        let own=Expression<String>("owner")
        let date=Expression<Double>("date")
        let cid=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        
        let shid=Expression<String>("shid")
        let shuser=Expression<String>("shuser")
        let shshared=Expression<String>("shshared")
        let shsharedid=Expression<String>("shsharedid")
        let showner=Expression<String>("showner")
        let edited=Expression<String>("edited")

        let now=n.date ?? Date().timeIntervalSince1970
        let bytes = n.toBytes()
        let cks=Note.checkSum(bytes: bytes)
       
        let i = notes.insert(id<-n.id,read<-n.wasRead,own<-n.owner ?? "",body <- SQLite.Blob(bytes: bytes),sec_id <- n.section,
                             date <-  now ,cid <- n.cloud_id!,
                             checksum <- Int(cks),locked<-false,
                             shid<-n.share!.id,shuser<-n.share!.user,
                             shshared<-n.share!.shared,
                             shsharedid<-n.share!.sharedid,showner<-n.share!.owner,
                             edited<-sharedRecord.modificationToString(n.share?.getModifications() ?? [""]))
        do {
            let rowid=try db?.run(i)
           return rowid ?? -1
        }catch {
           print("Error info: \(error)")
        }
        return -1
    }
    
    public func loadSharedCache2() -> Array<Note> {
        
        var rec_list:Array<Note>=Array()
        let notes = Table("shared_cache")
        let id=Expression<Int64>("id")
        let body=Expression<SQLite.Blob>("body")
        let sec_id=Expression<Int64>("section_id")
        let read=Expression<Bool>("read")
        let own=Expression<String>("owner")
        let date=Expression<Double>("date")
        let cid=Expression<String>("cloud_id")
        let locked=Expression<Bool>("locked")
        let checksum=Expression<Int>("checksum")
        
        let shid=Expression<String>("shid")
        let shuser=Expression<String>("shuser")
        let shshared=Expression<String>("shshared")
        let shsharedid=Expression<String>("shsharedid")
        let showner=Expression<String>("showner")
        let edited=Expression<String>("edited")
        
        for rec in try! db!.prepare(notes.select(id,read,
                                                 own,body,
                                                 sec_id,date,
                                                 cid,
                                                 checksum,
                                                 locked,
                                                 shid,
                                                 shuser,
                                                 shshared,
                                                 shsharedid,
                                                 showner,
                                                 edited)) {
                                                    let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body].bytes,update: rec[date])
                                                    note.cloud_id=rec[cid]
                                                    note.checksum=rec[checksum]
                                                    note.locked=rec[locked]
                                                    note.share=sharedRecord(id: rec[shid] , user: rec[shuser] ,
                                                                            sharedid: rec[shsharedid] ,
                                                                            shared: rec[shshared] ,
                                                                            owner: rec[showner] ,
                                                                            edited: sharedRecord.parseModificationString(rec[edited]))
                                                    note.wasRead=rec[read]
                                                    note.owner=rec[own]
                                                    rec_list.append(note)
                                                    print("**** get \(note.findSomeText())")
                                                    
        }
        
        return rec_list
    }
    
    public func loadSharedCache() -> Array<Note> {
           
             var rec_list:Array<Note>=Array()
             let notes = Table("shared_cache")
             let id=Expression<Int64>("id")
             let body=Expression<Blob?>("body")
             let sec_id=Expression<Int64>("section_id")
             let read=Expression<Bool>("read")
             let owner=Expression<String>("owner")
             let recid=Expression<String>("recordid")
             let edited=Expression<String?>("edited")
             let date=Expression<Double>("date")
             let cloud_id=Expression<String>("cloud_id")
             let locked=Expression<Bool>("locked")
             let checksum=Expression<Int>("checksum")

              for rec in try! db!.prepare(notes.select(id,read,owner,
                                                       body,sec_id,
                                                       date,
                                                       cloud_id,
                                                       checksum,
                                                       locked,
                                                       recid,
                                                       edited)) {
                let note=Note(local_id:rec[id],section_id: rec[sec_id],bytes: rec[body]!.bytes,update: rec[date])
                note.cloud_id=rec[cloud_id]
                note.checksum=rec[checksum]
                note.locked=rec[locked]
                note.share=sharedRecord(id: rec[recid] ?? "", user: "", sharedid: "", shared: "", owner: "", edited: [:])
                note.share!.cachedDescription=rec[edited]
                note.wasRead=rec[read]
                note.owner=rec[owner]
                rec_list.append(note)
                print("**** get \(note.findSomeText())")

              }
            
            return rec_list
        }

    
    public func markRecordAsRead(_ rid:String)  {
           let cache = Table("shared_cache")
           let recid=Expression<String>("shid")
           let read=Expression<Bool>("read")
           let filteredTable = cache.filter(recid == rid)
           let i = filteredTable.update(read<-true)
           do {
               try db?.run(i)
           }catch {
           }
           return
       }
    
    public func wasRecordRead(_ rid:String) ->Bool {
        let cache = Table("shared_cache")
        let recid=Expression<String>("shid")
        let read=Expression<Bool>("read")
        for rec in try! db!.prepare(cache.select(recid,read).filter(recid == rid)) {
            return rec[read]
        }
        return false
    }
    
    
    

    
}


