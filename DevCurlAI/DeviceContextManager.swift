import Foundation
import CoreLocation
import Contacts
import UIKit

public class DeviceContextManager: NSObject, CLLocationManagerDelegate {
    public static let shared = DeviceContextManager()

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let contactStore = CNContactStore()

    public private(set) var currentLocation: CLLocation?
    public private(set) var currentAddress: String = "Mendeteksi lokasi..."
    public private(set) var currentCity: String = ""

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    public func requestPermissions() {
        // 1. Location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        // 2. Contacts
        contactStore.requestAccess(for: .contacts) { granted, error in
            if granted {
                print("Contacts permission granted")
            }
        }
    }

    // MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let mark = placemarks?.first else { return }
            var parts: [String] = []
            if let name = mark.name { parts.append(name) }
            if let subLoc = mark.subLocality { parts.append(subLoc) }
            if let loc = mark.locality {
                parts.append(loc)
                self.currentCity = loc
            }
            if let admin = mark.administrativeArea { parts.append(admin) }
            if let country = mark.country { parts.append(country) }

            self.currentAddress = parts.joined(separator: ", ")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }

    // MARK: - Contact Lookup for WhatsApp / Automations
    public func findContactPhone(nameQuery: String) -> (name: String, phone: String)? {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.predicate = CNContact.predicateForContacts(matchingName: nameQuery)

        var matched: (name: String, phone: String)?

        do {
            try contactStore.enumerateContacts(with: request) { contact, stop in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if let phoneValue = contact.phoneNumbers.first?.value.stringValue {
                    let cleanPhone = phoneValue.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                    matched = (name: fullName, phone: cleanPhone)
                    stop.pointee = true
                }
            }
        } catch {
            print("Failed to fetch contact: \(error)")
        }

        return matched
    }

    // MARK: - Generate Ambient Context String
    public func getDeviceContextSummary() -> String {
        let batteryPct = Int(UIDevice.current.batteryLevel * 100)
        let batteryStr = batteryPct >= 0 ? "\(batteryPct)%" : "100%"
        let stateStr: String
        switch UIDevice.current.batteryState {
        case .charging: stateStr = "Mengisi daya"
        case .full: stateStr = "Penuh"
        case .unplugged: stateStr = "Baterai"
        default: stateStr = "Normal"
        }

        var locSummary = "Belum terdeteksi"
        if let loc = currentLocation {
            let lat = String(format: "%.5f", loc.coordinate.latitude)
            let lon = String(format: "%.5f", loc.coordinate.longitude)
            locSummary = "\(currentAddress) (Koordinat: \(lat), \(lon))"
        }

        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)

        return """
        [Konteks Nyata iPhone Pak cURLdev]:
        - Waktu Lokal: \(timeStr)
        - Lokasi GPS: \(locSummary)
        - Baterai: \(batteryStr) (\(stateStr))
        - Model: \(UIDevice.current.model) (iOS \(UIDevice.current.systemVersion))
        - Hak Akses: GPS Real-Time, Kontak Telepon, Mikrofon, Kamera Aktif
        """
    }
}
