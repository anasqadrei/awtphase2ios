//
//  DetailedSongTableViewCell.swift
//  awtarika
//
//  Created by Anas Qadrei on 3/10/16.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit

class DetailedSongTableViewCell: SongTableViewCell {

    @IBOutlet weak var artistName: UILabel!

    override func configure(_ song: Song) {
        super.configure(song)
        
        // Fill extra details (artist name)
        artistName.text = song.artistName
    }
}
