//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Aryan Verma on 24/03/26.
//

import SwiftUI

@main
struct WeatherAppApp: App {
    private let data = WeatherData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(data)
        }
    }
}
