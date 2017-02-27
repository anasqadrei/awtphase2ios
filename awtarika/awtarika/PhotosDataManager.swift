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
    
    func getNetworkImage(_ urlString: String, completion: @escaping ((UIImage) -> Void)) -> (Request) {
        return Alamofire.request(urlString).responseImage { (response) -> Void in
            
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
    
    func cacheImage(_ image: Image, urlString: String) {
        // Add to cache
        photoCache.add(image, withIdentifier: urlString)
    }
    
    func cachedImage(_ urlString: String) -> Image? {
        // Get from cached
        return photoCache.image(withIdentifier: urlString)
    }
}
