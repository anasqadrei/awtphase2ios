//
//  SearchViewController.swift
//  awtarika
//
//  Created by Anas Qadrei on 28/2/17.
//  Copyright © 2017 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import iOSLogEntries
import GoogleMobileAds

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet weak var totalResultsLabel: UILabel!
    @IBOutlet weak var adBannerView: GADBannerView!
    
    var searchTerm = ""
    var searchResultsList = [SearchResult]()
    
    var totalPages = 1
    var lastFetchedPage = 0
    var fetching = false
    
    let gaScreenCategory = "Search"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set table view data source
        searchResultsTableView.dataSource = self
        
        // Ad
        adBannerView.adUnitID = Constants.AdMob.SearchScreenAdUnitID
        adBannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kDFPSimulatorID, Constants.AdMob.TestDeviceAnasIPhone4S]
        adBannerView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Google Analytics - Screen View
        GoogleAnalyticsManager.screenView(name: gaScreenCategory)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Search text is not empty
        if let q = searchBar.text {
            // Google Analytics - Event
            GoogleAnalyticsManager.event(category: gaScreenCategory, action: "Search", label: q)
            
            // Reset
            searchResultsList.removeAll()
            lastFetchedPage = 0
            totalResultsLabel.text = ""
            searchResultsTableView.reloadData()
            
            // Set
            searchTerm = q
            
            // Go
            getSearchResults(lastFetchedPage + 1)
        }
        
        // Dismiss keyboard
        searchBar.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dismiss keyboard
        searchBar.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // For scrolling purposes, fetch more results if:
        //   Not busy fetching
        //   Still more pages to fetch
        //   Close to the bottom by 5 results
        if !fetching && lastFetchedPage < totalPages && indexPath.row >= searchResultsList.count - 5 {
            getSearchResults(lastFetchedPage + 1)
        }
        
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultTableViewCell
        cell.configure(searchResultsList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Dismiss keyboard first
        searchBar.resignFirstResponder()
        
        // Get the selected row
        let searchResult = searchResultsList[indexPath.row]
        
        // Navigation
        switch searchResult.type {
        case SearchResult.IndexType.Artist:
            segueToArtist(id: searchResult.id, slug: searchResult.slug)           
        case SearchResult.IndexType.Song:
            segueToSong(id: searchResult.id, slug: searchResult.slug)
        default:
            break
        }
    }
    
    fileprivate func getSearchResults(_ page: Int) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        let url = "\(Constants.URLs.Host)/search"
        let parameters = [
            "page": "\(page)",
            "pageSize": "\(10)",
            "q": searchTerm
        ]
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value as? [String: Any] else {
                    LELog.log("\(self) q: \(self.searchTerm) getSearchResults(\(page)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
              
                // GUARD: Are the "searchResultsList", "totalPages" and "totalResults" keys in our result?
                guard let parsedSearchResultsList = parsedResult["searchResultsList"] as? [[String:AnyObject]],
                    let totalPages = parsedResult["totalPages"] as? Int, let totalResults = parsedResult["totalResults"] as? Int else {
                        LELog.log("\(self) q: \(self.searchTerm) getSearchResults(\(page)): Couldn't find keys 'searchResultsList' and 'totalPages' in \(parsedResult)" as NSObject!)
                        self.configureUI(false)
                        return
                }
                
                // Fill the self.searchResultsList
                for parsedResult in parsedSearchResultsList {
                    // Append to self.searchResultsList
                    if let searchResult = SearchResult.createSearchResult(parsedResult) {
                        self.searchResultsList.append(searchResult)
                    } else {
                        LELog.log("\(self) q: \(self.searchTerm) getSearchResults(\(page)): A searchResult couldn't be serialized." as NSObject!)
                    }
                }
                
                // Set song page related values
                self.lastFetchedPage = page
                self.totalPages = totalPages
                
                // Reload data and finish
                self.totalResultsLabel.text = "عدد نتائج البحث: \(totalResults)"
                self.searchResultsTableView.reloadData()
                self.configureUI(false)
        }
    }
    
    fileprivate func segueToArtist(id: Int, slug: String) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        guard let url = "\(Constants.URLs.Host)/artist/\(id)/\(slug)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            LELog.log("\(self) segueToArtist(\(id), \(slug)): Couldn't encode url." as NSObject!)
            self.configureUI(false)
            return
        }
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value as? [String: Any] else {
                    LELog.log("\(self) segueToArtist(\(id), \(slug)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // GUARD: is the "artist" key in our result?
                guard let parsedArtist = parsedResult["artist"] as? [String:AnyObject] else {
                        LELog.log("\(self) segueToArtist(\(id), \(slug)): Couldn't find keys 'artist' in \(parsedResult)" as NSObject!)
                        self.configureUI(false)
                        return
                }
                
                // Finish
                self.configureUI(false)
                
                // Segue to artist VC
                if let artist = Artist.createArtist(parsedArtist) {
                    let artistVC = self.storyboard?.instantiateViewController(withIdentifier: "ArtistView") as! ArtistViewController
                    artistVC.artist = artist
                    self.navigationController?.pushViewController(artistVC, animated: true)
                } else {
                    LELog.log("\(self) segueToArtist(\(id), \(slug)): artist couldn't be serialized." as NSObject!)
                }
        }
    }
    
    fileprivate func segueToSong(id: Int, slug: String) {
        // Set busy fetching
        configureUI(true)
        
        // Create request
        guard let url = "\(Constants.URLs.Host)/song/\(id)/\(slug)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            LELog.log("\(self) segueToSong(\(id), \(slug)): Couldn't encode url." as NSObject!)
            self.configureUI(false)
            return
        }
        let headers = ["Accept": "application/json"]
        Alamofire.request(url, method: .get, headers: headers)
            .validate()
            .responseJSON { response in
                
                // GUARD: Data parsed to JSON?
                guard let parsedResult = response.result.value as? [String: Any] else {
                    LELog.log("\(self) segueToSong(\(id), \(slug)): Couldn't serialize response." as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // GUARD: is the "song" key in our result?
                guard let parsedSong = parsedResult["song"] as? [String:AnyObject] else {
                    LELog.log("\(self) segueToSong(\(id), \(slug)): Couldn't find keys 'song' in \(parsedResult)" as NSObject!)
                    self.configureUI(false)
                    return
                }
                
                // Finish
                self.configureUI(false)
                
                // Segue to song VC
                if let song = Song.createSong(parsedSong) {
                    let songVC = self.storyboard?.instantiateViewController(withIdentifier: "SongView") as! SongViewController
                    songVC.song = song
                    self.navigationController?.pushViewController(songVC, animated: true)
                } else {
                    LELog.log("\(self) segueToSong(\(id), \(slug)): song couldn't be serialized." as NSObject!)
                }
        }
    }
    
    fileprivate func configureUI(_ busy: Bool) {
        // Set UI and fetching to busy or not
        fetching = busy
        UIApplication.shared.isNetworkActivityIndicatorVisible = busy
    }

}
