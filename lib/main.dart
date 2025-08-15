import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Weather {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final String time;

  Weather({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.time,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] as num).toDouble(),
      windspeed: (json['windspeed'] as num).toDouble(),
      weathercode: json['weathercode'] as int,
      time: json['time'] as String,
    );
  }

  String get weatherDescription {
    switch (weathercode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Mainly clear, partly cloudy, and overcast';
      case 45:
      case 48:
        return 'Fog and depositing rime fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle: Light, moderate, and dense intensity';
      case 61:
      case 63:
      case 65:
        return 'Rain: Slight, moderate and heavy intensity';
      case 80:
      case 81:
      case 82:
        return 'Rain showers: Slight, moderate, and violent';
      default:
        return 'Unknown';
    }
  }

  String get iconUrl {
    if (weathercode == 0) {
      return 'https://cdn-icons-png.flaticon.com/512/869/869869.png';
    } else if ([1, 2, 3].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/1163/1163661.png';
    } else if ([45, 48].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/4005/4005901.png';
    } else if ([51, 53, 55].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/414/414974.png';
    } else if ([61, 63, 65].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/3313/3313887.png';
    } else if ([80, 81, 82].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/1779/1779940.png';
    } else {
      return 'https://cdn-icons-png.flaticon.com/512/869/869869.png';
    }
  }
}

class WeatherLocation {
  final String name;
  final double lat;
  final double lon;

  WeatherLocation({required this.name, required this.lat, required this.lon});
}

class WeatherService {
  static const String apiUrl =
      'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true';

  static Future<Weather> fetchWeather(double lat, double lon) async {
    final url = apiUrl
        .replaceFirst('{lat}', lat.toString())
        .replaceFirst('{lon}', lon.toString());
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final current = data['current_weather'];
      return Weather(
        temperature: (current['temperature'] as num).toDouble(),
        windspeed: (current['windspeed'] as num).toDouble(),
        weathercode: current['weathercode'] as int,
        time: current['time'] as String,
      );
    } else {
      throw Exception('Failed to load weather');
    }
  }

  static Future<List<WeatherWithLocation>> fetchWeatherForLocations(List<WeatherLocation> locations) async {
    List<WeatherWithLocation> result = [];
    for (final loc in locations) {
      try {
        final weather = await fetchWeather(loc.lat, loc.lon);
        result.add(WeatherWithLocation(location: loc, weather: weather));
      } catch (_) {
        // ถ้า error ให้ข้ามหรือจะใส่ error message ก็ได้
      }
    }
    return result;
  }
}

class WeatherWithLocation {
  final WeatherLocation location;
  final Weather weather;

  WeatherWithLocation({required this.location, required this.weather});
}

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static final List<WeatherLocation> locations = [
    WeatherLocation(name: 'San Francisco', lat: 37.7749, lon: -122.4194),
    WeatherLocation(name: 'Bangkok', lat: 13.7563, lon: 100.5018),
    WeatherLocation(name: 'Tokyo', lat: 35.6895, lon: 139.6917),
    WeatherLocation(name: 'London', lat: 51.5074, lon: -0.1278),
    WeatherLocation(name: 'Sydney', lat: -33.8688, lon: 151.2093),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Weather',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<WeatherWithLocation>>(
        future: WeatherService.fetchWeatherForLocations(locations),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบข้อมูลสภาพอากาศ',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final weatherWithLoc = snapshot.data![index];
              return WeatherCard(
                weather: weatherWithLoc.weather,
                locationName: weatherWithLoc.location.name,
              );
            },
          );
        },
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final String? locationName;

  const WeatherCard({super.key, required this.weather, this.locationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weather Icon
              Container(
                width: 120,
                child: Image.network(
                  weather.iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Weather Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (locationName != null) ...[
                        Text(
                          locationName!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather.weatherDescription,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Temperature: ${weather.temperature.toStringAsFixed(1)} °C',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Windspeed: ${weather.windspeed.toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Time: ${weather.time}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

