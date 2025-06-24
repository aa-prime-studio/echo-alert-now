import Foundation
import CoreLocation
import Combine

// 位置管理器 - 處理位置相關功能
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var currentLocation: LocationData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isLocationEnabled: Bool = false
    
    private let locationManager = CLLocationManager()
    private var locationUpdateTimer: Timer?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 只有在移動超過10公尺時才更新
        
        authorizationStatus = locationManager.authorizationStatus
        checkLocationPermission()
    }
    
    // 檢查位置權限
    func checkLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            isLocationEnabled = false
            locationError = LocationError.permissionDenied
        case .authorizedAlways:
            isLocationEnabled = true
            startLocationUpdates()
        #if os(iOS)
        case .authorizedWhenInUse:
            isLocationEnabled = true
            startLocationUpdates()
        #endif
        @unknown default:
            break
        }
    }
    
    // 請求位置權限
    func requestLocationPermission() {
        #if os(iOS)
        locationManager.requestWhenInUseAuthorization()
        #elseif os(macOS)
        locationManager.requestAlwaysAuthorization()
        #endif
    }
    
    // 開始位置更新
    func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = LocationError.locationServicesDisabled
            return
        }
        
        guard isLocationEnabled else {
            locationError = LocationError.permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
        
        // 設定定時器，定期檢查位置更新
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.requestCurrentLocation()
        }
    }
    
    // 停止位置更新
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    // 請求當前位置（一次性）
    func requestCurrentLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = LocationError.locationServicesDisabled
            return
        }
        
        #if os(iOS)
        locationManager.requestLocation()
        #elseif os(macOS)
        // macOS 不支援 requestLocation，使用 startUpdatingLocation 代替
        locationManager.startUpdatingLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.locationManager.stopUpdatingLocation()
        }
        #endif
    }
    
    // 取得模擬位置（用於測試）
    func getSimulatedLocation() -> LocationData {
        // 回傳台灣台北市的位置作為預設值
        return LocationData(
            latitude: 25.0330,
            longitude: 121.5654,
            accuracy: 10.0
        )
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let locationData = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
        
        DispatchQueue.main.async {
            self.currentLocation = locationData
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
            print("位置更新失敗: \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.checkLocationPermission()
        }
    }
    
    #if os(iOS)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            self.checkLocationPermission()
        }
    }
    #endif
}

// 位置錯誤類型
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServicesDisabled
    case locationNotAvailable
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置權限被拒絕"
        case .locationServicesDisabled:
            return "位置服務未啟用"
        case .locationNotAvailable:
            return "無法取得位置"
        case .timeout:
            return "位置請求逾時"
        }
    }
}

// 位置工具函數
extension LocationManager {
    
    // 計算兩點之間的距離
    static func distance(from: LocationData, to: LocationData) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // 檢查位置精度是否足夠
    func isLocationAccurate(_ location: LocationData, minimumAccuracy: Double = 100.0) -> Bool {
        return location.accuracy <= minimumAccuracy && location.accuracy > 0
    }
} 