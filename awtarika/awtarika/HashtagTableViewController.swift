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
    
    let gaScreenCategory = "Hashtag"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set VC data
        navigationItem.title = hashtag
      
        // Get first page of songs
        if !fetching {
            getSongsList(1)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Google Analytics - Screen View
        let name = "\(gaScreenCategory): \(hashtag!)"
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
            getSongsList(lastFetchedPage + 1)
        }
        
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailedSongCell", for: indexPath) as! DetailedSongTableViewCell
        cell.configure(songsList[indexPath.row])
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Assign the song of the destination VC
        if segue.identifier == "HashtagToSong", let songCell = sender as! DetailedSongTableViewCell? {
            let songVC = segue.destination as! SongViewController
            songVC.song = songCell.song
        }
    }
    
    fileprivate func getSongsList(_ page: Int) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let hashtagText = hashtag.replacingOccurrences(of: "#", with: "")
        let encodedHashtag = hashtagText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = "\(Constants.URLs.Host)/hashtag/\(encodedHashtag)"
        let parameters = [
            "page": "\(page)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in

                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value as? [String: Any] else {
                    LELog.log("\(self) Hashtag \(self.hashtag) getSongsList(\(page)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // GUARD: Are the "songsList" and "totalPages" keys in our result?
                guard let parsedSongsList = parsedResult["songsList"] as? [[String:AnyObject]],
                    let totalPages = parsedResult["totalPages"] as? Int else {
                        LELog.log("\(self) Hashtag \(self.hashtag) getSongsList(\(page)): Couldn't find keys 'songsList' and 'totalPages' in \(parsedResult)" as NSObject!)
                        self.configureUI(false)
                        return
                }
                
                // Fill the self.songsList
                for parsedSong in parsedSongsList {
                    
                    // Append to self.songsList
                    if let song = Song.createSong(parsedSong) {
                        self.songsList.append(song)
                    } else {
                        LELog.log("\(self) Hashtag \(self.hashtag) getSongsList(\(page)): A song couldn't be serialized." as NSObject!)
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
    
    fileprivate func configureUI(_ busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.shared.isNetworkActivityIndicatorVisible = busy
    }

}
