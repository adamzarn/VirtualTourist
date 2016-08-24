//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/23/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    let longPress = UILongPressGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        myMapView.addGestureRecognizer(longPress)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dropPin(sender: UILongPressGestureRecognizer) {
        
        let touchPoint = sender.locationInView(myMapView)
        let newCoordinates = myMapView.convertPoint(touchPoint, toCoordinateFromView: myMapView)
        
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]

            if let locationName = placeMark.addressDictionary!["Name"] as? NSString, let city = placeMark.addressDictionary!["City"] as? NSString, let state = placeMark.addressDictionary!["State"] as? NSString, let zip = placeMark.addressDictionary!["ZIP"] as? NSString {
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = CLLocationCoordinate2D(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
                newAnnotation.title = locationName as String
                newAnnotation.subtitle = (city as String) + ", " + (state as String) + " " + (zip as String)
                self.myMapView.addAnnotation(newAnnotation)

            }
        
        })
    }
    
    func setUpMapView() {
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
        
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {

            let cv = storyboard?.instantiateViewControllerWithIdentifier("CollectionView") as! CollectionViewController
            let pin = view.annotation!
            cv.lat = pin.coordinate.latitude
            cv.long = pin.coordinate.longitude
            cv.myTitle = pin.title!
            cv.mySubtitle = pin.subtitle!
            
            FlickrClient.sharedInstance().getFlickrImagesByLocation(pin.coordinate.latitude, long: pin.coordinate.longitude, completion: { (result, error) -> () in
                if let result = result {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.photos = result
                    cv.collectionView.reloadData()
                } else {
                    print(error)
                }
            })
            self.navigationController?.pushViewController(cv, animated: true)
        }
    }

}

