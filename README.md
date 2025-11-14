# 📱 Personalized Weather Dashboard – Flutter App

A mobile weather dashboard built for the **IN3510 – Wireless Communication & Mobile Networks** module at the University of Moratuwa. This Flutter application derives personalized coordinates from a student index, fetches real-time weather using the Open-Meteo API, and stores data locally so the app can also work offline.

---

## 🌟 Features

### ✅ 1. Student Index → Coordinates
The app calculates latitude and longitude using the required formula:

firstTwo = int(index[0..1])
nextTwo = int(index[2..3])

lat = 5 + (firstTwo / 10.0)
lon = 79 + (nextTwo / 10.0)


### ✅ 2. Real-Time Weather Fetching  
Uses Open-Meteo:
https://api.open-meteo.com/v1/forecast?latitude=LAT&longitude=LON&current_weather=true

Displays:
- 🌡 Temperature  
- 💨 Wind speed  
- ☁️ Weather code  
- 🕒 Last updated date & time  
- 🔗 Request URL

### ✅ 3. Offline Support  
- Saves last fetched data using `shared_preferences`
- When offline → automatically loads cached data
- Shows **Cached Data** tag when displaying offline results

### ✅ 4. Modern User Interface  
- Gradient background  
- Rounded weather info cards  
- Icons for weather, wind, and updates  
- Smooth loading indicator  
- Clear and friendly error messages  


---

## 🛠 Technologies Used
- Flutter  
- Dart  
- HTTP package  
- Shared Preferences 

---

## 🚀 How to Run This Project

### 1. Clone the repository
```bash
git clone https://github.com/Navoda001/WhetherApp.git
cd WhetherApp
```

###2. Install Flutter dependencies
```bash
flutter pub get
```

###3. Run the app
```bash
flutter run
```

