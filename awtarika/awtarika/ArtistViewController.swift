
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
    
    var artist: Artist?
    var songsList = [Song]()
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    let defaultSort = "-playsCount"
    
    private func configureUI(busy: Bool) {
        // Set UI and fetching to busy or not
        self.fetching = busy
        UIApplication.sharedApplication().networkActivityIndicatorVisible = busy
    }
    
    func getSongsList(page: Int, sort: String) {
        
        // GUARD: Artist ID exist?
        guard let artistId = artist?.id else {
            print("artist id doesn't exist")
            return
        }
        self.totalPages = artist!.totalSongsPages!

        // Set busy fetching
        configureUI(true)
        
        // Create request
        let url = "\(Constants.URLs.Host)/song/list"
        let parameters = [
            "artist": "\(artistId)",
            "page": "\(page)",
            "pagesize": "\(artist!.songsPageSize!)",
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // GUARD: Artist ID exist?
        guard let artistName = artist?.name else {
            print("artist name doesn't exist")
            return
        }
        
        // Set VC data
        self.navigationItem.title = artistName
        self.totalPages = artist!.totalSongsPages!

        // Get first page of songs
        if !self.fetching {
            getSongsList(1, sort: defaultSort)
        }
    }
    
    // ** Do I need it?
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songsList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Fetch more songs if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 5 songs
        if !self.fetching && self.lastFetchedPage < self.totalPages && indexPath.row >= self.songsList.count - 5 {
            getSongsList(self.lastFetchedPage + 1, sort: defaultSort)
        }
        
        // Get the cell
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell")! as! SongTableViewCell

        // Configure the cell
        cell.configure(self.songsList[indexPath.row])
      
        // Return
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Assign the song of the destination VC
        if segue.identifier == "Song", let songCell = sender as! SongTableViewCell? {
            let songVC = segue.destinationViewController as! SongViewController
            songVC.song = songCell.song
        }
    }
}

    