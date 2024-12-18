//
//  SwiftUIExampleApp.swift
//  SwiftUIExample
//
//  Created by Hamilton Center on 10/16/24.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import AdSupport
import AppTrackingTransparency
import GoogleSignIn
import ShopifyCheckoutSheetKit

// AppDelegate for handling Firebase, push notifications, Google Sign-In, and tracking
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize Google Sign-In
        GIDSignIn.sharedInstance.restorePreviousSignIn() // Restore previous sign-in if available

        application.applicationIconBadgeNumber = 0

        // Request Tracking Authorization
        requestTrackingAuthorization()

        // Set up push notifications
        setupPushNotifications(application)

        return true
    }

    private func setupPushNotifications(_ application: UIApplication) {
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("Notification permissions granted.")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            } else {
                print("Notification permissions not granted.")
            }
        }

        // Set Messaging delegate
        Messaging.messaging().delegate = self
        print("Set Messaging delegate")
    }

    private func requestTrackingAuthorization() {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    self.printIDFA()
                case .denied, .restricted, .notDetermined:
                    print("Tracking authorization status: \(status)")
                @unknown default:
                    break
                }
            }
        } else {
            // Fallback on earlier versions
            printIDFA()
        }
    }

    private func printIDFA() {
        let idfa = ASIdentifierManager.shared().advertisingIdentifier
        let idfaString = idfa.uuidString
        print("IDFA: \(idfaString)")
    }

    // MARK: - Push Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to a hex string
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let tokenString = tokenParts.joined()

        print("Device Token: \(tokenString)") // Print the formatted device token

        // Pass device token to Firebase
        Messaging.messaging().apnsToken = deviceToken

        // Fetch and print FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error.localizedDescription)")
            } else if let token = token {
                print("Firebase registration token: \(token)")
                self.postTokenToServer(token)

                // Subscribe to the "Wrapsody" topic
                self.subscribeToTopic("Wrapsody")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle push notification when the app is in the foreground
        completionHandler([.alert, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle response to the notification
        completionHandler()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Failed to fetch FCM registration token.")
            return
        }

        print("Firebase registration token: \(fcmToken)")
        // Send the token to your server or save it as needed

        // Optionally, notify parts of your app about the token
        NotificationCenter.default.post(name: Notification.Name("FCMTokenReceived"), object: nil, userInfo: ["token": fcmToken])
    }

    // MARK: - Helper Methods

    private func postTokenToServer(_ token: String) {
        // TODO: Implement the logic to send the token to your server
        print("Posting token to server: \(token)")
    }

    // Method to subscribe to the topic "Wrapsody"
    private func subscribeToTopic(_ topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Error subscribing to topic \(topic): \(error.localizedDescription)")
            } else {
                print("Successfully subscribed to topic \(topic)")
            }
        }
    }
}

@main
struct SwiftUIExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize Shopify Checkout
        ShopifyCheckoutSheetKit.configure {
            $0.preloading.enabled = true
        }

        // Set up custom appearance for UIBarButtonItem
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .wrapsodyGold

        // Set up Login navigation title to blue with enhanced visibility
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // Make the navigation bar transparent initially

        // Create a UIBlurEffect and apply it to the background
        let blurEffect = UIBlurEffect(style: .systemMaterialLight) // You can choose other styles like .dark or .extraLight
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44) // Adjust the height as needed

        // Make the blur view a part of the navigation bar's background
        appearance.backgroundEffect = blurEffect

        // Set text color for the title
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold]

        UINavigationBar.appearance().standardAppearance = appearance

        // Configure the appearance when scrolling
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground() // Ensure transparency when scrolling
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold]
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold]

        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance

        // Tab Bar Customization
        let tabBarAppearance = UITabBarAppearance()

        // Set Wrapsody gold color for tab bar items (selected and unselected)
      tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.wrapsodyGold
      tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold]
      tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.wrapsodyGold2
      tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.wrapsodyGold2]

      // Set background color for the tab bar
      tabBarAppearance.backgroundColor = UIColor.wrapsodyBlue // Change to any color you prefer

        // Set the appearance for both standard and scroll edge appearances
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            LoginView() // Directly show the login view
        }
    }
}
