//
//  Song.swift
//  awtarika
//
//  Created by Anas Qadrei on 30/08/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import Foundation
import UIKit

class Song {
    var id: Int
    var title: String
    var artistName: String?
    var url: String?
    var description: String?
    var imageURL: String?
    var image: UIImage?
    var durationDesc: String?
    var playsCount: Int
    var likesCount: Int

    init(id: Int, title: String){
        self.id = id
        self.title = title
        
        // Defaults
        playsCount = 0
        likesCount = 0
    }
    
    static func createSong(parsedSong: [String:AnyObject]) -> Song? {
        
        // GUARD: Is the song "_id" and "title" keys in our result?
        guard let id = parsedSong["_id"] as? Int, title = parsedSong["title"] as? String else {
            return nil
        }
        
        // Fill song data
        let song = Song(id: id, title: title)
        
        if let artistName = (parsedSong["artist"] as? [String:AnyObject])!["name"] as? String {
            song.artistName = artistName
        }
        if let url = parsedSong["url"] as? String {
            song.url = url
        }
        if let desc = parsedSong["desc"] as? String {
            song.description = desc
        }
        if let imageURL = parsedSong["image"] as? String {
            song.imageURL = imageURL
        }
        if let durationDesc = parsedSong["durationDesc"] as? String {
            song.durationDesc = durationDesc
        }
        if let playsCount = parsedSong["playsCount"] as? Int {
            song.playsCount = playsCount
        }
        if let likesCount = parsedSong["likesCount"] as? Int {
            song.likesCount = likesCount
        }
        
        // Return
        return song
    }
    
}