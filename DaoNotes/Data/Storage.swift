//
//  Storage.swift
//  Notes2
//
//  Created by Denis Mikaya on 06.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//  

import SwiftUI
import Combine
import CloudKit



final class Storage : ObservableObject {
    
    @Published var mathMode=false
    @Published var refresh=false
    @Published var sections: [NSection] = []
    @Published var sectionsNotes:[Note]=[]
    @Published var selectedSection:Int64 = 0
    @Published var showSectionMenu:Bool=true
    @Binding var refreshList:Bool
    
    private static var currentOwner:String=""
    private var currentFilter:String=""
    private var menuActive=true
    
    @Binding var isloading:Bool
    var listSharedCache:[(id:Int,name:String,profileid:String)]=Array()
    
    private var is_debug=false
    
    
    private let database = DBClient()
    var cloud:CKClient?=nil
    
    
    init( is_debug:Bool) {
        self.is_debug=is_debug
        _isloading = .constant(true)
        _refreshList = .constant(false)
        reloadSections()
        reloadNotes(section_id: sections[0].id)
    }
    
    init() {
        _isloading = .constant(true)
        _refreshList = .constant(false)
        if database.connect() {
            if is_debug {
                addDataForTests()
            }
        }
        reloadSections()
        if sections.count == 0 {
            addSomeSections()
            reloadSections()
        }
        reloadNotes(section_id: sections[0].id)
        if  let iprops=loadSettings() {
            Storage.currentOwner = iprops["name"] as? String ??  "guest"
        }
        refreshiCloudUserName()
        initCloud()
    }
    
    func getSectionNotes() -> [Note] {
        return self.sectionsNotes
    }
    
    static func getOwner() -> String {
        return currentOwner.lowercased();
    }
    
    
    func setMenuActive(_ b:Bool) {
        menuActive=b
    }
    
    func isMenuActive() ->Bool {
        return menuActive
    }
    
    
    func  setRefreshList( refresh:Binding<Bool>) {
        _refreshList=refresh
    }
    
    func addUser(name:String,handler: @escaping (Bool)->Void) {
        cloud?.addUser(name: name, completion: { isok in
            handler(isok)
        })
    }
    
    func checkUser(name:String,handler: @escaping (Int)->Void) {
        cloud?.userExist(name: name, completion: handler)
    }
    
    func refreshiCloudUserName(){
        if  let iprops=loadSettings() {
            let user = iprops["name"] as! String
            Storage.currentOwner=user
        } else {
            Storage.currentOwner="guest"
        }
        if cloud?.cStatus == .available {
            cloud?.unsubscribeAll()
            sleep(1)
            cloud?.subscribeForPublic()
        }
    }
    
    func initCloud() {
        cloud = CKClient()
        cloud?.getCloudAccStaus()
        
        //initTempCloudDB()
    }
    
    func initTempCloudDB() {
        
        Storage.currentOwner="john"
        
        for i in 1..<70 {
            let record=Note()
            record.add("This is a icloud note! ("+String(i)+")")
            record.add(3, ncol: 2, text: "This is a table")
            record.add("This is a second note.")
            let bytes=record.toBytes()
            
            cloud?.addNote(isPublic: false,type: "note", zone: "notesdb",
                           arg1: ["msid":i, "sid": 2, "bytes": bytes]) { recordID in
                            
            }
        }
        
        sleep(10)
        
        for j in 1..<50 {
            let record=Note()
            record.add("This is a local note! ("+String(j)+")")
            record.add(3, ncol: 2, text: "This is a table")
            record.add("This is a second note.")
            record.section=2
            _=database.addNote(record)
        }
        
    }
    
    func addSomeSections() {
        _=database.addSection("Local Notes",type: NotesTypes.DB_LOCAL.rawValue)
        _=database.addSection("iCloud Notes",type: NotesTypes.DB_CLOUD.rawValue)
        _=database.addSection("Shared Notes",type: NotesTypes.DB_CLOUD_CHAIN.rawValue)
    }
    
    func getNote(_ id:Int64) ->Note? {
        for n in sectionsNotes {
            if n.id == id {
                return n
            }
        }
        return nil
    }
    
    func getSection(_ id:Int64) ->NSection? {
        for s in sections {
            if s.id == id {
                return s
            }
        }
        let s=database.getSection(id)
        
        return s
    }
    
