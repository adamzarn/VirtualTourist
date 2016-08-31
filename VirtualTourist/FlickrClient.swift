//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/24/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FlickrClient: NSObject {
    
    func getFlickrImagesByLocation(lat: CLLocationDegrees, long: CLLocationDegrees, pin: Pin, page: Int, completion: (result: NSArray?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.PhotosForLocationMethod
            ,Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey
            ,Constants.FlickrParameterKeys.Lat: "\(lat)"
            ,Constants.FlickrParameterKeys.Long: "\(long)"
            ,Constants.FlickrParameterKeys.Accuracy: Constants.FlickrParameterValues.Accuracy
            ,Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL
            ,Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat
            ,Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ,Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
            ,Constants.FlickrParameterKeys.Page: "\(page)"
        ]
        
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
        
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completion(result: nil, error: NSError(domain: "getFlickrImages", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("error")
                return
            }
            if let photos1 = parsedResult as? [String:AnyObject], let photos2 = photos1["photos"] as? [String:AnyObject], let photos = photos2["photo"] as? NSArray {
                    performUIUpdatesOnMain {
                        
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        let context = appDelegate.managedObjectContext
                        
                        for photo in photos {
                            let newPhoto = NSEntityDescription.insertNewObjectForEntityForName("Photo",inManagedObjectContext: context) as! Photo
                                newPhoto.imageURL = photo[Constants.FlickrResponseKeys.MediumURL] as? String
                                newPhoto.photoToPin = pin
                            }
                        completion(result: photos, error: nil)
                }
            }
        }
        task.resume()
        return task
    }
    
    func getImageData(urlString: String, completion: (result: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
    
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
        
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completion(result: nil, error: error)
                return
            }
        
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                completion(result: nil, error: error)
                return
            }
        
            guard let data = data else {
                print("No data was returned by the request!")
                completion(result: nil, error: error)
                return
            }
        
            if let data = data as NSData? {
                performUIUpdatesOnMain {
                    completion(result: data, error: nil)
                }
            } else {
                completion(result: nil, error: error)
                }
        }
        task.resume()
        return task
    }



    private func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joinWithSeparator("&"))"
        }
    }
    
    static let sharedInstance = FlickrClient()
    private override init() {
        super.init()
    }

}