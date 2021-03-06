//
//  ArtistsListViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 12/04/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import iOSLogEntries

class ArtistsListViewController: UICollectionViewController {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var artistsList = [Artist]()
    
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    let defaultSort = "-songsCount"
    
    let gaScreenCategory = "Artists List"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get first page of artists
        if !fetching {
            getArtistsList(1, sort: defaultSort)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Google Analytics - Screen View
        GoogleAnalyticsManager.screenView(name: gaScreenCategory)
    }
    
    override func viewDidLayoutSubviews() {
        // Based on the equation: width = cols * item + ((cols - 1) * spacing)
        // Aspect ratio for cell is 5:6 (150:180)
        // Always set storyboardWidth = cell width at storyboard
        let storyboardWidth: CGFloat = 100
        let cols = floor((view.frame.size.width + flowLayout.minimumInteritemSpacing)/(storyboardWidth + flowLayout.minimumInteritemSpacing))
        let itemWidth = (view.frame.size.width - (cols - 1) * flowLayout.minimumInteritemSpacing)/cols
        let itemHeight = itemWidth * (6.0/5.0)

        flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artistsList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // For scrolling purposes, fetch more artists if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 4 artists
        if !fetching && lastFetchedPage < totalPages && indexPath.row >= artistsList.count - 4 {
            getArtistsList(lastFetchedPage + 1, sort: defaultSort)
        }
        
        // Build the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArtistsCell", for: indexPath) as! ArtistsCollectionViewCell
        cell.configure(artistsList[indexPath.row])
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Assign the artist of the destination VC
        if segue.identifier == "ArtistsListToArtist", let artistCell = sender as! ArtistsCollectionViewCell? {
            let artistVC = segue.destination as! ArtistViewController
            artistVC.artist = artistCell.artist
        }
    }

    fileprivate func getArtistsList(_ page: Int, sort: String) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let url = "\(Constants.URLs.Host)/artists-list"
        let parameters = [
            "page": "\(page)",
            "sort": "\(sort)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value as? [String: Any] else {
                    LELog.log("\(self) getArtistsList(\(page),\(sort)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // GUARD: Are the "artistsList" and "totalPages" keys in our result?
                guard let parsedArtistsList = parsedResult["artistsList"] as? [[String:AnyObject]],
                    let totalPages = parsedResult["totalPages"] as? Int else {
                        LELog.log("\(self) getArtistsList(\(page),\(sort)): Couldn't find keys 'artistsList' and 'totalPages' in \(parsedResult)" as NSObject!)
                        self.configureUI(false)
                        return
                }
                
                // Fill the self.artistsList
                for parsedArtist in parsedArtistsList {
                    
                    // Append to self.songsList
                    if let artist = Artist.createArtist(parsedArtist) {
                        self.artistsList.append(artist)
                    } else {
                        LELog.log("\(self) getArtistsList(\(page),\(sort)): An artist couldn't be serialized." as NSObject!)
                    }
                }
                
                // Set artist page related values
                self.lastFetchedPage = page
                self.totalPages = totalPages
                
                // Reload data and finish
                self.collectionView?.reloadData()
                self.configureUI(false)
        }
    }
    
    fileprivate func configureUI(_ busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.shared.isNetworkActivityIndicatorVisible = busy
    }
}
