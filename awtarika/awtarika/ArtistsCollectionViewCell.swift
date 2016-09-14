//
//  ArtistsCollectionViewCell.swift
//  awtarika
//
//  Created by Anas Qadrei on 22/08/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire

class ArtistsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    var request: Request?
    var artist: Artist!
  
    func configure(artist: Artist) {
        self.artist = artist
        
        // Fill data
        reset()
        populate()
    }
    
    func reset() {
        // Clear visuals and cancel request if there are anything pending by cell reusability
        name.text = nil
        image.image = nil
        request?.cancel()
    }
    
    func populate() {
        // First set the artist name
        self.name.text = self.artist.name!

        // GUARD: Does artist have an image?
        guard let imageURL = self.artist.imageURL else {
            return
        }

        // Is that image cached?
        if let image = PhotosDataManager.sharedManager.cachedImage(imageURL) {
            // Then show it
            self.image.image = image
        } else {
            // Else download image if not cached
            request = PhotosDataManager.sharedManager.getNetworkImage(imageURL) { image in
                // Show new downloaded image
                self.image.image = image
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Circular image at layout updates
        self.image.layer.cornerRadius = self.image.frame.size.width/2
        self.image.clipsToBounds = true
    }
}
