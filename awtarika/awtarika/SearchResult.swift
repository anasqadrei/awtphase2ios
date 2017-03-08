//
//  SearchResult.swift
//  awtarika
//
//  Created by Anas Qadrei on 1/3/17.
//  Copyright © 2017 Anas Qadrei. All rights reserved.
//

import Foundation

class SearchResult {
    
    struct IndexType {
        static let Artist = "artists"
        static let Song = "songs"
    }
    
    var id: Int
    var type: String
    var slug: String
    var metaTitle: String
    var durationDesc: String?
    
    init(id: Int, type: String, slug: String, metaTitle: String) {
        self.id = id
        self.type = type
        self.slug = slug
        self.metaTitle = metaTitle
    }
    
    static func createSearchResult(_ parsedSearchResult: [String:AnyObject]) -> SearchResult? {      
        
        // GUARD: Are the search result "_id", "_type", "_source", "slug", and "metaTitle" keys in our result?
        guard let id = Int((parsedSearchResult["_id"] as? String)!) else {
            return nil
        }
        guard let type = parsedSearchResult["_type"] as? String else {
            return nil
        }
        guard let source = parsedSearchResult["_source"] as? [String:AnyObject] else {
            return nil
        }
        guard let slug = source["slug"] as? String else {
            return nil
        }
        guard let metaTitle = source["metaTitle"] as? String else {
            return nil
        }
        
        // Create a search result with mandetory data
        let searchResult = SearchResult(id: id, type: type, slug: slug, metaTitle: metaTitle)
        
        // Fill in the rest of the data
        if let durationDesc = source["durationDesc"] as? String {
            searchResult.durationDesc = durationDesc
        }
        
        // Return
        return searchResult
    }
}
