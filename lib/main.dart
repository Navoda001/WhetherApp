import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final TextEditingController indexController = TextEditingController(text: "");
  String? temperature;
  String? windSpeed;
  String? weatherCode;
  String? lastUpdated;
  String? requestUrl;
  bool isLoading = false;
  bool isCached = false;
  String? errorMessage;

  double? lat;
  double? lon;

  @override
  void initState() {
    super.initState();
    _loadCachedData(indexController.text);
  }

  void _calculateCoords(String index) {
    try {
      int firstTwo = int.parse(index.substring(0, 2));
      int nextTwo = int.parse(index.substring(2, 4));
      lat = 5 + (firstTwo / 10.0);
      lon = 79 + (nextTwo / 10.0);
    } catch (_) {
      lat = null;
      lon = null;
    }
  }

  Future<void> fetchWeather() async {
    final index = indexController.text.trim();
    _calculateCoords(index);

    if (lat == null || lon == null) {
      setState(() => errorMessage = "Invalid index format.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      isCached = false;
    });

    final url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true";
    requestUrl = url;

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['current_weather'];

        setState(() {
          temperature = weather['temperature'].toString();
          windSpeed = weather['windspeed'].toString();
          weatherCode = weather['weathercode'].toString();
          final now = DateTime.now();
          lastUpdated =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'weatherData_$index',
          json.encode({
            'index': index,
            'temperature': temperature,
            'windSpeed': windSpeed,
            'weatherCode': weatherCode,
            'lat': lat,
            'lon': lon,
            'url': url,
            'time': lastUpdated,
          }),
        );
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      bool found = await _loadCachedData(index, showCachedMessage: true);
      if (!found) {
        setState(() {
          errorMessage = "Failed to fetch data. No cached result found.";
          // Clear previous weather data
          temperature = null;
          windSpeed = null;
          weatherCode = null;
          lastUpdated = null;
          requestUrl = null;
          lat = null;
          lon = null;
          isCached = false;
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _loadCachedData(
    String index, {
    bool showCachedMessage = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('weatherData_$index');
    if (cached != null) {
      final data = json.decode(cached);
      setState(() {
        indexController.text = data['index'];
        temperature = data['temperature'];
        windSpeed = data['windSpeed'];
        weatherCode = data['weatherCode'];
        lat = data['lat'];
        lon = data['lon'];
        requestUrl = data['url'];
        lastUpdated = data['time'];
        isCached = showCachedMessage;
      });
      return true;
    }
    return false;
  }

  String _getWeatherDescription(String? code) {
    if (code == null) return 'Unknown';
    switch (code) {
      case '0':
        return 'Clear sky';
      case '1':
      case '2':
      case '3':
        return 'Partly cloudy';
      case '45':
      case '48':
        return 'Foggy';
      case '51':
      case '53':
      case '55':
        return 'Drizzle';
      case '61':
      case '63':
      case '65':
        return 'Rain';
      case '71':
      case '73':
      case '75':
        return 'Snow';
      case '95':
        return 'Thunderstorm';
      default:
        return 'Weather code $code';
    }
  }

  IconData _getWeatherIcon(String? code) {
    if (code == null) return Icons.cloud;
    switch (code) {
      case '0':
        return Icons.wb_sunny;
      case '1':
      case '2':
      case '3':
        return Icons.wb_cloudy;
      case '45':
      case '48':
        return Icons.foggy;
      case '51':
      case '53':
      case '55':
        return Icons.grain;
      case '61':
      case '63':
      case '65':
        return Icons.water_drop;
      case '71':
      case '73':
      case '75':
        return Icons.ac_unit;
      case '95':
        return Icons.thunderstorm;
      default:
        return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightBlue.shade300, Colors.blue.shade900],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Weather App',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Input Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Index (e.g: 224029B)',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.lightBlue.shade700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: indexController,
                              decoration: InputDecoration(
                                hintText: "Enter student index",
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.lightBlue.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.lightBlue.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade900,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            if (lat != null && lon != null) ...[
                              const SizedBox(height: 12),
                              Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        "Indexed Coordinates",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Latitude
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Colors.blue.shade900,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Latitude",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    lat!.toStringAsFixed(4),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.blue.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          // Longitude
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Colors.blue.shade900,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Longitude",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    lon!.toStringAsFixed(4),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.blue.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : fetchWeather,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh),
                                          SizedBox(width: 8),
                                          Text(
                                            'Fetch Weather',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (errorMessage != null)
                      Card(
                        elevation: 4,
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Weather Display Card
                    if (temperature != null)
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              if (isCached)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cached,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cached Data',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),

                              // Weather Icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getWeatherIcon(weatherCode),
                                  size: 64,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Weather Description
                              Text(
                                _getWeatherDescription(weatherCode),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                              ),
                              const SizedBox(height: 4),

                              // Show Weather Code
                              Text(
                                'Weather Code: $weatherCode',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Temperature
                              Text(
                                '$temperature°C',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                              ),
                              const SizedBox(height: 24),

                              // Weather Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _WeatherDetail(
                                    icon: Icons.air,
                                    label: 'Wind Speed',
                                    value: '$windSpeed km/h',
                                  ),
                                  _WeatherDetail(
                                    icon: Icons.access_time,
                                    label: 'Updated',
                                    value: lastUpdated ?? 'N/A',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // API URL
                              if (requestUrl != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'API Endpoint',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        requestUrl!,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade900),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
