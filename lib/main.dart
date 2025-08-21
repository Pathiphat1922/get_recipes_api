import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import ไฟล์ weather_detail_screen.dart ที่สร้างไว้
// import 'weather_detail_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        fontFamily: 'Roboto',
      ),
      home: const WeatherScreen(),
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
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Light drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      default:
        return 'Unknown';
    }
  }

  Color get temperatureColor {
    if (temperature >= 30) {
      return const Color(0xFFE57373);
    } else if (temperature >= 20) {
      return const Color(0xFFFFB74D);
    } else if (temperature >= 10) {
      return const Color(0xFF81C784);
    } else {
      return const Color(0xFF64B5F6);
    }
  }

  IconData get weatherIcon {
    switch (weathercode) {
      case 0:
        return Icons.wb_sunny;
      case 1:
      case 2:
      case 3:
        return Icons.wb_cloudy;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
        return Icons.grain;
      case 61:
      case 63:
      case 65:
        return Icons.water_drop;
      case 80:
      case 81:
      case 82:
        return Icons.shower;
      default:
        return Icons.help_outline;
    }
  }

  List<Color> get backgroundGradient {
    if (weathercode == 0) {
      return [
        const Color(0xFF87CEEB),
        const Color(0xFF4FC3F7),
        const Color(0xFF29B6F6),
      ];
    } else if ([1, 2, 3].contains(weathercode)) {
      return [
        const Color(0xFF90A4AE),
        const Color(0xFF78909C),
        const Color(0xFF607D8B),
      ];
    } else if ([45, 48].contains(weathercode)) {
      return [
        const Color(0xFFB0BEC5),
        const Color(0xFF90A4AE),
        const Color(0xFF78909C),
      ];
    } else if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(weathercode)) {
      return [
        const Color(0xFF546E7A),
        const Color(0xFF455A64),
        const Color(0xFF37474F),
      ];
    } else {
      return [
        const Color(0xFF64B5F6),
        const Color(0xFF2196F3),
        const Color(0xFF1976D2),
      ];
    }
  }
}

class WeatherLocation {
  final String name;
  final double lat;
  final double lon;
  final String emoji;

  WeatherLocation({
    required this.name,
    required this.lat,
    required this.lon,
    required this.emoji,
  });
}

class WeatherWithLocation {
  final WeatherLocation location;
  final Weather weather;
  bool isFavorite;

  WeatherWithLocation({
    required this.location,
    required this.weather,
    this.isFavorite = false,
  });
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

