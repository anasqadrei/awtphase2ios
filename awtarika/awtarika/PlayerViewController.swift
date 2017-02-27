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
    
    let audioPlayer = (UIApplication.shared.delegate as! AppDelegate).audioPlayer
    
    var play: UIBarButtonItem!
    var pause: UIBarButtonItem!
    var stop: UIBarButtonItem!
    var spinner: UIBarButtonItem!

    let gaScreenCategory = "Player"
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
        LNPopupBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).barStyle = .black
        LNPopupBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 16)]
        
        // Prepare bar buttons
        // Spinner
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        spinner = UIBarButtonItem(customView: activityIndicatorView)
        
        // Play
        play = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(barActionPlay))
        play.accessibilityLabel = NSLocalizedString("Play", comment: "")
        
        // Pause
        pause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(barActionPause))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        // Close
        stop = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(barActionClose))
        stop.accessibilityLabel = NSLocalizedString("Close", comment: "")
        popupItem.rightBarButtonItems = [ stop ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        case .playing:
            togglePlayPauseButton.setImage(UIImage(named: "playerPause"), for: UIControlState())
        case .paused, .stopped:
            togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), for: UIControlState())
        case .failed(AudioPlayerError.foundationError(_)):
            togglePlayPauseButton.setImage(UIImage(named: "playerClose"), for: UIControlState())
        default:
            break
        }

        // Ad
        adBannerView.adUnitID = Constants.AdMob.PlayerScreenAdUnitID
        adBannerView.rootViewController = self
        let adRequest = GADRequest()
        adRequest.testDevices = [kDFPSimulatorID, Constants.AdMob.TestDeviceAnasIPhone4S]
        adBannerView.load(adRequest)
        
        // Google Analytics - Screen View
        let name = "\(gaScreenCategory): \(gaScreenID!)"
        GoogleAnalyticsManager.screenView(name: name)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioItem) {
        // Increment counters when the song is to be played.
        let url = "\(Constants.URLs.Host)/song/play"
        let parameters = [
            "songId": "\(song.id)",
            "artistId": "\(song.artistID)"
        ]
        let headers = ["Accept": "application/json"]
        
        print("here")
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                // result of the call doesn't matter much
        }
       
        // Update local counter
        song.playsCount += 1
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        // Show that it is buffering
        if state == .buffering || state == .waitingForConnection {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]
        }
        
        // Hide network activity when bufferings ends. Play or pause will be displayed depending on the "to" state
        if from == .buffering || from == .waitingForConnection {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        // Show play button on bar and popup if loaded
        if state == .stopped || state == .paused {
            popupItem.leftBarButtonItems = [ play ]
            if isViewLoaded {
                togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), for: UIControlState())
            }
        }
        
        // Show pause button on bar and popup if loaded
        if state == .playing {
            popupItem.leftBarButtonItems = [ pause ]
            if isViewLoaded {
                togglePlayPauseButton.setImage(UIImage(named: "playerPause"), for: UIControlState())
            }
        }
        
        // Show stop/error button on bar and popup if loaded
        if case .failed = state {
            popupItem.rightBarButtonItems = [  ]
            popupItem.leftBarButtonItems = [ stop ]
            if isViewLoaded {
                togglePlayPauseButton.setImage(UIImage(named: "playerClose"), for: UIControlState())
            }
        }
        
        // Dismiss player when song playing comes to an end
        if from == .playing && state == .stopped {
            dismissVC()
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        // Update progress on bar
        popupItem.progress = percentageRead/100.0
        
        if isViewLoaded {
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

    @IBAction func togglePlayPause(_ sender: AnyObject) {
        // Play, Pause, or Close depending on the player state. Showing the correct button is at delegate method
        switch audioPlayer.state {

        case .stopped, .paused:
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Play - Popup", label: gaScreenID)
            
            // If current state is paused then play
            playSong()
            
        case .playing:
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Pause - Popup", label: gaScreenID)
            
            // If current state is playing then pause
            audioPlayer.pause()
            
        case .failed(AudioPlayerError.foundationError(_)):
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
        if audioPlayer.state == .paused {
            audioPlayer.resume()
        } else {
            
            // Show that it's busy loading the song
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            popupItem.leftBarButtonItems = [ spinner ]

            // Create request to get the temporary song URL
            let url = "\(Constants.URLs.Host)/song/play"
            let parameters = [
                "songId": "\(song.id)"
            ]
            let headers = ["Accept": "application/json"]
            Alamofire.request(url, method: .get, parameters: parameters, headers: headers)
                .validate()
                .responseJSON { response in
                    
                    // GUARD: Data parsed to JSON?
                    guard let parsedResult = response.result.value as? [String: Any] else {
                        LELog.log("\(self) playSong(\(self.song.id)): Couldn't serialize response." as NSObject!)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return
                    }
                    
                    // GUARD: Are the "photos" and "photo" keys in our result?
                    guard var songURL = URL(string: (parsedResult["url"] as? String)!) else {
                        LELog.log("\(self) playSong(\(self.song.id)): Couldn't find key 'url' in \(parsedResult)" as NSObject!)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        return
                    }
                    
                    // Local URL for testing purposes
                    songURL = URL(fileURLWithPath: Bundle.main.path(forResource: "Mediterranean Breeze.mp3", ofType:nil)!)
              
                    // Set the audioPlayer item with the song URL and data
                    let item = AudioItem(mediumQualitySoundURL: songURL)
                    item?.title = self.song.title
                    item?.artist = self.song.artistName
                    if let image = self.song.image {
                        item?.artworkImage = image
                    } else {
                        item?.artworkImage = nil
                    }
                    
                    // Play
                    self.audioPlayer.play(item: item!)
                }
        }
    }

    func dismissVC() {
        // Stop song from playing
        audioPlayer.stop()
        
        // Remove the only item to save bandwidth (wasn't really tested)
        if (audioPlayer.items != nil) {
            audioPlayer.removeItem(at: 0)
        }
        
        // Dismiss VC
        popupPresentationContainer?.dismissPopupBar(animated: true, completion: nil)
    }

    func stringFromTimeInterval(_ interval:TimeInterval) -> String {
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
