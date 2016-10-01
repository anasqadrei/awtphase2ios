//
//  ArtistsListViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 12/04/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire

class ArtistsListViewController: UICollectionViewController {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var artistsList = [Artist]()
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    let defaultSort = "-songsCount"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get first page of artists
        if !fetching {
            getArtistsList(1, sort: defaultSort)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Based on the equation: width = cols * item + ((cols - 1) * spacing)
        // Aspect ratio for cell is 5:6 (150:180)
        // Always set storyboardWidth = cell width at storyboard
        let storyboardWidth: CGFloat = 100
        let cols = floor((view.frame.size.width + flowLayout.minimumInteritemSpacing)/(storyboardWidth + flowLayout.minimumInteritemSpacing))
        let itemWidth = (view.frame.size.width - (cols - 1) * flowLayout.minimumInteritemSpacing)/cols
        let itemHeight = itemWidth * (6.0/5.0)

        flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight)
    }
    
//    // ** Do I really need it?
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        // Layout update if size changed
//        collectionView?.collectionViewLayout.invalidateLayout()
//    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artistsList.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // For scrolling purposes, fetch more artists if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 4 artists
        if !fetching && lastFetchedPage < totalPages && indexPath.row >= artistsList.count - 4 {
            getArtistsList(lastFetchedPage + 1, sort: defaultSort)
        }
        
        // Build the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ArtistsCell", forIndexPath: indexPath) as! ArtistsCollectionViewCell
        cell.configure(artistsList[indexPath.row])
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Assign the artist of the destination VC
        if segue.identifier == "Artist", let artistCell = sender as! ArtistsCollectionViewCell? {
            let artistVC = segue.destinationViewController as! ArtistViewController
            artistVC.artist = artistCell.artist
        }
    }

    private func getArtistsList(page: Int, sort: String) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let url = "\(Constants.URLs.Host)/artists-list"
        let parameters = [
            "page": "\(page)",
            "sort": "\(sort)"
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(.GET, url, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value else {
                    print("couldn't serialize response")
                    self.configureUI(false)
                    return
                }
                
                // GUARD: Are the "photos" and "photo" keys in our result?
                guard let parsedArtistsList = parsedResult["artistsList"] as? [[String:AnyObject]],
                    totalPages = parsedResult["totalPages"] as? Int else {
                        print("Cannot find keys 'artistsList' and 'totalPages' in \(parsedResult)")
                        self.configureUI(false)
                        return
                }
                
                // Fill the self.artistsList
                for parsedArtist in parsedArtistsList {
                    
                    // GUARD: Are the artist "_id" and "name" keys in our result?
                    guard let id = parsedArtist["_id"] as? Int, name = parsedArtist["name"] as? String else {
                        // Skip that artist
                        continue
                    }
                    
                    // Fill artist data
                    let artist = Artist(id: id, name: name)
                    
                    if let imageURL = parsedArtist["image"] as? String {
                        artist.imageURL = imageURL
                    }
                    if let totalSongsPages = parsedArtist["totalSongsPages"] as? Int {
                        artist.totalSongsPages = totalSongsPages
                    }
                    if let songsPageSize = parsedArtist["songsPageSize"] as? Int {
                        artist.songsPageSize = songsPageSize
                    }
                    
                    // Append to self.artistsList
                    self.artistsList.append(artist)
                }
                
                // Set artist page related values
                self.lastFetchedPage = page
                self.totalPages = totalPages
                
                // Reload data and finish
                self.collectionView?.reloadData()
                self.configureUI(false)
        }
    }
    
    private func configureUI(busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.sharedApplication().networkActivityIndicatorVisible = busy
    }
}
