import CoreLocation

public class LocationInfoManager {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var cityName = ""
    var stateName = ""
    var countryName = ""

    public init() {
        fetchLocation()
    }

    public func fetchLocation() {
        guard let coordinates = getLatitudeAndLongitude() else {
            print("Failed to retrieve location.")
            return
        }

        latitude = coordinates.latitude
        longitude = coordinates.longitude

        if let locationInfo = reverseGeocode(latitude: latitude, longitude: longitude) {
            let (city, state, country) = locationInfo
        } else {
            print("Reverse geocoding failed.")
        }
    }

    public func getLatitudeAndLongitude() -> (latitude: Double, longitude: Double)? {
        let locationManager = CLLocationManager()
        var result: (latitude: Double, longitude: Double)?

        // Create a semaphore to wait for location updates
        let semaphore = DispatchSemaphore(value: 0)

        // Request location authorization
        locationManager.requestWhenInUseAuthorization()

        // Check if location services are enabled
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest

            // Start receiving location updates
            locationManager.startUpdatingLocation()

            // Get the most recent location
            if let location = locationManager.location {
                result = (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }

            // Stop updating location and signal semaphore
            locationManager.stopUpdatingLocation()
            semaphore.signal()
        }

        // Wait for the semaphore to be signaled
        _ = semaphore.wait(timeout: .distantFuture)

        return result
    }

    public func reverseGeocode(latitude: Double, longitude: Double) -> (String, String, String)? {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }

            guard let placemark = placemarks?.first else {
                print("No placemark found.")
                return
            }

            if let city = placemark.locality {
                self.cityName = city
            }

            if let state = placemark.administrativeArea {
                self.stateName = state
            }

            if let country = placemark.country {
                self.countryName = country
            }
        }

        // Wait for the reverse geocoding to complete
        while cityName.isEmpty || stateName.isEmpty || countryName.isEmpty {
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }

        return (cityName, stateName, countryName)
    }
}

