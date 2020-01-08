//
//  SceneDelegate.swift
//  Notes2
//
//  Created by Denis Mikaya on 06.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import UIKit
import SwiftUI
import CoreSpotlight




class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var shortcutItemToProcess: UIApplicationShortcutItem?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            AppDelegate.storage=Storage()
            window.rootViewController = UIHostingController(rootView: HomeView().environmentObject(AppDelegate.storage!) )
            self.window = window
            window.makeKeyAndVisible()
            
            let act=newArticleShortcut()
            _=UIHostingController(rootView: NoteEditor(hh:{_ in }).environmentObject(AppDelegate.storage!))
            window.rootViewController?.userActivity=act
            act.becomeCurrent()
        }
    }
    
    public  func newArticleShortcut() -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.mobico.DaoNotes.AddToTheNoteIntent")
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier("com.mobico.DaoNotes.AddToTheNoteIntent")
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType:  "NSUserActivity.searchableItemContentType")
        activity.title = "Write a new note"
        attributes.contentDescription = "The chance to retain something!"
        activity.suggestedInvocationPhrase = "Just add a note!"
        activity.contentAttributeSet = attributes
        return activity
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("activity")
        self.window?.rootViewController?.present(UIHostingController(rootView: NoteEditor(hh:{_ in }).environmentObject(AppDelegate.storage!)), animated: true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let icon = UIApplicationShortcutIcon(type: .add)
        let item = UIApplicationShortcutItem(type: "com.mobico.DaoNotes.addnote", localizedTitle: "Add Note", localizedSubtitle: "add something to notes", icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [item]
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        shortcutItemToProcess = shortcutItem
        self.window?.rootViewController?.present(UIHostingController(rootView: NoteEditor(hh:{_ in }).environmentObject(AppDelegate.storage!)), animated: true)
    }

}

