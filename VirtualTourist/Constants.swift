//
//  Constants.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/24/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

struct Constants {
    
    // MARK: Flickr
    struct Flickr {
        static let APIBaseURL = "https://api.flickr.com/services/rest/"
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Lat = "lat"
        static let Long = "lon"
        static let Accuracy = "accuracy"
        static let Extras = "extras"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let APIKey = "dcf08a8332d7bab9cc96c11bc07bcf36"
        static let APISecret = "f9188c1e0adeaf9d"
        static let Accuracy = "11"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let PhotosForLocationMethod = "flickr.photos.search"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
