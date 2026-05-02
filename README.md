# WeatherApp
  A highly responsive weather application featuring dynamic, data-driven theming and real-time API integrations. Built with a focus on fluid UI and a minimal memory footprint.

---

# Performance Profiles
  Benchmarked via Xcode Instruments
  Memory: ~32MB idle, peaks at ~37MB during location switching and network fetches.
  CPU: 0% idle footprint.

---

# Features
🎨 Dynamic Theming: Background gradients adapt in real-time based on live weather conditions.
☀️ Time-Aware UI: Weather icons animate dynamically (top→bottom for day, bottom→top for night) driven by live API sunrise/sunset data.
🌡️ Interactive Data: Tap temperature to instantly toggle °C / °F and trigger live data refetches.
📍 Quick Navigation: Tap the location header to switch between 6 pre-configured global cities via a native dropdown menu.
⏱️ Deep Forecasting: Includes a 3-hour interval hourly forecast strip and a comprehensive 4-day daily outlook.
💨 Advanced Metrics: Displays "feels like" temperature, humidity, pressure, visibility, wind speed, and wind direction.
🌐 Chained Networking: Dual API call architecture — fetches current weather and seamlessly chains coordinates to fetch the extended forecast.

---

# Tech Stack
  UI & State: SwiftUI + @Observable
  Networking: URLSession
  async/await
  Data Source: OpenWeatherMap REST API
  Assets: Native AsyncImage for asynchronous icon loading
  Architecture
  Single-File MVVM This project utilizes a centralized WeatherData model as the observable state, treating SwiftUI views as pure rendering layers.
  Engineering Note: This repository served as the architectural baseline for strict state management. The architecture was subsequently scaled into a fully modular Protocol-Oriented pattern in my [Expense Tracker] and true Clean Architecture with Dependency Injection in my [Aria AI] projects.

---
  
# Screenshots
  <img src="WeatherApp/Assets/night.png" width="250"> 
  <img src="WeatherApp/Assets/clear_day.png" width="250"> 

---

# Setup & Installation
  Clone the repository.
  Create a Secrets.swift file in the root directory (this file is ignored in .gitignore for security) and add your OpenWeatherMap API key: Swift

  '''
  struct Secrets {
      static let weatherAPIKey = "YOUR_KEY_HERE"
  }
  '''

