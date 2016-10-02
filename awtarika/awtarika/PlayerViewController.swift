//
//  PlayerViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import GoogleMobileAds
import LNPopupController
import KDEAudioPlayer

class PlayerViewController: UIViewController, AudioPlayerDelegate {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressTime: UILabel!
    @IBOutlet weak var remainingTime: UILabel!
    @IBOutlet weak var togglePlayPauseButton: UIButton!
    @IBOutlet weak var adBannerView: GADBannerView!
    
    let audioPlayer = (UIApplication.sharedApplication().delegate as! AppDelegate).audioPlayer
    
    var play: UIBarButtonItem!
    var pause: UIBarButtonItem!
    var stop: UIBarButtonItem!
    var spinner: UIBarButtonItem!

    var song: Song! {
        didSet {
            popupItem.title = song!.title
            popupItem.subtitle = song!.artistName
            
            playSong()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        audioPlayer.delegate = self

        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).barStyle = .Black
        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16)]
        
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        spinner = UIBarButtonItem(customView: activityIndicatorView)
        
        play = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: #selector(playSong))
        play.accessibilityLabel = NSLocalizedString("Play", comment: "")
        
        pause = UIBarButtonItem(barButtonSystemItem: .Pause, target: audioPlayer, action: #selector(audioPlayer.pause))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        stop = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(dismissVC))
        stop.accessibilityLabel = NSLocalizedString("Close", comment: "")
        popupItem.rightBarButtonItems = [ stop ]
    }
    
    override func viewWillAppear(animated: Bool) {
        //
        songTitleLabel.text = song.title
        if song.artistName != nil {
            artistNameLabel.text = song.artistName!
        } else {
            artistNameLabel.text = ""
        }
        if song.durationDesc != nil {
            remainingTime.text = song.durationDesc!
        } else {
            remainingTime.text = ""
        }
        if song.image != nil {
            songImage.image = song.image
        }
        // Mainly to init the progress in case of loading error
        progressView.progress = popupItem.progress
        
        // Ad
        adBannerView.adUnitID = Constants.AdMob.PlayerScreenAdUnitID
        adBannerView.rootViewController = self
        let adRequest = GADRequest()
        adRequest.testDevices = [kDFPSimulatorID, Constants.AdMob.TestDeviceAnasIPhone4S]
        adBannerView.loadRequest(adRequest)
    }

    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        
        // now buffering
        if to == .Buffering || to == .WaitingForConnection {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]
        }
        
        // end buffering
        if from == .Buffering || from == .WaitingForConnection {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        // show play
        if to == .Stopped || to == .Paused {
            popupItem.leftBarButtonItems = [ play ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), forState: .Normal)
            }
        }
        
        // show pause
        if to == .Playing {
            popupItem.leftBarButtonItems = [ pause ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerPause"), forState: .Normal)
            }
        }
        
        // show stop/error
        if to == .Failed(AudioPlayerError.FoundationError(nil)) {
            popupItem.rightBarButtonItems = [  ]
            popupItem.leftBarButtonItems = [ stop ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerClose"), forState: .Normal)
            }
        }
        
        // dismiss at end
        if from == .Playing && to == .Stopped {
            dismissVC()
        }
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {
        popupItem.progress = percentageRead/100.0
        if isViewLoaded() {
            progressView.progress = popupItem.progress
            progressTime.text = stringFromTimeInterval(round(time))
            if audioPlayer.currentItemDuration != nil {
                remainingTime.text = "-" + stringFromTimeInterval(round(audioPlayer.currentItemDuration!) - round(time))
            } else {
                remainingTime.text = ""
            }
        }
    }

    @IBAction func togglePlayPause(sender: AnyObject) {
        //
        switch audioPlayer.state {
        case .Stopped, .Paused:
            playSong()
        case .Playing:
            audioPlayer.pause()
        case .Failed(AudioPlayerError.FoundationError(_)):
            dismissVC()
        default:
            return
        }
    }
    
    func playSong() {
        
        if audioPlayer.state == .Paused {
            audioPlayer.resume()
        } else {
            
            //
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]
            
            // reset ?
      
            // Create request
            let url = "\(Constants.URLs.Host)/song/play"
            let parameters = [
                "songId": "\(song.id)"
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
                    
                    //
//                    let NSSongURL = NSURL(string: songURL)!
                    
                    //local
                    let NSSongURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Havana Express - Gangstas Paradise (Salsa Version).mp3", ofType:nil)!)
                    
                    let item = AudioItem(mediumQualitySoundURL: NSSongURL)
                    item?.title = self.song.title
                    if let artistName = self.song.artistName {
                        item?.artist = artistName
                    }
                    if let image = self.song.image {
                        item?.artworkImage = image
                    }
                    //play
                    self.audioPlayer.playItem(item!)     
                }
        }
    }
    
    func dismissVC() {
        audioPlayer.stop()
        if (audioPlayer.items != nil) {
            audioPlayer.removeItemAtIndex(0)    //remove the only item to save bandwidth?
        }
        popupPresentationContainerViewController?.dismissPopupBarAnimated(true, completion: nil)
    }

    func stringFromTimeInterval(interval:NSTimeInterval) -> String {
        //
        let ti = Int(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        if hours == 0 {
            return String(format: "%d:%0.2d",minutes,seconds)
        } else {
            return String(format: "%d:%0.2d:%0.2d",hours,minutes,seconds)
        }
    }
}
