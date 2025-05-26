//
//  WeatherManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

import Foundation

struct WeatherData {
    let condition: String
    let temperature: Double
}

class WeatherManager {
    static let shared = WeatherManager()

    func fetchWeather(completion: @escaping (WeatherData?) -> Void) {
        LocationManager.shared.getCurrentLocation { location in
            guard let location = location else {
                completion(nil)
                return
            }

            let lat = location.latitude
            let lon = location.longitude
            let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=weathercode,temperature_2m"

            guard let url = URL(string: urlStr) else {
                completion(nil)
                return
            }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any],
                      let code = current["weathercode"] as? Int,
                      let temp = current["temperature_2m"] as? Double else {
                    completion(nil)
                    return
                }

                let condition = self.mapCode(code)
                let weather = WeatherData(condition: condition, temperature: temp)

                DispatchQueue.main.async {
                    completion(weather)
                }
            }.resume()
        }
    }

    private func mapCode(_ code: Int) -> String {
        switch code {
        case 0: return "sunny"
        case 1...3: return "cloudy"
        case 45, 48: return "fog"
        case 51...67, 80...82: return "rainy"
        case 71...77, 85, 86: return "snowy"
        default: return "unknown"
        }
    }
}

