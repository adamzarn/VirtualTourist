//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/23/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var myBottomView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    
    let longPress = UILongPressGestureRecognizer()
    var pins = [NSManagedObject]()
    var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        myMapView.addGestureRecognizer(longPress)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if  let lat = defaults.valueForKey("lat"),
            let long = defaults.valueForKey("long"),
            let latDelta = defaults.valueForKey("latDelta"),
            let longDelta = defaults.valueForKey("longDelta")
        
        {
            let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat as! Double, long as! Double)
            let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta as! Double, longDelta as! Double)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(center, span)
            myMapView.setRegion(region, animated: true)
        }
        
        myBottomView.hidden = true
        
        self.setUpMapView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {

        if sender.style == UIBarButtonItemStyle.Done {
            myBottomView.hidden = true
            sender.title = "Edit"
            sender.style = UIBarButtonItemStyle.Plain
            myMapView.frame.origin.y += myBottomView.frame.height
        } else {
            myBottomView.hidden = false
            sender.title = "Done"
            sender.style = UIBarButtonItemStyle.Done
            myMapView.frame.origin.y -= myBottomView.frame.height
        }

    }
    
    func dropPin(sender: UILongPressGestureRecognizer) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let touchPoint = sender.locationInView(myMapView)
        let newCoordinates = myMapView.convertPoint(touchPoint, toCoordinateFromView: myMapView)
        
        let newPin = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: context) as! Pin
        newPin.lat = newCoordinates.latitude
        newPin.long = newCoordinates.longitude
        
        appDelegate.saveContext()
        
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            pins = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            if let latitude = pin.valueForKey("lat"), longitude = pin.valueForKey("long") {
                let lat = CLLocationDegrees(latitude as! Double)
                let long = CLLocationDegrees(longitude as! Double)
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = ""
                annotation.subtitle = ""
                
                annotations.append(annotation)
            }
        }
        
        self.myMapView.addAnnotations(annotations)
    
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if self.navItem.rightBarButtonItem!.style == UIBarButtonItemStyle.Done {
            mapView.removeAnnotation(view.annotation!)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(myMapView.centerCoordinate.latitude, forKey: "lat")
        defaults.setValue(myMapView.centerCoordinate.longitude, forKey: "long")
        defaults.setValue(myMapView.region.span.latitudeDelta, forKey: "latDelta")
        defaults.setValue(myMapView.region.span.longitudeDelta, forKey: "longDelta")
    }

}

