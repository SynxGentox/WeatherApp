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

struct TempSize: ViewModifier {
    enum Style {
        case tempStyle
        case degreeStyle
        case captionStyle
        case footnoteStyle
    }
    var style: Style
    
    @ScaledMetric private var tempStyle: CGFloat = 150
    @ScaledMetric private var degreeStyle: CGFloat = 70
    @ScaledMetric private var captionStyle: CGFloat = 35
    @ScaledMetric private var footnoteStyle: CGFloat = 20
    
    func body(content: Content) -> some View {
        switch style {
        case .tempStyle:
            content
                .font(
                    Font(
                        UIFont
                            .systemFont(
                                ofSize: tempStyle,
                                weight: .bold,
                                width: .compressed
                            )
                    )
                )
        case .degreeStyle:
            content
                .font(
                    Font(
                        UIFont
                            .systemFont(
                                ofSize: degreeStyle,
                                weight: .bold,
                                width: .compressed
                            )
                    )
                )
        case .captionStyle:
            content
                .font(
                    Font(
                        UIFont
                            .systemFont(
                                ofSize: captionStyle,
                                weight: .bold,
                                width: .compressed
                            )
                    )
                )
        case .footnoteStyle:
            content
                .font(
                    Font(
                        UIFont
                            .systemFont(
                                ofSize: footnoteStyle,
                                weight: .medium,
                                width: .condensed
                            )
                    )
                )
        }
    }
}
extension View {
    func tempStyle(_ style: TempSize.Style) -> some View {
        modifier(TempSize(style: style))
    }
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

struct WeatherDetails: Codable, Identifiable {
    let id: Int
    let main: String
    let icon: String
}

struct ForecastDetails: Codable, Identifiable {
    let dt: TimeInterval
    let weather: [WeatherDetails]
    let main: Main
    let dtTxt: String
    
    var id: TimeInterval { dt }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"  // "28 Mar"
        return formatter.string(from: Date(timeIntervalSince1970: dt))
    }
    var shortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date(timeIntervalSince1970: dt))
    }
}
struct ForecastResponse: Codable {
    let list: [ForecastDetails]
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

struct SysDetails: Codable {
    let country: String
    let sunrise: TimeInterval
    let sunset: TimeInterval
}

struct WeatherResponse: Codable {
    let name: String
    let weather: [WeatherDetails]
    let coord: Coordinates
    let wind: Wind
    let visibility: Int
    let main: Main
    let sys: SysDetails
}

struct WeatherImage: View {
    let data: String
    
    var body: some View {
        AsyncImage(
            url: URL(
                string: "https://openweathermap.org/img/wn/\(data)@4x.png"
            )
        ) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if phase.error !=  nil {
                VStack{
                    Image(systemName: "exclamationmark.trianglepath")
                    Text("Image couldnt Load")
                }
            }
            else {
                ProgressView()
            }
        }
        .scaleEffect(2.5)
    }
}

enum Units: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
    
    var symbol: String {
        switch self {
        case .metric: return "°C"
        case .imperial: return "°F"
        }
    }
}

