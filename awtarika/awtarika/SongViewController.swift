//
//  SongViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 13/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import GoogleMobileAds
import ActiveLabel

class SongViewController: UIViewController {

    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var playerButton: UIButton!
    @IBOutlet weak var songDescription: ActiveLabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var playsCount: UILabel!
    @IBOutlet weak var likesCount: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var adBannerView: GADBannerView!

    var request: Request?
    var song: Song!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set VC data
        navigationItem.title = song.title
        songTitle.text = song.title
        if song.artistName != nil {
            artistName.text = song.artistName!
        } else {
            artistName.text = ""
        }
        if song.description != nil {
            // Custom hashtags to allow special chars in the string. Default hashtag doesn't allow symbols.
            let customHashtag = ActiveType.Custom(pattern: "#(\\S+)")
            songDescription.enabledTypes = [customHashtag]
            songDescription.customColor[customHashtag] = songDescription.hashtagColor
            songDescription.customSelectedColor[customHashtag] = songDescription.hashtagSelectedColor
            songDescription.handleCustomTap(for: customHashtag) { element in
                // Segue to the hashtag VC on click
                let hashtagVC = self.storyboard?.instantiateViewControllerWithIdentifier("HashtagView") as! HashtagTableViewController
                hashtagVC.hashtag = element
                self.navigationController?.pushViewController(hashtagVC, animated: true)
            }
            
            // Assign text after
            songDescription.text = song.description!
        } else {
            songDescription.text = ""
        }
        playsCount.text = "▶️ \(song.playsCount)"
        likesCount.text = "👍 \(song.likesCount)"
        if song.durationDesc != nil {
            duration.text = "🕓 \(song.durationDesc!)"
        } else {
            duration.text = ""
        }
        if song.imageURL != nil {
            showImage()
        }
        
        // Ad
        adBannerView.adUnitID = Constants.AdMob.SongScreenAdUnitID
        adBannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kDFPSimulatorID, Constants.AdMob.TestDeviceAnasIPhone4S]
        adBannerView.loadRequest(request)
    }
    
    @IBAction func share(sender: AnyObject) {
        // Share song URL
        if let url = song.url {
            let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self.presentViewController(shareVC, animated: true, completion: nil)
        } else {
            print("how come song \(song.id) doesn't have a url")
        }
        
    }

    @IBAction func showPlayer(sender: AnyObject) {
        // Show popup player VC
        let popupContentVC = storyboard?.instantiateViewControllerWithIdentifier("PlayerView") as! PlayerViewController
        popupContentVC.song = song
        navigationController?.presentPopupBarWithContentViewController(popupContentVC, animated: true, completion: nil)
    }
    
    private func showImage() {
        // GUARD: Does song have an image?
        guard let imageURL = song.imageURL else {
            return
        }
        
        // Reset any other request
        request?.cancel()
        
        // Is that image cached?
        if let image = PhotosDataManager.sharedManager.cachedImage(imageURL) {
            // Then show it (and update song image. not sure if this step is needed)
            songImage.image = image
            song.image = image
        } else {
            // Else download image if not cached
            request = PhotosDataManager.sharedManager.getNetworkImage(imageURL) { image in
                // Show new downloaded image and set song image
                self.songImage.image = image
                self.song.image = image
            }
        }
    }
    
}
