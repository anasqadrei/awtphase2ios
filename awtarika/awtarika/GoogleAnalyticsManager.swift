//
//  GoogleAnalyticsManager.swift
//  awtarika
//
//  Created by Anas Qadrei on 6/10/16.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import Foundation

class GoogleAnalyticsManager {
    
    static func screenView(name name: String) {
        //
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: name)
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    static func event(category category: String, action: String, label: String? = nil, value: NSNumber? = nil) {
        //
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value)
        tracker.send(event.build() as [NSObject : AnyObject])
    }
}