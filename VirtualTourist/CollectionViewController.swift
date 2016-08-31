//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/23/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import CoreData
import UIKit
import MapKit

class CollectionViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var appDelegate: AppDelegate!
    
    @IBOutlet weak var singlePointMapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var lat: CLLocationDegrees?
    var long: CLLocationDegrees?
    var myTitle: String?
    var mySubtitle: String?
    
    var pins = [Pin]()
    var photosForPin = [Photo]()
    var correctPin = Pin?()
    var pageNumber = 1
    var indexPathsToDelete = [Int]()
    
    override func viewDidLoad() {
        self.setUpMapView()
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let space: CGFloat = 3.0
        let dimension = (UIScreen.mainScreen().bounds.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension,dimension)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.backgroundColor = UIColor.whiteColor()
        noImagesLabel.hidden = true
        
        getCorrectPin(self.lat!, long: self.long!)
        getPhotoURLs()
        setUpCollectionView()
 
    }
    
    override func viewDidAppear(animated: Bool) {
        self.setUpMapView()
    }
    
    func setUpCollectionView() {
        if photosForPin.count == 0 {
            noImagesLabel.hidden = false
            collectionView.hidden = true
        } else {
            noImagesLabel.hidden = true
            collectionView.hidden = false
            collectionView?.reloadData()
        }
    }
    
    func getCorrectPin(lat: Double, long: Double) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            pins = results as! [Pin]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        for pin in pins {
            if pin.lat as! Double == lat && pin.long as! Double == long {
                correctPin = pin
            }
        }
    }
    
    func getPhotoURLs() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Photo")
    
        if let correctPin = correctPin {
            let p = NSPredicate(format: "photoToPin = %@", argumentArray: [correctPin])
            fetchRequest.predicate = p
        
            photosForPin = []
            do {
                let results = try context.executeFetchRequest(fetchRequest)
                photosForPin = results as! [Photo]
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        } else {
            print("Predicate didn't work")
        }
    }

    
    func setUpMapView() {
        
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: self.lat!, longitude: self.long!)
    
        singlePointMapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: true)
    
        annotation.coordinate = coordinate
        annotation.title = myTitle
        annotation.subtitle = mySubtitle
        
        self.singlePointMapView.addAnnotation(annotation)
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .redColor()
        } else {
            pinView!.annotation = annotation
        }
        return pinView
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosForPin.count
    }
    
    func stopLoading(activityIndicator: UIActivityIndicatorView) {
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCell
        
        if cell.myImageView!.alpha < 1.0 {
            cell.myImageView!.alpha = 1.0
            let index = indexPathsToDelete.indexOf(indexPath.row)
            indexPathsToDelete.removeAtIndex(index!)
            if indexPathsToDelete.count == 0 {
                bottomButton.title = "New Collection"
            }
        } else {
            cell.myImageView!.alpha = 0.25
            indexPathsToDelete.append(indexPath.row)
            if indexPathsToDelete.count == 1 {
                bottomButton.title = "Remove Selected Pictures"
            }
        }
        indexPathsToDelete = indexPathsToDelete.sort { return $1 < $0 }
    }
    
    @IBAction func newCollectionRequested(sender: AnyObject) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        if bottomButton.title == "New Collection" {
            if photosForPin.count == 21 {
                pageNumber += 1
            } else {
                pageNumber = 1
            }
            
            photosForPin.removeAll()
            for photo in photosForPin {
                context.deleteObject(photo)
            }
            
            appDelegate.saveContext()
 
            self.noImagesLabel.hidden = true
            self.collectionView.hidden = true
            
            FlickrClient.sharedInstance().getFlickrImagesByLocation(correctPin!.lat as! Double, long: correctPin!.long as! Double, pin: correctPin!, page: pageNumber, completion: { (result, error) -> () in
                if let result = result {
                    self.getPhotoURLs()
                    self.setUpCollectionView()
                } else {
                    print(error)
                }
            })
            
        } else {
            
            for i in indexPathsToDelete {
                let photo = photosForPin[i]
                context.deleteObject(photo)
                photosForPin.removeAtIndex(i)
                self.setUpCollectionView()
            }
            
            appDelegate.saveContext()
            bottomButton.title = "New Collection"
            indexPathsToDelete = []
            
        }
    }
}

extension CollectionViewController {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CustomCell
        cell.activityIndicator.color = UIColor.whiteColor()
        
        if let imageData = photosForPin[indexPath.row].valueForKey("image") {
            
            cell.myImageView!.image = UIImage(data: imageData as! NSData)
            self.stopLoading(cell.activityIndicator)
            
        } else if photosForPin.count != 0 {
            
            cell.myImageView!.alpha = 1.0
            cell.myImageView.backgroundColor = UIColor.grayColor()
            cell.myImageView.image = nil
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()

            let urlString = photosForPin[indexPath.row].valueForKey("imageURL") as! String
            
            let url = NSURL(string: urlString)!
            let request = NSURLRequest(URL: url)
            let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    self.stopLoading(cell.activityIndicator)
                    return
                }
                
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    self.stopLoading(cell.activityIndicator)
                    return
                }
                
                guard let data = data else {
                    print("No data was returned by the request!")
                    self.stopLoading(cell.activityIndicator)
                    return
                }
                
                if let image = UIImage(data: data) {
                    performUIUpdatesOnMain {
                        cell.myImageView!.image = image
                        self.photosForPin[indexPath.row].setValue(data, forKey: "image")
                        self.appDelegate.saveContext()
                        self.stopLoading(cell.activityIndicator)
                    }
                } else {
                    print("Could not create image from \(data)")
                }
            }
            task.resume()
        }
        return cell
    }
}