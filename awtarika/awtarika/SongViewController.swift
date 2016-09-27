//
//  SongViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 13/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire

class SongViewController: UIViewController {

    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var playerButton: UIButton!
    @IBOutlet weak var songDescription: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var playsCount: UILabel!
    @IBOutlet weak var likesCount: UILabel!

    var request: Request?
    var song: Song?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // GUARD: Song ID exists?
        guard let songId = song?.id else {
            print("song doesn't exist")
            return
        }
        
        // Set VC data
        songTitle.text = song!.title
        artistName.text = song!.artistName
        songDescription.text = song!.description
        playsCount.text = "▶️ \(song!.playsCount!)"
        likesCount.text = "👍 \(song!.likesCount!)"
        
        showImage()

    }
    
    func showImage() {
        // Reset any other request
        request?.cancel()
        
        // GUARD: Does song have an image?
        guard let imageURL = song?.imageURL else {
            return
        }
        
        // Is that image cached?
        if let image = PhotosDataManager.sharedManager.cachedImage(imageURL) {
            // Then show it
            self.songImage.image = image
        } else {
            // Else download image if not cached
            request = PhotosDataManager.sharedManager.getNetworkImage(imageURL) { image in
                // Show new downloaded image
                self.songImage.image = image
            }
        }
    }
    
    @IBAction func showPlayer(sender: AnyObject) {
        let popupContentVC = storyboard?.instantiateViewControllerWithIdentifier("PlayerViewController") as! PlayerViewController
        popupContentVC.song = song
        navigationController?.presentPopupBarWithContentViewController(popupContentVC, animated: true, completion: nil)
    }
    
}
