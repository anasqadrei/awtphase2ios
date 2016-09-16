//
//  PlayerViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import LNPopupController
import Alamofire
import AVFoundation

class PlayerViewController: UIViewController {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!

    var audioPlayer: AVPlayer!

    var song: Song? {
        didSet {
            popupItem.title = song!.title
            popupItem.subtitle = song!.artistName
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).barStyle = .Black
        
        let pause = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: #selector(togglePlayPause))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        let play = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: #selector(togglePlayPause))
        play.accessibilityLabel = NSLocalizedString("Play", comment: "")
        
        popupItem.leftBarButtonItems = [ pause ]
    }
    
    func togglePlayPause() {
//        if (audioPlayer.status) {
            audioPlayer.play()
//
//            pausePlayButton.setTitle("Pause", forState: UIControlState.Normal)
//            popupItem.leftBarButtonItems = [ pause ]
//            
//            
//        } else {
//            audioPlayer.pause()
//            
//            pausePlayButton.setTitle("Play", forState: UIControlState.Normal)
//            popupItem.leftBarButtonItems = [ play ]
//            
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        songTitleLabel.text = song!.title
        artistNameLabel.text = song!.artistName

        // Create request
        let url = "\(Constants.URLs.Host)/song/play"
        let parameters = [
            "songId": "\(song!.id!)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(.GET, url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value else {
                    print("couldn't serialize response")
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    return
                }
                
                // GUARD: Are the "photos" and "photo" keys in our result?
                guard let songURL = parsedResult["url"] as? String else {
                    print("Cannot find keys 'url' in \(parsedResult)")
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    return
                }

                self.audioPlayer = AVPlayer(URL: NSURL(string: songURL)!)
                self.togglePlayPause()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
