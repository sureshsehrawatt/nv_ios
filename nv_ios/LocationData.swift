//
//  LocationData.swift
//  nv_ios
//
//  Created by cavisson on 13/06/23.
//  Copyright © 2023 Cavisson. All rights reserved.
//

import Foundation
public class LocationData{
     
    public static let lm = LocationInfoManager()
    
    public static var latitude: Double = lm.latitude
    public static var longitude: Double = lm.longitude
    public static var city: String = lm.cityName
    public static var state: String = lm.stateName
    public static var country : String = lm.countryName
    
    init(){
        print(LocationData.latitude)
        print(LocationData.longitude)
        print(LocationData.city)
        print(LocationData.state)
        print(LocationData.country)
    }
    
}