    func addDataForTests() {
        for i in 1...5 {
            _=database.addSection("Section-"+String(i))
            for _ in 1...5 {
                let record=Note()
                record.add("The simple note and ...")
                _=database.addNote(record)
            }
        }
    }
    
    func saveiCloudContent(_ note:Note) {
        for i in 0..<sectionsNotes.count {
            if sectionsNotes[i].id == note.id {
                sectionsNotes[i]=Note(note)
            }
        }
        let shared=isSharedSection()
        let bytes = note.toBytes()
        let cks=Note.checkSum(bytes: bytes)
        
        cloud?.modNote(shared: shared,recordId: note.cloud_id!,owner: note.owner,
                       arg1: ["msid":note.id, "sid": note.section,"checksum":cks, "bytes": bytes]) { recordID in
                        if  note.share != nil {
                            self.cloud?.addModificationLine(shr: note.share!)
                        }
        }
    }
    
    func saveContent(_ note:Note) {
        for i in 0..<sectionsNotes.count {
            if sectionsNotes[i].id == note.id {
                sectionsNotes[i]=Note(note)
            }
        }
        if !is_debug {
            _=database.modNote(note)
        }
    }
    
    func addRow(_ handler:@escaping ()->Void) -> Bool {
        let record=Note()
        var note:Note?
        var icloud=false
        
        record.add(" ")
        
        if !is_debug {
            let pk=database.addNote(selectedSection,bytes: record.toBytes(),thisdate: Date())
            note=database.getNote(pk) ?? nil
            if note != nil {
                for s in sections {
                    if s.id == selectedSection {
                        if s.type > 0 {
                            icloud=true
                            cloud?.addNote(isPublic: false,
                                           type: "note",
                                           zone: "notesdb",
                                           arg1: ["msid": note!.id,
                                                  "sid": selectedSection,
                                                  "bytes": note!.toBytes()])
                            { recordID in
                                note?.cloud_id=recordID
                                handler()
                            }
                            break
                        }
                    }
                }
            }
        } else {
            note=Note(local_id:-1,section_id: selectedSection,bytes: record.toBytes(),update: Date().timeIntervalSince1970)
        }
        if note != nil {
            sectionsNotes.insert(note!, at: 0)
        }
        if !icloud {
            handler()
        }
        return true
    }
    
    public func loadTheRow(_ pk:Int64) -> Note? {
        let note=database.getNote(pk) ?? nil
        return note
    }
    
    public func saveChildsFor( parent_id:Int64, childs:[(String,String)]) {
        _=database.delAllChilds(local_id: parent_id)
        for n in childs {
            _=database.addSection(n.0, type: 0, pid: parent_id,clr: n.1)
        }
    }
    
    public func saveSection( section:NSection ){
        if !is_debug {
            _=database.modSection(section.id, newname: section.name, type: section.type,prio: section.prio,clr: section.color)
            reloadSections()
        } else {
            for (index,s) in sections.enumerated() {
                if s.id == -1 {
                    sections[index]=NSection(0, name: section.name, type: section.type)
                }
            }
        }
    }
    
    public func addSection() -> Bool {
        var sec:NSection?
        if !is_debug {
            let pk=database.addSection("Section ?",type: 0)
            sec=database.getSection(pk) ?? nil
        } else {
            sec=NSection(-1,name: "Section ?",type: 0)
        }
        if sec != nil {
            sections.insert(sec!, at: 0)
        }
        return true
    }
    
    public func deleteSection(index: Int) {
        if !is_debug {
            _=database.delSection(sections[index].id)
        }
        sections.remove(at: index)
    }
    
