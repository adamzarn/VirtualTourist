//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/23/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class CollectionViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var singlePointMapView: MKMapView!
    
    var lat: CLLocationDegrees?
    var long: CLLocationDegrees?
    var myTitle: String?
    var mySubtitle: String?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        self.setUpMapView()
        
        let space: CGFloat = 3.0
        let dimension = (UIScreen.mainScreen().bounds.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension,dimension)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView?.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.setUpMapView()
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
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .redColor()
        } else {
            pinView!.annotation = annotation
        }
        return pinView
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CustomCell
        
        if appDelegate.photos.count != 0 {
        
        let photo = appDelegate.photos[indexPath.row]
            if let imageUrlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String {
                let imageURL = NSURL(string: imageUrlString)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    cell.myImageView!.image = UIImage(data: imageData)
                }
            }
        }
        
        return cell
    }

    
    
}