  static Future<List<WeatherWithLocation>> fetchWeatherForLocations(
    List<WeatherLocation> locations,
  ) async {
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

// Weather Detail Screen (ใช้แทน import)
class WeatherDetailScreen extends StatefulWidget {
  final WeatherWithLocation weatherWithLocation;
  final VoidCallback? onFavoriteToggle;

  const WeatherDetailScreen({
    super.key,
    required this.weatherWithLocation,
    this.onFavoriteToggle,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconRotateAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _iconRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _iconAnimationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  String _getDetailedDescription() {
    final weather = widget.weatherWithLocation.weather;
    final temp = weather.temperature.toStringAsFixed(1);
    final wind = weather.windspeed.toStringAsFixed(1);

    switch (weather.weathercode) {
      case 0:
        return 'Perfect weather with clear blue skies! Great day for outdoor activities. Temperature is $temp°C with gentle winds at $wind km/h.';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy conditions with some sunshine. A pleasant day with $temp°C and moderate winds at $wind km/h.';
      case 45:
      case 48:
        return 'Foggy conditions reducing visibility. Be careful when driving. Temperature $temp°C with light winds at $wind km/h.';
      case 51:
      case 53:
      case 55:
        return 'Light drizzle in the area. You might want to carry an umbrella. Temperature $temp°C with winds at $wind km/h.';
      case 61:
      case 63:
      case 65:
        return 'Rainy weather today. Perfect for staying indoors with a warm drink. Temperature $temp°C with winds at $wind km/h.';
      case 80:
      case 81:
      case 82:
        return 'Rain showers expected. Don\'t forget your umbrella! Temperature $temp°C with winds at $wind km/h.';
      default:
        return 'Weather conditions are $temp°C with winds at $wind km/h.';
    }
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weather = widget.weatherWithLocation.weather;
    final location = widget.weatherWithLocation.location;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: weather.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        // Custom App Bar
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.weatherWithLocation.isFavorite =
                                        !widget.weatherWithLocation.isFavorite;
                                  });
                                  widget.onFavoriteToggle?.call();
                                },
                                icon: Icon(
                                  widget.weatherWithLocation.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      widget.weatherWithLocation.isFavorite
                                          ? Colors.red[300]
                                          : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Main Weather Display
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Location
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      location.emoji,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        location.name,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Weather Icon
                                AnimatedBuilder(
                                  animation: _iconRotateAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _iconRotateAnimation.value * 0.1,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: Icon(
                                          weather.weatherIcon,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Temperature
                                Text(
                                  '${weather.temperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Weather Description
                                Text(
                                  weather.weatherDescription,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Weather Details Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.1,
                          children: [
                            _buildInfoCard(
                              Icons.thermostat,
                              'Temperature',
                              '${weather.temperature.toStringAsFixed(1)}°C',
                              weather.temperatureColor,
                            ),
                            _buildInfoCard(
                              Icons.air,
                              'Wind Speed',
                              '${weather.windspeed.toStringAsFixed(1)} km/h',
                              const Color(0xFF64B5F6),
                            ),
                            _buildInfoCard(
                              Icons.code,
                              'Weather Code',
                              weather.weathercode.toString(),
                              const Color(0xFF9C27B0),
                            ),
                            _buildInfoCard(
                              Icons.access_time,
                              'Last Updated',
                              weather.time.substring(11, 16),
                              const Color(0xFF4CAF50),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Detailed Description
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF2196F3),
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Weather Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getDetailedDescription(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Coordinates
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.place,
                                    color: Color(0xFF4CAF50),
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Latitude',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          location.lat.toStringAsFixed(4),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Longitude',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          location.lon.toStringAsFixed(4),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Main Weather Screen
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static final List<WeatherLocation> locations = [
    WeatherLocation(
      name: 'San Francisco',
      lat: 37.7749,
      lon: -122.4194,
      emoji: '🌉',
    ),
    WeatherLocation(name: 'Bangkok', lat: 13.7563, lon: 100.5018, emoji: '🏛️'),
    WeatherLocation(name: 'Tokyo', lat: 35.6895, lon: 139.6917, emoji: '🗾'),
    WeatherLocation(name: 'London', lat: 51.5074, lon: -0.1278, emoji: '🏰'),
    WeatherLocation(
      name: 'Sydney',
      lat: -33.8688,
      lon: 151.2093,
      emoji: '🏄‍♂️',
    ),
    WeatherLocation(name: 'Paris', lat: 48.8566, lon: 2.3522, emoji: '🗼'),
    WeatherLocation(name: 'New York', lat: 40.7128, lon: -74.0060, emoji: '🗽'),
    WeatherLocation(name: 'Dubai', lat: 25.2048, lon: 55.2708, emoji: '🏙️'),
  ];

  List<WeatherWithLocation> weatherData = [];
  Set<String> favoriteLocations = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await WeatherService.fetchWeatherForLocations(locations);

      // ตรวจสอบรายการโปรดและจัดเรียง
      for (var item in data) {
        item.isFavorite = favoriteLocations.contains(item.location.name);
      }

      // เรียงลำดับ: รายการโปรดก่อน แล้วตาม name
      _sortWeatherData(data);

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _sortWeatherData(List<WeatherWithLocation> data) {
    data.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.location.name.compareTo(b.location.name);
    });
  }

  void _toggleFavorite(String locationName) {
    setState(() {
      if (favoriteLocations.contains(locationName)) {
        favoriteLocations.remove(locationName);
      } else {
        favoriteLocations.add(locationName);
      }

      // อัปเดต favorite status และจัดเรียงใหม่
      for (var item in weatherData) {
        if (item.location.name == locationName) {
          item.isFavorite = !item.isFavorite;
        }
      }

      // เรียงลำดับใหม่
      _sortWeatherData(weatherData);
    });
  }

  void _navigateToDetail(WeatherWithLocation weatherWithLoc) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => WeatherDetailScreen(
              weatherWithLocation: weatherWithLoc,
              onFavoriteToggle:
                  () => _toggleFavorite(weatherWithLoc.location.name),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF64B5F6),
              Color(0xFF2196F3),
              Color(0xFF1976D2),
              Color(0xFF0D47A1),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Around the World',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _loadWeatherData,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Weather Cards
              Expanded(
                child:
                    isLoading
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Loading weather data...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : error != null
                        ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Color(0xFFE57373),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'เกิดข้อผิดพลาด',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$error',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF757575),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadWeatherData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                        : weatherData.isEmpty
                        ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ไม่พบข้อมูลสภาพอากาศ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: weatherData.length,
                          itemBuilder: (context, index) {
                            final weatherWithLoc = weatherData[index];
                            return WeatherCard(
                              weather: weatherWithLoc.weather,
                              location: weatherWithLoc.location,
                              isFavorite: weatherWithLoc.isFavorite,
                              onTap: () => _navigateToDetail(weatherWithLoc),
                              onFavoriteToggle:
                                  () => _toggleFavorite(
                                    weatherWithLoc.location.name,
                                  ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final WeatherLocation location;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.location,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(0, -1),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Weather Icon Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        weather.temperatureColor.withOpacity(0.2),
                        weather.temperatureColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    weather.weatherIcon,
                    size: 40,
                    color: weather.temperatureColor,
                  ),
                ),
                const SizedBox(width: 20),
                // Weather Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            location.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF424242),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFavorite)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.weatherDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: weather.temperatureColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.thermostat,
                                    size: 16,
                                    color: weather.temperatureColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${weather.temperature.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: weather.temperatureColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64B5F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.air,
                                    size: 16,
                                    color: Color(0xFF64B5F6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${weather.windspeed.toStringAsFixed(1)} km/h',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64B5F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Updated: ${weather.time.substring(11, 16)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
