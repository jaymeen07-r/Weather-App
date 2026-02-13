import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'add_city_page.dart';
import 'map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

String getFormattedDateTime() {
  DateTime now = DateTime.now();
  return DateFormat('EEEE h:mm a').format(now).toUpperCase();
}

String getGreetingMessage() {
  int hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return "GOOD MORNING";
  } else if (hour >= 12 && hour < 17) {
    return "GOOD AFTERNOON";
  } else if (hour >= 17 && hour < 21) {
    return "GOOD EVENING";
  } else {
    return "GOOD NIGHT";
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Position? currentPosition;

  String city = "Loading...";
  String description = "";
  String icon = "";
  double temperature = 0;
  String sunriseTime = "--";
  double windSpeed = 0;
  double visibility = 0;
  int pressure = 0;
  int humidity = 0;
  double airQuality = 75;
  double dewPoint = 0;
  List hourlyForecast = [];
  int aqi = 75;
  double pm2_5 = 0;
  double pm10 = 0;
  final primaryColor = Color(0xFF0B132B);
  final secondColor = Colors.white.withOpacity(0.25);
  final accentColor = Color(0xFF5BC0BE);

  String formatUnixTime(int unix) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return DateFormat('h:mm').format(dt);
  }

  final String apiKey = "3aca61afabcf321d848dc05f6867a520";

  @override
  void initState() {
    super.initState();
    _loadOfflineWeather();
    _getLocationAndWeather();
  }

  Widget _buildFullComparison(dynamic c1, dynamic c2) {
    double dew1 = calculateDewPoint(c1['main']['temp'], c1['main']['humidity']);
    double dew2 = calculateDewPoint(c2['main']['temp'], c2['main']['humidity']);

    return Column(
      children: [
        const Divider(color: Colors.white54),

        _compareRow(
          "Temperature",
          "${c1['main']['temp']}°C",
          "${c2['main']['temp']}°C",
        ),

        _compareRow(
          "Humidity",
          "${c1['main']['humidity']}%",
          "${c2['main']['humidity']}%",
        ),

        _compareRow(
          "Wind",
          "${c1['wind']['speed']} m/s",
          "${c2['wind']['speed']} m/s",
        ),

        _compareRow(
          "Pressure",
          "${c1['main']['pressure']} hPa",
          "${c2['main']['pressure']} hPa",
        ),

        _compareRow(
          "Visibility",
          "${(c1['visibility'] / 1000).toStringAsFixed(1)} km",
          "${(c2['visibility'] / 1000).toStringAsFixed(1)} km",
        ),

        _compareRow(
          "Dew Point",
          "${dew1.toStringAsFixed(1)}°C",
          "${dew2.toStringAsFixed(1)}°C",
        ),

        _compareRow(
          "Sunrise",
          formatUnixTime(c1['sys']['sunrise']),
          formatUnixTime(c2['sys']['sunrise']),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showCompareDialog() {
    TextEditingController city1Controller = TextEditingController();
    TextEditingController city2Controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // ❗ Prevent tap outside dismiss
      enableDrag: false, // ❗ Prevent swipe down dismiss
      builder: (context) {
        bool isLoading = false;
        Map<String, dynamic>? city1Data;
        Map<String, dynamic>? city2Data;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> compareCities() async {
              if (city1Controller.text.isEmpty || city2Controller.text.isEmpty)
                return;

              setModalState(() => isLoading = true);

              final url1 = Uri.parse(
                "https://api.openweathermap.org/data/2.5/weather?q=${city1Controller.text}&appid=$apiKey&units=metric",
              );

              final url2 = Uri.parse(
                "https://api.openweathermap.org/data/2.5/weather?q=${city2Controller.text}&appid=$apiKey&units=metric",
              );

              final response1 = await http.get(url1);
              final response2 = await http.get(url2);

              if (response1.statusCode == 200 && response2.statusCode == 200) {
                city1Data = jsonDecode(response1.body);
                city2Data = jsonDecode(response2.body);
              }

              setModalState(() => isLoading = false);
            }

            return Stack(
              children: [
                /// 🔵 BLUR BACKGROUND
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),

                /// 🔵 MAIN POPUP
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 25,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text(
                            "Compare Cities",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(city1Controller, "First City"),
                          const SizedBox(height: 15),
                          _buildTextField(city2Controller, "Second City"),

                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 55),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: compareCities,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text("Compare"),
                                ),
                                SizedBox(width: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: const Text(
                                    "Close",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (isLoading)
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),

                          if (city1Data != null && city2Data != null)
                            _buildFullComparison(city1Data!, city2Data!),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildComparison(dynamic c1, dynamic c2) {
    return Column(
      children: [
        const Divider(color: Colors.white54),
        const SizedBox(height: 15),

        _compareRow(
          "Temperature",
          "${c1['main']['temp']}°C",
          "${c2['main']['temp']}°C",
        ),

        _compareRow(
          "Humidity",
          "${c1['main']['humidity']}%",
          "${c2['main']['humidity']}%",
        ),

        _compareRow(
          "Wind",
          "${c1['wind']['speed']} m/s",
          "${c2['wind']['speed']} m/s",
        ),

        _compareRow(
          "Pressure",
          "${c1['main']['pressure']} hPa",
          "${c2['main']['pressure']} hPa",
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showComparisonResult(dynamic city1, dynamic city2) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[900],
          title: const Text(
            "Weather Comparison",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${city1['name']} vs ${city2['name']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                _compareRow(
                  "Temperature",
                  "${city1['main']['temp']}°C",
                  "${city2['main']['temp']}°C",
                ),

                _compareRow(
                  "Humidity",
                  "${city1['main']['humidity']}%",
                  "${city2['main']['humidity']}%",
                ),

                _compareRow(
                  "Wind Speed",
                  "${city1['wind']['speed']} m/s",
                  "${city2['wind']['speed']} m/s",
                ),

                _compareRow(
                  "Pressure",
                  "${city1['main']['pressure']} hPa",
                  "${city2['main']['pressure']} hPa",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _compareRow(String label, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(value1, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value2,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _loadOfflineWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      city = prefs.getString('last_city') ?? "Loading...";
      temperature = prefs.getDouble('last_temp') ?? 0;
      description = prefs.getString('last_desc') ?? "";
      sunriseTime = prefs.getString('last_sunrise') ?? "--";
      windSpeed = prefs.getDouble('last_wind') ?? 0;
      humidity = prefs.getInt('last_humidity') ?? 0;
      pressure = prefs.getInt('last_pressure') ?? 0;
    });
  }

  Future<LatLng> getCityCoordinates(String cityName) async {
    List<Location> locations = await locationFromAddress(cityName);
    if (locations.isNotEmpty) {
      return LatLng(locations[0].latitude, locations[0].longitude);
    } else {
      throw Exception("City not found");
    }
  }

  Future<void> _fetchHourlyWeather(String cityName) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$apiKey&units=metric",
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        hourlyForecast = data['list'].take(6).toList();
      });
    }
  }

  Future<void> _fetchAQI(double lat, double lon) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey",
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        aqi = data['list'][0]['main']['aqi'];
        pm2_5 = data['list'][0]['components']['pm2_5'];
        pm10 = data['list'][0]['components']['pm10'];
      });
    }
  }

  String getAQIText(int aqi) {
    switch (aqi) {
      case 1:
        return "Good 😊";
      case 2:
        return "Fair 🙂";
      case 3:
        return "Moderate 😐";
      case 4:
        return "Poor 😷";
      case 5:
        return "Very Poor ⚠️";
      default:
        return "Unknown";
    }
  }

  Future<void> _getLocationAndWeather() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => city = "Permission Denied");
        return;
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _fetchAQI(currentPosition!.latitude, currentPosition!.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      String currentCity = placemarks[0].locality ?? "Unknown";

      await _fetchWeather(currentCity);
      print(city);
    } catch (e) {
      setState(() => city = "Error: $e");
    }
  }

  double calculateDewPoint(double temp, int humidity) {
    return temp - ((100 - humidity) / 5);
  }

  Future<void> _fetchWeather(String cityName) async {
    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric",
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          city = data['name'];
          description = data['weather'][0]['main'];
          icon = data['weather'][0]['icon'];
          temperature = data['main']['temp'];
          int sunriseUnix = data['sys']['sunrise'];
          sunriseTime = formatUnixTime(sunriseUnix);
          windSpeed = data['wind']['speed'];
          visibility = (data['visibility'] ?? 0) / 1000;
          pressure = data['main']['pressure'];
          humidity = data['main']['humidity'];
          dewPoint = calculateDewPoint(temperature, humidity);
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('last_city', city);
        prefs.setDouble('last_temp', temperature);
        prefs.setString('last_desc', description);
        prefs.setString('last_sunrise', sunriseTime);
        prefs.setDouble('last_wind', windSpeed);
        prefs.setInt('last_humidity', humidity);
        prefs.setInt('last_pressure', pressure);
      } else {
        setState(() => city = "City not found");
      }
    } catch (e) {
      setState(() => city = "Ahmedabad");
    }
    _fetchHourlyWeather(cityName);
  }

  Widget _buildInfoColumn({
    required String iconUrl,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(iconUrl, width: MediaQuery.of(context).size.width * 0.08),
        SizedBox(height: MediaQuery.of(context).size.height * 0.008),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Text(
          "│",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A2A72), // Top (night blue)
                Color(0xFF009FFD), // Middle (sky blue)
                Color(0xFF00C6FF), // Bottom (light sky)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 45),
                Padding(
                  padding: const EdgeInsets.only(right: 300),
                  child: GestureDetector(
                    child: Icon(Icons.menu, color: Colors.white),
                    onTap: () async {
                      final newCity = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddCityPage()),
                      );

                      if (newCity != null && newCity.toString().isNotEmpty) {
                        _fetchWeather(newCity);
                      }
                    },
                  ),
                ),
                Text(
                  city,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  getFormattedDateTime(),
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                SizedBox(height: 80),
                Column(
                  children: [
                    if (icon.isEmpty)
                      SizedBox(
                        height: 170,
                        child: const Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                      ),

                    if (icon.isNotEmpty)
                      SizedBox(
                        height: 170,
                        child: icon.isNotEmpty
                            ? Image.network(
                                description == "Clear"
                                    ? "https://img.icons8.com/?size=256&id=xWIZQJTeNHmJ&format=png"
                                    : description == "Smoke"
                                    ? "https://img.icons8.com/?size=256&id=DFREO1i3Tfa8&format=png"
                                    : description == "Clouds"
                                    ? "https://img.icons8.com/?size=60&id=Qb0bo60oUIkx&format=png"
                                    : description == "Strom"
                                    ? "https://img.icons8.com/?size=60&id=ezR5QOXjCIPR&format=png"
                                    : description == "Rain"
                                    ? "https://img.icons8.com/?size=60&id=QApkqtngP0RV&format=png"
                                    : description == "Snow"
                                    ? "https://img.icons8.com/?size=60&id=hz3IyqvNkSYX&format=png"
                                    : description == "Haze"
                                    ? "https://img.icons8.com/?size=60&id=7WQzKVrx2nlD&format=png"
                                    : description == "Wind"
                                    ? "https://img.icons8.com/?size=60&id=XNMn9wVFp8dJ&format=png"
                                    : description == "Dry"
                                    ? "https://img.icons8.com/?size=60&id=VEkUMQgJv05z&format=png"
                                    : description == "Sleet"
                                    ? "https://img.icons8.com/?size=60&id=2N2doKekWFUl&format=png"
                                    : description == "Fog"
                                    ? "https://img.icons8.com/?size=60&id=ZBfBCaELdssK&format=png"
                                    : description == "Wet"
                                    ? "https://img.icons8.com/?size=60&id=H3KbH1J8KKGZ&format=png"
                                    : "https://img.icons8.com/?size=256&id=xWIZQJTeNHmJ&format=png",
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                              )
                            : const SizedBox(),
                      ),
                    const SizedBox(height: 70),
                    Text(
                      "${temperature.toStringAsFixed(1)}°C",
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      getGreetingMessage(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description.isEmpty ? "Fetching weather..." : description,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 150,
                      child: hourlyForecast.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: hourlyForecast.length,
                              itemBuilder: (context, index) {
                                var item = hourlyForecast[index];

                                DateTime time = DateTime.parse(item['dt_txt']);
                                String hour = DateFormat('h a').format(time);

                                double temp = item['main']['temp'];
                                String desc = item['weather'][0]['main'];

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  width: 103,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        hour,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Image.network(
                                        desc == "Clear"
                                            ? "https://img.icons8.com/?size=60&id=xWIZQJTeNHmJ&format=png"
                                            : desc == "Rain"
                                            ? "https://img.icons8.com/?size=60&id=QApkqtngP0RV&format=png"
                                            : "https://img.icons8.com/?size=60&id=Qb0bo60oUIkx&format=png",
                                        width: 40,
                                      ),

                                      const SizedBox(height: 8),
                                      Text(
                                        "${temp.toStringAsFixed(0)}°C",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.03,
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=dtWnrVFqkUib&format=png',
                            label: 'SUNRISE',
                            value: sunriseTime,
                          ),
                          _buildVerticalDivider(context),
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=UxvbhlHDl0iU&format=png',
                            label: 'TEMPERATURE',
                            value: "${temperature.toStringAsFixed(0)}°",
                          ),
                          _buildVerticalDivider(context),
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=XNMn9wVFp8dJ&format=png',
                            label: 'WIND',
                            value: "${windSpeed.toStringAsFixed(1)} m/s",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.03,
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=2u4BhhlKcUe5&format=png',
                            label: 'VISIBILITY',
                            value: "${visibility.toStringAsFixed(1)} km",
                          ),
                          _buildVerticalDivider(context),
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=t9oYX8LsUYdk&format=png',
                            label: 'AIR QUALITY',
                            value: airQuality.toStringAsFixed(0),
                          ),
                          _buildVerticalDivider(context),
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=fz7uzhEJt0sC&format=png',
                            label: 'HUMIDITY',
                            value: "$humidity%",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.03,
                        horizontal: MediaQuery.of(context).size.width * 0.14,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=59DEoRp1Krqu&format=png',
                            label: 'PRESSURE',
                            value: "$pressure hPa",
                          ),
                          _buildVerticalDivider(context),
                          _buildInfoColumn(
                            iconUrl:
                                'https://img.icons8.com/?size=60&id=nBxxj2r1YGsE&format=png',
                            label: 'DEW POINT',
                            value: "${dewPoint.toStringAsFixed(1)}°C",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          print("Compare Clicked");
                          _showCompareDialog();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.04,
                          ),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.network(
                                'https://img.icons8.com/?size=80&id=YAHIpxRx0NGS&format=png',
                                width: 50,
                              ),
                              const SizedBox(width: 15),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Compare Cities",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Tap to compare weather",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 25),
                    GestureDetector(
                      onTap: () async {
                        try {
                          LatLng cityCoords = await getCityCoordinates(city);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WeatherMapPage(
                                lat: cityCoords.latitude,
                                lon: cityCoords.longitude,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Unable to find city coordinates"),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                        ),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.network(
                              'https://img.icons8.com/?size=60&id=Kh9y4bxkctIl&format=png',
                              width: 50,
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Live Weather Map",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Tap to view temperature & wind",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
