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

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var myBottomView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    
    let longPress = UILongPressGestureRecognizer()
    var pins = [NSManagedObject]()
    var pinsForDeletion = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        myMapView.addGestureRecognizer(longPress)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let location = defaults.dictionaryForKey("location") {
            let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location["lat"] as! Double, location["long"] as! Double)
            let span: MKCoordinateSpan = MKCoordinateSpanMake(location["latDelta"] as! Double, location["longDelta"] as! Double)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(center, span)
            myMapView.setRegion(region, animated: true)
            print(location)
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
        
        print(myMapView.centerCoordinate.latitude)
        print(myMapView.centerCoordinate.longitude)
        print(myMapView.region.span.latitudeDelta)
        print(myMapView.region.span.longitudeDelta)

        
        let touchPoint = sender.locationInView(myMapView)
        let newCoordinates = myMapView.convertPoint(touchPoint, toCoordinateFromView: myMapView)
        
        let newPin = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: context) as! Pin
        newPin.lat = newCoordinates.latitude
        newPin.long = newCoordinates.longitude
        
        FlickrClient.sharedInstance().getFlickrImagesByLocation(newPin.lat as! Double, long: newPin.long as! Double, pin: newPin, page: 1, completion: { (result, error) -> () in
            if let result = result {
            } else {
                print(error)
            }
        })

        appDelegate.saveContext()
        
        self.setUpMapView()
        
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
                annotation.title = "Title"
                annotation.subtitle = "Subtitle"
                
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
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let cv = storyboard?.instantiateViewControllerWithIdentifier("CollectionView") as! CollectionViewController
        let pin = view.annotation!
        
        if self.navItem.rightBarButtonItem!.style == UIBarButtonItemStyle.Done {
            mapView.removeAnnotation(view.annotation!)
            deletePin(pin.coordinate.latitude, long: pin.coordinate.longitude)
            
        } else {
            cv.lat = pin.coordinate.latitude
            cv.long = pin.coordinate.longitude
            cv.myTitle = pin.title!
            cv.mySubtitle = pin.subtitle!
            
            self.navigationController?.pushViewController(cv, animated: true)
        }
    }
    
    func deletePin(lat: Double, long: Double) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            pinsForDeletion = results as! [Pin]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        for pinToDelete in pinsForDeletion {
            if pinToDelete.lat as! Double == lat && pinToDelete.long as! Double == long {
                context.deleteObject(pinToDelete)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let locationData = ["lat":myMapView.centerCoordinate.latitude
            , "long":myMapView.centerCoordinate.longitude
            , "latDelta":myMapView.region.span.latitudeDelta
            , "longDelta":myMapView.region.span.longitudeDelta]
        defaults.setObject(locationData, forKey: "location")
    }


}

