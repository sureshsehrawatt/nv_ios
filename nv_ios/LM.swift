//
//  LocationManager.swift
//  NetVision
//
//  Created by compass-362 on 09/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


public class Location : Equatable {
    public var physical : CLLocation = CLLocation.init(latitude: 28.7041 , longitude: 77.1025)
    public static var city: String = "Delhi"
    public static var state: String = "Delhi"
    public static var neighborhood: String = "Connaught Place"
    public static var country : String = "India"
    
}

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.physical == rhs.physical
}

public class LocationManager : NSObject, CLLocationManagerDelegate {
    static let threshold = 5.0000;
    var map: MKMapView!
    static var currentLocation = Location() ;
    static var locationFound : Bool = false;
    static var isTracking : Bool = false;
    var locationManager = CLLocationManager()
    static var defaultlocation : Bool = false
    override public init() {
        super.init();
        // NARENDRA: FIX123
        /*if(!LocationManager.defaultlocation){
            //NSLog("[NetVision] Sending Default Location");
            sendSessionInfo(loc: LocationManager.currentLocation.physical);
        }*/
        
    }
    @objc(didFindLocation)
    public func didFindLocation() -> Bool {
        return NvPermission.didGetSessionInfo;
    }
    @objc(fetchLocation)
    public func fetchLocation(){
        if (LocationManager.locationFound){
            return;
        }
        locationManager.delegate = self
        if(LocationManager.isTracking){
            return;
        }
        LocationManager.isTracking = true;
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 9.0, *) {
            //FIXME: this request is creating an error NSInternalInconsistencyException.
            //locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }

    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if LocationManager.locationFound == false {
            
            let location = locations.last
            
            CLGeocoder().reverseGeocodeLocation(location!, completionHandler: { (placemarks, error) -> Void in
                if let placemark = placemarks?.first {
                    Location.city = placemark.locality ?? ""
                    Location.state = placemark.administrativeArea ?? ""
                    Location.neighborhood = placemark.subLocality ?? ""
                    Location.country = placemark.country ?? ""
                    LocationManager.currentLocation.physical = location!
                    LocationManager.locationFound = true;
                    sendSessionInfo(loc: location!)
                }
                else if let error = error {
                    NSLog("[NetVision] error : \(error)");
                }
                
                
                
            })
        }
        LocationManager.isTracking = false;
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("[NetVision] Didnt get location")
        LocationManager.isTracking = false;
        
    }
    

    
    
}

public func shouldUpdateWithLocation(location: CLLocation, loc : Location?) -> Bool
{
    if( LocationManager.locationFound ) {
        return false;
    }
    else {
        return true;
    }
}

