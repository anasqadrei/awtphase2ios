//
//  GoogleAnalyticsManager.swift
//  awtarika
//
//  Created by Anas Qadrei on 6/10/16.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import Foundation

class GoogleAnalyticsManager {
    
    static func screenView(name: String) {
        // Track a screen
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.allowIDFACollection = true
        tracker.set(kGAIScreenName, value: name)
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    static func event(category: String, action: String, label: String? = nil, value: NSNumber? = nil) {
        // Track an event
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.allowIDFACollection = true
        
        guard let builder = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value) else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
}
