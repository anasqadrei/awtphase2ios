//
//  Song.swift
//  awtarika
//
//  Created by Anas Qadrei on 30/08/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import Foundation

class Song {
    var id: Int?
    var title: String?
    var artistName: String?
    var durationDesc: String?
    var playsCount: Int?
    var likesCount: Int?

    init(id: Int, title: String){
        self.id = id
        self.title = title
        
        // Defaults
        playsCount = 0
        likesCount = 0
    }
    
}