//
//  HashtagTableViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 3/10/16.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import iOSLogEntries

class HashtagTableViewController: UITableViewController {

    var hashtag: String!
    var songsList = [Song]()
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set VC data
        navigationItem.title = hashtag
      
        // Get first page of songs
        if !fetching {
            getSongsList(1)
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songsList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // For scrolling purposes, fetch more songs if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 5 songs
        if !fetching && lastFetchedPage < totalPages && indexPath.row >= songsList.count - 5 {
            getSongsList(lastFetchedPage + 1)
        }
        
        // Build the cell
        let cell = tableView.dequeueReusableCellWithIdentifier("DetailedSongCell", forIndexPath: indexPath) as! DetailedSongTableViewCell
        cell.configure(songsList[indexPath.row])
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Assign the song of the destination VC
        if segue.identifier == "HashtagToSong", let songCell = sender as! DetailedSongTableViewCell? {
            let songVC = segue.destinationViewController as! SongViewController
            songVC.song = songCell.song
        }
    }
    
    private func getSongsList(page: Int) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let hashtagText = hashtag.stringByReplacingOccurrencesOfString("#", withString: "")
        let encodedHashtag = hashtagText.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let url = "\(Constants.URLs.Host)/hashtag/\(encodedHashtag)"
        let parameters = [
            "page": "\(page)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(.GET, url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in

                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value else {
                    LELog.log("\(self) getSongsList(\(page)): Couldn't serialize response.")
                    self.configureUI(false)
                    return
                }
                
                // GUARD: Are the "photos" and "photo" keys in our result?
                guard let parsedSongsList = parsedResult["songsList"] as? [[String:AnyObject]],
                    totalPages = parsedResult["totalPages"] as? Int else {
                        LELog.log("\(self) getSongsList(\(page)): Couldn't find keys 'songsList' and 'totalPages' in \(parsedResult)")
                        self.configureUI(false)
                        return
                }
                
                // Fill the self.songsList
                for parsedSong in parsedSongsList {
                    
                    // Append to self.songsList
                    if let song = Song.createSong(parsedSong) {
                        self.songsList.append(song)
                    }
                }
                
                // Set song page related values
                self.lastFetchedPage = page
                self.totalPages = totalPages
                
                // Reload data and finish
                self.tableView?.reloadData()
                self.configureUI(false)
        }
    }
    
    private func configureUI(busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.sharedApplication().networkActivityIndicatorVisible = busy
    }

}
