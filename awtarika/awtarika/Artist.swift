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
    
    static func createArtist(parsedArtist: [String:AnyObject]) -> Artist? {
        
        // GUARD: Are the artist "_id" and "name" keys in our result?
        guard let id = parsedArtist["_id"] as? Int, name = parsedArtist["name"] as? String else {
            return nil
        }
        
        // Fill artist data
        let artist = Artist(id: id, name: name)
        
        if let imageURL = parsedArtist["image"] as? String {
            artist.imageURL = imageURL
        }
        if let totalSongsPages = parsedArtist["totalSongsPages"] as? Int {
            artist.totalSongsPages = totalSongsPages
        }
        if let songsPageSize = parsedArtist["songsPageSize"] as? Int {
            artist.songsPageSize = songsPageSize
        }
        
        //Return
        return artist
    }


}