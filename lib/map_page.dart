import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WeatherMapPage extends StatelessWidget {
  final double lat;
  final double lon;

  const WeatherMapPage({required this.lat, required this.lon, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lon),
          initialZoom: 8,
          minZoom: 2,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.aoctomeater",
          ),
          TileLayer(
            urlTemplate:
                "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=3aca61afabcf321d848dc05f6867a520",
            userAgentPackageName: "com.example.aoctomeater",
          ),
        ],
      ),
    );
  }
}
