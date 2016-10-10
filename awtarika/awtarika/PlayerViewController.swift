//
//  PlayerViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import iOSLogEntries
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

    var gaScreenCategory = "Player"
    var gaScreenID: String!
    
    var song: Song! {
        didSet {
            // Set google analytics song data
            gaScreenID = "\(song.id)/\(song.title) - \(song.artistName)"
            
            // Set popup bar song data
            popupItem.title = song!.title
            popupItem.subtitle = song!.artistName
            
            // Play the song immidiatly
            playSong()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Player implements audioPlayer protocol
        audioPlayer.delegate = self

        // Bar custom design
        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).barStyle = .Black
        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16)]
        
        // Prepare bar buttons
        // Spinner
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        spinner = UIBarButtonItem(customView: activityIndicatorView)
        
        // Play
        play = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: #selector(barActionPlay))
        play.accessibilityLabel = NSLocalizedString("Play", comment: "")
        
        // Pause
        pause = UIBarButtonItem(barButtonSystemItem: .Pause, target: self, action: #selector(barActionPause))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        // Close
        stop = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(barActionClose))
        stop.accessibilityLabel = NSLocalizedString("Close", comment: "")
        popupItem.rightBarButtonItems = [ stop ]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        // Set the song data when popup will appear
        songTitleLabel.text = song.title
        artistNameLabel.text = song.artistName
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
        
        // Show correct button depending on the player state. It has to be done here as well as in the change state method for the correct initial view
        switch audioPlayer.state {
        case .Playing:
            togglePlayPauseButton.setImage(UIImage(named: "playerPause"), forState: .Normal)
        case .Paused, .Stopped:
            togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), forState: .Normal)
        case .Failed(AudioPlayerError.FoundationError(_)):
            togglePlayPauseButton.setImage(UIImage(named: "playerClose"), forState: .Normal)
        default:
            break
        }

        // Ad
        adBannerView.adUnitID = Constants.AdMob.PlayerScreenAdUnitID
        adBannerView.rootViewController = self
        let adRequest = GADRequest()
        adRequest.testDevices = [kDFPSimulatorID, Constants.AdMob.TestDeviceAnasIPhone4S]
        adBannerView.loadRequest(adRequest)
        
        // Google Analytics - Screen View
        let name = "\(gaScreenCategory): \(gaScreenID)"
        GoogleAnalyticsManager.screenView(name: name)
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {
        // Increment counters when the song is to be played.
        let url = "\(Constants.URLs.Host)/song/play"
        let parameters = [
            "songId": "\(song.id)",
            "artistId": "\(song.artistID)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(.POST, url, parameters: parameters, headers: headers, encoding: .JSON)
        
        // Update local counter
        song.playsCount += 1
    }

    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        // Show that it is buffering
        if to == .Buffering || to == .WaitingForConnection {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]
        }
        
        // Hide network activity when bufferings ends. Play or pause will be displayed depending on the "to" state
        if from == .Buffering || from == .WaitingForConnection {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        // Show play button on bar and popup if loaded
        if to == .Stopped || to == .Paused {
            popupItem.leftBarButtonItems = [ play ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), forState: .Normal)
            }
        }
        
        // Show pause button on bar and popup if loaded
        if to == .Playing {
            popupItem.leftBarButtonItems = [ pause ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerPause"), forState: .Normal)
            }
        }
        
        // Show stop/error button on bar and popup if loaded
        if to == .Failed(AudioPlayerError.FoundationError(nil)) {
            popupItem.rightBarButtonItems = [  ]
            popupItem.leftBarButtonItems = [ stop ]
            if isViewLoaded() {
                togglePlayPauseButton.setImage(UIImage(named: "playerClose"), forState: .Normal)
            }
        }
        
        // Dismiss player when song playing comes to an end
        if from == .Playing && to == .Stopped {
            dismissVC()
        }
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {
        // Update progress on bar
        popupItem.progress = percentageRead/100.0
        
        if isViewLoaded() {
            // Update progress on popup
            progressView.progress = popupItem.progress
            
            // Update progress and remaning times
            progressTime.text = stringFromTimeInterval(round(time))
            if audioPlayer.currentItemDuration != nil {
                remainingTime.text = "-" + stringFromTimeInterval(round(audioPlayer.currentItemDuration!) - round(time))
            } else {
                remainingTime.text = ""
            }
        }
    }

    @IBAction func togglePlayPause(sender: AnyObject) {
        // Play, Pause, or Close depending on the player state. Showing the correct button is at delegate method
        switch audioPlayer.state {

        case .Stopped, .Paused:
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Play - Popup", label: gaScreenID)
            
            // If current state is paused then play
            playSong()
            
        case .Playing:
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Pause - Popup", label: gaScreenID)
            
            // If current state is playing then pause
            audioPlayer.pause()
            
        case .Failed(AudioPlayerError.FoundationError(_)):
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Close - Popup", label: gaScreenID)
            
            // If error then dismiss
            dismissVC()
            
        default:
            // Do nothing in other states (Buffering, Waiting for connection, ...)
            return
        }
    }
    
    func barActionPlay() {
        // Google Analytics - Event
        GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Play - Bar", label: gaScreenID)
        
        // Play
        playSong()
    }
    
    func barActionPause() {
        // Google Analytics - Event
        GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Pause - Bar", label: gaScreenID)
        
        // Pause
        audioPlayer.pause()
    }
    
    func barActionClose() {
        // Google Analytics - Event
        GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Close - Bar", label: gaScreenID)
        
        // Dismiss Player
        dismissVC()
    }
    
    func playSong() {
        // If song is already loaded and paused then resume, otherwise load and play it
        if audioPlayer.state == .Paused {
            audioPlayer.resume()
        } else {
            
            // Show that it's busy loading the song
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]

            // Create request to get the temporary song URL
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
                        LELog.log("\(self) playSong(\(self.song.id)): Couldn't serialize response.")
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        return
                    }
                    
                    // GUARD: Are the "photos" and "photo" keys in our result?
                    guard let songURL = parsedResult["url"] as? String else {
                        LELog.log("\(self) playSong(\(self.song.id)): Couldn't find key 'url' in \(parsedResult)")
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        return
                    }

                    // Set the temporary song URL
                    let NSSongURL = NSURL(string: songURL)!

                    // Set the audioPlayer item with the song URL and data
                    let item = AudioItem(mediumQualitySoundURL: NSSongURL)
                    item?.title = self.song.title
                    item?.artist = self.song.artistName
                    if let image = self.song.image {
                        item?.artworkImage = image
                    } else {
                        item?.artworkImage = nil
                    }
                    
                    // Play
                    self.audioPlayer.playItem(item!)     
                }
        }
    }

    func dismissVC() {
        // Stop song from playing
        audioPlayer.stop()
        
        // Remove the only item to save bandwidth (wasn't really tested)
        if (audioPlayer.items != nil) {
            audioPlayer.removeItemAtIndex(0)
        }
        
        // Dismiss VC
        popupPresentationContainerViewController?.dismissPopupBarAnimated(true, completion: nil)
    }

    func stringFromTimeInterval(interval:NSTimeInterval) -> String {
        // Show time in human readable format
        let ti = Int(interval)
        
        // Calculate seconds, minutes, and hours
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        // Return string format of the time interval
        if hours == 0 {
            return String(format: "%d:%0.2d",minutes,seconds)
        } else {
            return String(format: "%d:%0.2d:%0.2d",hours,minutes,seconds)
        }
    }
}
