//
//  AppDelegate.swift
//  Notes2
//
//  Created by Denis Mikaya on 06.08.19.
//  Copyright © 2019 Denis Mikaya. All rights reserved.
//

import UIKit
import CloudKit
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {

    static var storage:Storage? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
            if authorized {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        })
        if launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            application.applicationIconBadgeNumber = AppDelegate.storage!.processNewRecords()
        } else {
            application.applicationIconBadgeNumber = 0
            application.cancelAllLocalNotifications()
        }
        return true
    }
    

    
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }
 
    func  applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = AppDelegate.storage!.processNewRecords()
    }
   

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData!) {
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError!) {
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (_ options:UNNotificationPresentationOptions) -> Void)
    {
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response:UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {

    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        let dict = userInfo as! [String: NSObject]
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)
        if notification?.subscriptionID == CKClient.subscriptionID {
            completionHandler(.newData)
            let queryNotification = notification as! CKQueryNotification
            DispatchQueue.main.async {
                    application.applicationIconBadgeNumber = AppDelegate.storage!.processNewRecords()
            }
            print("2.\(notification)")
        }
        else {
            completionHandler(.noData)
        }
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
     
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.main.async {
                     application.applicationIconBadgeNumber = AppDelegate.storage!.processNewRecords()
        }

       }
    

}

