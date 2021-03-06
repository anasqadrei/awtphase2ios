
//
//  ArtistViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/04/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import iOSLogEntries

class ArtistViewController: UITableViewController {
    
    var artist: Artist!
    var songsList = [Song]()
    
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    let defaultSort = "-playsCount"
    
    let gaScreenCategory = "Artist"
    var gaScreenID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set VC data
        gaScreenID = "\(artist.id)/\(artist.name)"
        navigationItem.title = artist.name
        totalPages = artist.totalSongsPages

        // Get first page of songs
        if !fetching {
            getSongsList(1, sort: defaultSort)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Google Analytics - Screen View
        let name = "\(gaScreenCategory): \(gaScreenID!)"
        GoogleAnalyticsManager.screenView(name: name)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // For scrolling purposes, fetch more songs if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 5 songs
        if !fetching && lastFetchedPage < totalPages && indexPath.row >= songsList.count - 5 {
            getSongsList(lastFetchedPage + 1, sort: defaultSort)
        }
        
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.configure(songsList[indexPath.row])
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Assign the song of the destination VC
        if segue.identifier == "ArtistToSong", let songCell = sender as! SongTableViewCell? {
            let songVC = segue.destination as! SongViewController
            songVC.song = songCell.song
        }
    }

    @IBAction func share(_ sender: UIBarButtonItem) {
        // Google Analytics - Event
        GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Share", label: gaScreenID)
        
        // Share artist URL
        if let url = artist.url {
            let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            shareVC.popoverPresentationController?.barButtonItem = sender
            self.present(shareVC, animated: true, completion: nil)
        } else {
            LELog.log("\(self) share(): Artist \(artist.id) doesn't have a url." as NSObject!)
        }
    }
    
    fileprivate func getSongsList(_ page: Int, sort: String) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let url = "\(Constants.URLs.Host)/song/list"
        let parameters = [
            "artist": "\(artist.id)",
            "page": "\(page)",
            "pagesize": "\(artist.songsPageSize)",
            "sort": "\(sort)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedSongsList = response.result.value as? [[String:AnyObject]] else {
                    LELog.log("\(self) Artist \(self.artist.id) getSongsList(\(page),\(sort)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // Fill the self.songsList
                for parsedSong in parsedSongsList {
                    
                    // Append to self.songsList
                    if let song = Song.createSong(parsedSong) {
                        self.songsList.append(song)
                    } else {
                        LELog.log("\(self) Artist \(self.artist.id) getSongsList(\(page),\(sort)): A song couldn't be serialized." as NSObject!)
                    }
                }
                
                // Set song page related values
                self.lastFetchedPage = page
                
                // Reload data and finish
                self.tableView?.reloadData()
                self.configureUI(false)
        }
    }

    fileprivate func configureUI(_ busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.shared.isNetworkActivityIndicatorVisible = busy
    }
}

    
