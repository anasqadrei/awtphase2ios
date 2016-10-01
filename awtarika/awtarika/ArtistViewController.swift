
//
//  ArtistViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 14/04/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire

class ArtistViewController: UITableViewController {
    
    var artist: Artist!
    var songsList = [Song]()
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    let defaultSort = "-playsCount"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set VC data
        navigationItem.title = artist.name
        totalPages = artist.totalSongsPages

        // Get first page of songs
        if !fetching {
            getSongsList(1, sort: defaultSort)
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
            getSongsList(lastFetchedPage + 1, sort: defaultSort)
        }
        
        // Build the cell
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell")! as! SongTableViewCell
        cell.configure(songsList[indexPath.row])
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Assign the song of the destination VC
        if segue.identifier == "Song", let songCell = sender as! SongTableViewCell? {
            let songVC = segue.destinationViewController as! SongViewController
            songVC.song = songCell.song
        }
    }

    private func getSongsList(page: Int, sort: String) {
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
        Alamofire.request(.GET, url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedSongsList = response.result.value as? [[String:AnyObject]] else {
                    print("couldn't serialize response")
                    self.configureUI(false)
                    return
                }
                
                // Fill the self.songsList
                for parsedSong in parsedSongsList {
                    
                    // GUARD: Is the song "_id" and "title" keys in our result?
                    guard let id = parsedSong["_id"] as? Int, title = parsedSong["title"] as? String else {
                        // Skip that song
                        continue
                    }
                    
                    // Fill song data
                    let song = Song(id: id, title: title)
                    
                    if let artistName = (parsedSong["artist"] as? [String:AnyObject])!["name"] as? String {
                        song.artistName = artistName
                    }
                    if let url = parsedSong["url"] as? String {
                        song.url = url
                    }
                    if let desc = parsedSong["desc"] as? String {
                        song.description = desc
                    }
                    if let imageURL = parsedSong["image"] as? String {
                        song.imageURL = imageURL
                    }
                    if let durationDesc = parsedSong["durationDesc"] as? String {
                        song.durationDesc = durationDesc
                    }
                    if let playsCount = parsedSong["playsCount"] as? Int {
                        song.playsCount = playsCount
                    }
                    if let likesCount = parsedSong["likesCount"] as? Int {
                        song.likesCount = likesCount
                    }
                    
                    // Append to self.songsList
                    self.songsList.append(song)
                }
                
                // Set song page related values
                self.lastFetchedPage = page
                
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

    