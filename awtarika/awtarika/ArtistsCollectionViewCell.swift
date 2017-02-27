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
    @IBOutlet weak var imageView: UIImageView!
    
    var artist: Artist!
    var request: Request?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Circular image at layout updates
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.clipsToBounds = true
    }

    func configure(_ artist: Artist) {
        // Save the artist in the cell to be passed later on to artist VC
        self.artist = artist
        
        // Fill data
        reset()
        populate()
    }
    
    fileprivate func reset() {
        // Clear visuals and cancel request if there are anything pending by cell reusability
        name.text = nil
        imageView.image = nil
        request?.cancel()
    }
    
    fileprivate func populate() {
        // First set the artist name
        name.text = artist.name

        // GUARD: Does artist have an image?
        guard let imageURL = artist.imageURL else {
            return
        }

        // Is that image cached?
        if let image = PhotosDataManager.sharedManager.cachedImage(imageURL) {
            // Then show it
            imageView.image = image
        } else {
            // Else download image if not cached
            request = PhotosDataManager.sharedManager.getNetworkImage(imageURL) { image in
                // Show new downloaded image
                self.imageView.image = image
            }
        }
    }

}