    public func deleteRow(index: Int) {
        if !is_debug {
            if sectionsNotes[index].savedLocaly {
                _=database.delNote(sectionsNotes[index].id)
            }
            for s in self.sections {
                if s.id == self.selectedSection {
                    if s.type > 0 {
                        cloud?.delNote(recordId: sectionsNotes[index].cloud_id!)
                    }
                }
            }
        }
        sectionsNotes.remove(at: index)
    }
    
    
    func filterSectionNotes(_ filter:String,_ isall:Bool) {
        if currentFilter == filter {
            return
        }
        if filter.count == 0 && currentFilter.count > 0 {
            reloadNotes(section_id: selectedSection)
        } else if filter.count > 0 {
            sectionsNotes=database.filteredLoadNotes(selectedSection,isall: isall,text: filter)
        }
        currentFilter=filter
    }
    
    
    func  loadSharedMotes(handler: @escaping ([Note])->Void)  {
        
        class Atomic<A> {
            private let queue = DispatchQueue(label: "atomic")
            private var _value: A
            init(_ value: A) {    self._value = value  }
            var value: A {
                get { return queue.sync { self._value } }
            }
            func mutate(_ transform: (inout A) -> ()) {
                queue.sync { transform(&self._value) }
            }
        }
        
        if  let iprops=loadSettings() {
            var res_notes:[Note] = []
            let user = iprops["name"] as! String
            cloud?.getAllSharedForUser(username: user,completion: { records in
                if records.count > 0 {
                    let sync_counter = Atomic<Int>(0)
                    for r in records {
                        self.cloud?.loadShared(surl: r.sharedid,completion: {notes,owner in
                            for n in notes! {
                                n.savedLocaly=false
                                n.owner=owner
                                DispatchQueue.main.sync {
                                    n.share=r
                                    res_notes.append(n)
                                }
                            }
                            sync_counter.mutate({ $0+=1 })
                        })
                    }
                    var max_time_counter = 0
                    while sync_counter.value < records.count && max_time_counter<20 {
                        usleep(500000)
                        max_time_counter += 1
                    }
                    if  max_time_counter<20 {
                    } else {
                    }
                }
                handler(res_notes)
            })
        }
    }
        
    func isNewInSection() ->Int {
        for s in self.sections {
            if s.id == self.selectedSection {
                return s.isnew
            }
        }
        return 0
    }
    
    func isCloudSection() ->Bool {
        for s in self.sections {
            if s.id == self.selectedSection {
                return s.type == 1
            }
        }
        return false
    }
    
    func isSharedSection() ->Bool {
        for s in self.sections {
            if s.id == self.selectedSection {
                return s.type == 2
            }
        }
        return false
    }
    
