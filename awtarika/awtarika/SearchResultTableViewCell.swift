//
//  SearchResultTableViewCell.swift
//  awtarika
//
//  Created by Anas Qadrei on 1/3/17.
//  Copyright © 2017 Anas Qadrei. All rights reserved.
//

import Foundation

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var metaTitle: UILabel!
    @IBOutlet weak var duration: UILabel!
    
    var searchResult: SearchResult!
    
    func configure(_ searchResult: SearchResult) {
        // Save the search result in the cell to be passed later on to search VC
        self.searchResult = searchResult
        
        // Fill data
        metaTitle.text = searchResult.metaTitle
        if let durationStr = searchResult.durationDesc {
            duration.text = "🕓 \(durationStr)"
        } else {
            duration.text = ""
        }
    }
    
}
