//
//  PhotosDataManager.swift
//  awtarika
//
//  Created by Anas Qadrei on 5/09/2016.
//  Copyright © 2016 Anas Qadrei. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class PhotosDataManager {
    static let sharedManager = PhotosDataManager()
    
    let photoCache = AutoPurgingImageCache(
        // 100 MB
        memoryCapacity: 100 * 1024 * 1024,
        
        //60 MB
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )
    
    func getNetworkImage(urlString: String, completion: (UIImage -> Void)) -> (Request) {
        return Alamofire.request(.GET, urlString).responseImage { (response) -> Void in
            
            // GUARD: Does image even exist?
            guard let image = response.result.value else {
                return
            }
            
            // Run completion function
            completion(image)
            
            // Cache image
            self.cacheImage(image, urlString: urlString)
        }
    }
    
    func cacheImage(image: Image, urlString: String) {
        // Add to cache
        photoCache.addImage(image, withIdentifier: urlString)
    }
    
    func cachedImage(urlString: String) -> Image? {
        // Get from cached
        return photoCache.imageWithIdentifier(urlString)
    }
}