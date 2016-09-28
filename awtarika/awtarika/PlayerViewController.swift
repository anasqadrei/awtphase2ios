//
//  PlayerViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import LNPopupController
import KDEAudioPlayer

class PlayerViewController: UIViewController, AudioPlayerDelegate {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var togglePlayPauseButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    var play: UIBarButtonItem!
    var pause: UIBarButtonItem!
    var stop: UIBarButtonItem!
    var spinner: UIBarButtonItem!

//    let audioPlayer = AudioPlayer()
    let audioPlayer = (UIApplication.sharedApplication().delegate as! AppDelegate).audioPlayer
    

    var song: Song? {
        didSet {
            popupItem.title = song!.title
            popupItem.subtitle = song!.artistName
            
            playSong()
        }
    }
    
    @IBAction func togglePlayPause(sender: AnyObject) {

        //
        switch audioPlayer.state {
        case .Stopped, .Paused:
            playSong()
        case .Playing:
            audioPlayer.pause()
        case .Failed(AudioPlayerError.FoundationError(nil)):
            dismissVC()
        default:
            return
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        audioPlayer.delegate = self
        
        LNPopupBar.appearanceWhenContainedInInstancesOfClasses([UINavigationController.self]).barStyle = .Black
        
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.startAnimating()
        spinner = UIBarButtonItem(customView: activityIndicatorView)
        
        play = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: #selector(playSong))
        play.accessibilityLabel = NSLocalizedString("Play", comment: "")
        
        pause = UIBarButtonItem(barButtonSystemItem: .Pause, target: audioPlayer, action: #selector(audioPlayer.pause))
        pause.accessibilityLabel = NSLocalizedString("Pause", comment: "")
        
        stop = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(dismissVC))
        stop.accessibilityLabel = NSLocalizedString("Error", comment: "")
    }
    
    func dismissVC() {
        popupPresentationContainerViewController?.dismissPopupBarAnimated(true, completion: nil)
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
                    
                    //
//                    let NSSongURL = NSURL(string: songURL)!
                    
                    //local
                    let NSSongURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Havana Express - Gangstas Paradise (Salsa Version).mp3", ofType:nil)!)
                    
                    let item = AudioItem(mediumQualitySoundURL: NSSongURL)
                    item?.title = self.song!.title
                    item?.artist = self.song!.artistName
                    self.audioPlayer.playItem(item!)
                    
                    //??
                    self.volumeSlider.value = self.audioPlayer.volume
                }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        songTitleLabel.text = song!.title
        artistNameLabel.text = song!.artistName
        if let image = song?.image {
            songImage.image = image
        }
        
   
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
//        print("from \(from) to \(to)")
        
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
            togglePlayPauseButton.setImage(UIImage(named: "playerPlay"), forState: .Normal)
        }
        
        // show pause
        if to == .Playing {
            popupItem.leftBarButtonItems = [ pause ]
            togglePlayPauseButton.setImage(UIImage(named: "playerPause"), forState: .Normal)
        }
        
        // show stop/error
        if to == .Failed(AudioPlayerError.FoundationError(nil)) {
            popupItem.leftBarButtonItems = [ stop ]
            togglePlayPauseButton.setImage(UIImage(named: "playerClose"), forState: .Normal)
        }
        
        // dismiss at end
        if from == .Playing && to == .Stopped {
            dismissVC()
        }
    }
    
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {
        popupItem.progress = percentageRead/100.0
        if isViewLoaded() {
            progressView.progress = percentageRead/100.0
        }
    }

    @IBAction func volumeChange(sender: AnyObject) {
        audioPlayer.volume = volumeSlider.value
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
