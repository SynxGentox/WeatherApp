//
//  ContentView.swift
//  WeatherApp
//
//  Created by Aryan Verma on 24/03/26.
//

import SwiftUI
import Observation

//enum WeatherType: String, CodingKey {
//    case longitude = "lon"
//    case latitude = "lat"
//    case temperature = "temp"
//    case feelsLike = "feels_like"
//    case pressure = "pressure"
//    case humidity = "humidity"
//    case visibility = "visibility"
//    case windSpeed = "wind_speed"
//    case windDirection = "wind_deg"
//    case weatherDescription = "description"
//    case cloudiness = "clouds"
//}


struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let tempMin: Double
    let tempMax: Double
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
}

struct WeatherResponse: Codable {
    let name: String
    let weather: [Weather]
    let coord: Coordinates
    let wind: Wind
    let visibility: Int
    let main: Main
}

@Observable
class WeatherData {
    //    var result: WeatherResponse = WeatherResponse(name: "", weather: [], coord: Coordinates(lat: 0.0, lon: 0.0), wind: Wind(speed: 0.0, deg: 0), visibility: 0, main: Main(temp: 0.0, feels_Like: 0.0, pressure: 0, humidity: 0, temp_min: 0.0, temp_max: 0))
    var weather: [Weather]?
    var name: String?
    var coord: Coordinates?
    var wind: Wind?
    var visibility: Int?
    var main: Main?
    
    
    func loadData() async {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=London&appid=\(Secrets.weatherAPIKey)") else {
            print("InvalidURL")
            return
        }
        do {
            let (data,_) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let decodedData = try? decoder.decode(
                WeatherResponse.self,
                from: data
            ) {
                weather = decodedData.weather
                name = decodedData.name
                coord = decodedData.coord
                wind = decodedData.wind
                visibility = decodedData.visibility
                main = decodedData.main
            }
        } catch {
            print("InvalidData")
        }
    }
}

struct ContentView: View {
    @Environment(WeatherData.self) private var data
    var body: some View {
        ZStack{
            Text(data.name ?? "errorLoadingName")
                .foregroundStyle(.primary)
                .task {
                    await data.loadData()
                }
            
            ConcentricRectangle(corners: .concentric, isUniform: true)
                .fill(.fill.secondary)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 400, alignment: .bottom)
            
            VStack {
                
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        
    }
}

#Preview {
    ContentView()
        .environment(WeatherData())
}
