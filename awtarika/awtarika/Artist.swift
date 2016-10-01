//
//  Artist.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/04/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import Foundation

class Artist {
    var id: Int
    var name: String
    var imageURL: String?
    var totalSongsPages: Int
    var songsPageSize: Int
    
    init(id: Int, name: String){
        self.id = id
        self.name = name
        
        // Defaults
        totalSongsPages = 1
        songsPageSize = 20
    }

}