    func reloadNotes( section_id:Int64) {
        if is_debug {
            sectionsNotes.removeAll()
            for i in 1...10 {
                let note=Note()
                note.add("Note:"+String(section_id)+"...")
                note.section=section_id
                note.id=Int64(i)
                sectionsNotes.append(note)
            }
        } else  if self.isSharedSection() || self.isCloudSection() {
            if self.selectedSection != section_id {
                self.sectionsNotes.removeAll()
            }
            let queue=DispatchQueue.global(qos: .utility)
            queue.async {
                var notes_unsorted:[Note]=[]
                if self.isCloudSection() {
                    self.refreshList.toggle()
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    let last=self.database.getSection(section_id)?.date ?? 0
                    self.cloud?.syncing(section_id, dblocal: self.database, last_sync: last,completion: { last_date in
                        DispatchQueue.main.async {
                            notes_unsorted=self.database.loadNotes(section_id)
                            semaphore.signal()
                        }
                        _=self.database.modSectionSyncDate(section_id, last: last_date)
                    })
                    let res=semaphore.wait( timeout: DispatchTime.now() + .seconds(10))
                    if res == .success {
                    } else {
                        if res == .timedOut {
                        }
                    }
                    DispatchQueue.main.async {
                        notes_unsorted.sort{
                            return Int64($0.date!) > Int64($1.date!)
                        }
                        self.sectionsNotes=notes_unsorted
                    }
                    self.refreshList.toggle()
                } else if self.isSharedSection() {
                    self.refreshList.toggle()
                    if self.selectedSection != section_id {
                        self.loadRecorsFromLocalCache()
                    }
                    self.loadSharedMotes(handler:{ notes in
                        self.database.syncSharedCache(cloud: notes)
                        self.loadRecorsFromLocalCache()
                        
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.refreshList.toggle()
                    }
                }
            }
        } else {
            var sectionsNotes_unsorted=database.loadNotes(section_id)
            sectionsNotes_unsorted.sort{
                return Int64($0.date!) > Int64($1.date!)
            }
            sectionsNotes=sectionsNotes_unsorted
        }
        selectedSection=section_id
    }
    
    
    func loadRecorsFromLocalCache() {
         var notes_unsorted=self.database.loadSharedCache2()
         notes_unsorted.sort{
               return Int64($0.date!) > Int64($1.date!)
         }
         DispatchQueue.main.sync {
             self.sectionsNotes=notes_unsorted
         }
    }
    
    func getNumOfNewecords() ->Int {
        for s in self.sections {
            if s.type == 2 {
                return database.isThereNewInSection(section_id: s.id)
            }
        }
        return 0
        
    }
    
    func processNewRecords() ->Int {
        for s in self.sections {
            if s.type == 2 {
                let n=database.setNewInSection(s.id)
                s.isnew=n
                return n
            }
        }
        return 0
    }

    func reloadSections() {
        if is_debug {
            sections.removeAll()
            for i in 1...10 {
                sections.append(NSection(Int64(i),name: "Section qwertyuzxcvb-"+String(i),type: i))
            }
        } else {
            sections=database.loadSections()
        }
        sections.sort{
            return $0.prio < $1.prio
        }
    }
    
  
    func loadChildSections( parent_id:Int64) -> [NSection] {
       return database.loadChildSection(parent_id)
    }
    
    func getSharedForWho(id:Int64,completion: @escaping ([sharedRecord]) ->Void )  ->Bool {
        if cloud?.cStatus != .available {
            return false
        }
        cloud?.getNoteCloudId(localid: id,completion: { recId in
                self.cloud?.getAllSharingsOfiCloudRecord(recordId: recId, completion: { records in
                    completion(records)
                  })
      
        })
        return true
    }
    
    func loadSettings() -> [String:Any]? {
        return database.loadSettings()
    }
    
    func saveSettings(_ attrs:[String:Any]) {
        _=database.saveSettings(attrs)
        refreshiCloudUserName()
    }
 
    
    func isNewNote( note:Note, isnew: Binding<Bool?> ) -> Bool {
         if isSharedSection() {
              if note.share != nil {
                return database.wasRecordRead(note.share!.id)
              }
        }
        return false
    }
    
    func markNoteAsRead( note:Note){
        if isSharedSection() {
            if note.share != nil {
                database.markRecordAsRead(note.share!.id)
                database.clearNewInSection(selectedSection)
                for s in self.sections {
                    if s.id == selectedSection {
                        s.isnew=0
                    }
                }
            }
        }
    }
    
    
    func deleteShared(_ sharedid:String) {
        cloud?.deleteSharingProfile(recordId: sharedid)
    }
    
    func saveShared(_ localid:Int64,username:String) {
        let note = getNote(localid)
        self.cloud?.shareLocalRecordToUser(userID: username,recordId: note!.cloud_id!) { url,recordID in
            
        }
    }
    
    func doShareofRecord( localid:Int64,values:[String],shared:[Bool]) {
        for i in 0..<values.count {
            if shared[i]  {
                var isexisted=false
                for v in listSharedCache {
                    if v.name == values[i] && v.name != "username" {
                        isexisted=true
                    }
                }
                if values[i].count > 3 && !isexisted {
                    saveShared(localid,username: values[i])
                }
            } else {
                for v in listSharedCache {
                    if v.name == values[i] && v.name != "username" {
                        deleteShared(v.profileid)
                    }
                }
            }
        }
        self.isloading.toggle()
        listSharedCache.removeAll()
    }
    
    func addSharedUserToCache() {
        listSharedCache.append((id: self.listSharedCache.count, name: "username",profileid:""))
    }
    
    func getSharedUsersFor( id:Int64,loading:Binding<Bool>) ->[(id:Int,name:String,profileid:String)] {
        if loading.wrappedValue {
            _isloading=loading
            self.listSharedCache = [(id:Int,name:String,profileid:String)]()
            _ =  getSharedForWho(id: id ,completion: { records in
                var i=0
                for r in records {
                    self.listSharedCache.append((id: i, name: r.user,profileid:r.id))
                    i+=1
                }
                self.isloading.toggle()
            })
        }
        return listSharedCache
    }
    
    
    func getMainColor() -> UIColor {
        if let settings=loadSettings() {
            return DaoColorSheme.getColor(DaoColorSheme.colorsNames[settings["color"] as! Int])
        }
        return DaoColorSheme.getColor("blue")
    }
  
}


