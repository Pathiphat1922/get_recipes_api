import 'package:flutter/material.dart';

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
      // Clear sky - สีฟ้าใส
      return [
        const Color(0xFF87CEEB),
        const Color(0xFF4FC3F7),
        const Color(0xFF29B6F6),
      ];
    } else if ([1, 2, 3].contains(weathercode)) {
      // Partly cloudy - สีเทาอ่อน
      return [
        const Color(0xFF90A4AE),
        const Color(0xFF78909C),
        const Color(0xFF607D8B),
      ];
    } else if ([45, 48].contains(weathercode)) {
      // Foggy - สีเทาหมอก
      return [
        const Color(0xFFB0BEC5),
        const Color(0xFF90A4AE),
        const Color(0xFF78909C),
      ];
    } else if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(weathercode)) {
      // Rainy - สีเทาเข้ม
      return [
        const Color(0xFF546E7A),
        const Color(0xFF455A64),
        const Color(0xFF37474F),
      ];
    } else {
      // Default
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
