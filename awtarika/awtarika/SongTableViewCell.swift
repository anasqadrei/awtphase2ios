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

    func configure(song: Song) {
        self.song = song
        
        // Fill data
        title.text = self.song.title!
        duration.text = "🕓 \(self.song.durationDesc!)"
        plays.text = "▶️ \(self.song.playsCount!)"
    }
    
    @IBAction func play(sender: UIButton) {
        print("\(self.song.title)")
    }
}