enum City: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case newYork = "New York"
    case london = "London"
    case paris = "Paris"
    case tokyo = "Tokyo"
    case sydney = "Sydney"
    case ghaziabad = "Ghaziabad"
    
    var query: String {
        rawValue
            .addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
class WeatherData {
    var result: WeatherResponse?
    var forecast: ForecastResponse?
    var unit: Units = Units.metric
    var city: City = .ghaziabad
    
    func loadData() async {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city.query)&units=\(unit.rawValue)&appid=\(Secrets.weatherAPIKey)") else {
            print("InvalidURL")
            return
        }
        do {
            let (data,_) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            result = try decoder.decode(WeatherResponse.self,from: data)
            
            if let lat = result?.coord.lat, let lon = result?.coord.lon {
                await loadForecastData(lat: lat, lon: lon)
            }
        }
        catch {
            print("InvalidData")
        }
    }
    
    func loadForecastData(lat: Double, lon: Double) async{
        guard let url2 = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&units=\(unit.rawValue)&appid=\(Secrets.weatherAPIKey)") else {
            print("Invalid Forecast URl")
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url2)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            forecast = try decoder.decode(ForecastResponse.self, from: data)
        }
        catch {
            print("Invalid Forecast Data: \(error)")
        }
    }
    
    var forecastByDay: [String: [ForecastDetails]] {
        guard let list = forecast?.list else { return [:] }
        
        return Dictionary(grouping: list) { item in
            String(
                item.dtTxt.prefix(10)
            )
        }
    }
        
    var hourlySummary: [ForecastDetails] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return forecast?.list.filter { $0.dtTxt.hasPrefix(today) } ?? []
    }
    
    // NEW: one representative temp per day (the noon slot, fallback to first)
    var dailySummary: [ForecastDetails] {
        return forecastByDay.keys.sorted().compactMap { day in
            let items = forecastByDay[day] ?? []
            // prefer the 12:00:00 slot as it represents midday
            return items.first { $0.dtTxt.contains("12:00:00") } ?? items.first
        }
    }
    
    var backgroundColor: LinearGradient {
        switch result?.weather.first?.main {
        case "Clear": return LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .top,
            endPoint: .bottom
        )
        case "Clouds": return LinearGradient(
            colors: [.gray, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        case "Rain": return LinearGradient(
            colors: [.indigo, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        default: return LinearGradient(
            colors: [.black, .gray],
            startPoint: .top,
            endPoint: .bottom
        )
        }
    }
    
    var dayProgress: Double {
        let now = Date().timeIntervalSince1970
        let sunrise: Double = result?.sys.sunrise ?? 0.0
        let sunset: Double =  result?.sys.sunset ?? 1.0
        if now < sunrise {
            // before sunrise — night ending, count down to sunrise
            // need previous sunset for this, skip for now, return 0
            return 0.0
        } else if now < sunset {
            // daytime — 0 to 1
            return (now - sunrise) / (sunset - sunrise)
        } else {
            // after sunset — night starting, 1 back to 0
            let nightDuration: Double = 86400 - (
                sunset - sunrise
            ) // seconds of night
            let nightProgress = (now - sunset) / nightDuration
            return 1.0 - nightProgress // counts back down
        }
    }
}

struct ContentView: View {
    @Environment(WeatherData.self) private var data
    var body: some View {
        @Bindable var degree = data
        ZStack{
            Rectangle()
                .fill(data.backgroundColor)
                .containerRelativeFrame(.horizontal)
                .ignoresSafeArea()
            Color.black.opacity(0.1)
                .background(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea(.all)
                
            VStack(alignment: .leading, spacing: 10) {
                Spacer().frame(height: 60)
                Menu {
                    ForEach(City.allCases) { city in
                        Button(city.rawValue) {
                            data.city = city
                            Task {
                                await data.loadData()
                            }
                        }
                    }
                    
                } label: {
                    VStack(alignment: .leading) {
                        Text(data.result?.name ?? "")
                            .tempStyle(.captionStyle)
                            .foregroundStyle(Color.white)
                        Text(Date(), format: .dateTime.weekday(.wide).month().day())
                            .tempStyle(.footnoteStyle)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.leading, 20)
                }
                
                ZStack(alignment: .topLeading) {
                    WeatherImage(
                        data: data.result?.weather.first?.icon ?? "04d"
                    )
                    .offset(y: 100 + (data.dayProgress * 150)) // Pushing it way down
                            .offset(x: 200, y: 75)
                    .animation(.smooth(duration: 1), value: data.dayProgress)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 10,
                        x: 3,
                        y: 7
                    )
                    .frame(maxWidth: 100, maxHeight: 100)
                    
                    MainTempView(
                        degree: $degree.unit
                    )  // bottom layer, keeps its frame
                    .padding(.top, 10)
                }
                HourlyTempView()
                    .padding(.bottom)
                DetailsView()
                    .padding(.bottom)
                DailyTempView()
                Spacer()
            }
            .ignoresSafeArea()
        }
        .shadow(color: .black.opacity(0.33), radius: 3, x: 0, y: 0)
        
        .task {
            await data.loadData()
        }
    }
}

struct MainTempView: View {
    @Environment(WeatherData.self) private var data
    @Binding var degree: Units
    var body: some View {
        HStack {
            Text(String(format: "%.1f", data.result?.main.temp ?? 0.0))
                .tempStyle(.tempStyle)
            Text(data.unit.symbol)
                .tempStyle(.degreeStyle)
                .offset(x: 0, y: -30)
        }
        .padding(.leading, 20)
        //        .shadow(
        //            color: Color.black.opacity(0.3),
        //            radius: 3,
        //            x: 7,
        //            y: 7
        //        )
        .onTapGesture {
            if data.unit == Units.metric {
                degree = Units.imperial
            } else {
                degree = Units.metric
            }
            Task {
                await data.loadData()
            }
        }
        
    }
}

struct HourlyTempView: View {
    @Environment(WeatherData.self) private var data
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(data.hourlySummary) { item in
                    VStack {
                        Text(item.shortTime)
                            .tempStyle(.footnoteStyle)
                        WeatherImage(data: item.weather.first?.icon ?? "04d")
                            .frame(maxWidth: 70, maxHeight: 70)
                        Text(
                            String(format: "%.1f°", item.main.temp)
                        )
                        .tempStyle(.footnoteStyle)
                    }
                    .frame(minWidth: 83)
                }
            }
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 95, maxHeight: 95)
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .glassEffect(.clear.tint(.black.opacity(0.25)), in: .rect)
        .background(.ultraThinMaterial.opacity(01))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        
    }
}

