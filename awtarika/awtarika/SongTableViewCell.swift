//
//  SongTableViewCell.swift
//  awtarika
//
//  Created by Anas Qadrei on 30/08/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var plays: UILabel!
    
    var song: Song!

    func configure(_ song: Song) {
        // Save the song in the cell to be passed later on to song VC
        self.song = song
        
        // Fill data
        title.text = song.title
        plays.text = "▶️ \(song.playsCount)"
        if let durationStr = song.durationDesc {
            duration.text = "🕓 \(durationStr)"
        }
    }
    
}