struct DailyTempView: View {
    @Environment(WeatherData.self) private var data
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(data.dailySummary) { item in
                    VStack {
                        Text(item.shortDate)
                            .tempStyle(.footnoteStyle)
                        WeatherImage(data: item.weather.first?.icon ?? "04d")
                            .frame(maxWidth: 70, maxHeight: 70)
                        Text(
                            String(format: "%.1f°", item.main.temp)
                        )
                        .tempStyle(.footnoteStyle)
                    }
                    .frame(minWidth: 83)
                }
            }
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 95, maxHeight: 95)
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
    }
}

struct DetailsView: View {
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150, maximum: 1000), spacing: nil),
        GridItem(.adaptive(minimum: 150, maximum: 1000), spacing: nil)
    ]
    @Environment(WeatherData.self) private var data
    
    var body: some View {
        VStack {
            let details: [(label: String, value: String)] = [
                (
                    "Feels Like",
                    String(format: "%.1f°", data.result?.main.feelsLike ?? 0)
                ),
                ("Humidity", "\(data.result?.main.humidity ?? 0)%"),
                (
                    "Temp Max",
                    String(format: "%.1f°", data.result?.main.tempMax ?? 0)
                ),
                (
                    "Temp Min",
                    String(format: "%.1f°", data.result?.main.tempMin ?? 0)
                ),
                ("Pressure", "\(data.result?.main.pressure ?? 0) hPa"),
                ("Visibility", "\((data.result?.visibility ?? 0)/1000) km"),
                (
                    "Wind Speed",
                    String(format: "%.1f m/s", data.result?.wind.speed ?? 0)
                ),
                ("Wind Deg", "\(data.result?.wind.deg ?? 0)°")
            ]
            
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(details, id: \.label) { detail in
                    VStack(alignment: .leading) {
                        Text(detail.label)
                        Text(detail.value)
                    }
                    .padding(2.5)
                }
            }
            .padding(.horizontal, 25)
        }
        .tempStyle(.footnoteStyle)
    }
}

extension WeatherData {
    static var preview: WeatherData {
        let data = WeatherData()
        Task {
            await data.loadData()
        }
        return data
    }
}

#Preview {
    ContentView()
        .environment(WeatherData.preview)
}
