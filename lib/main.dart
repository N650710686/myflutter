import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Air Quality App',
      home: AirQualityScreen(),
    );
  }
}

class AirQuality {
  final int aqi;
  final String city;
  final double temperature;

  AirQuality({required this.aqi, required this.city, required this.temperature});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      aqi: json['data']['aqi'],
      city: json['data']['city']['name'],
      temperature: (json['data']['iaqi']['t']['v']).toDouble(),
    );
  }
}

class ApiService {
  final String token =
      "9d8f74b7b3699a9445175b479ba9ae3323de9112"; // ใช้ Token ของคุณ

  Future<AirQuality> fetchAirQuality(String city) async {
    final url = Uri.parse("https://api.waqi.info/feed/$city/?token=$token");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return AirQuality.fromJson(jsonData);
    } else {
      throw Exception("Failed to load data");
    }
  }
}

class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({super.key});

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  final ApiService apiService = ApiService();
  late Future<AirQuality> futureAirQuality;

  @override
  void initState() {
    super.initState();
    futureAirQuality = apiService.fetchAirQuality("Bangkok"); // ค่า default
  }

  String getAirQualityLevel(int aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy for Sensitive Groups";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF90CAF9), Color(0xFFA5D6A7)], // ฟ้า → เขียวอ่อน
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<AirQuality>(
            future: futureAirQuality,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData) {
                return const Center(child: Text("No data"));
              }

              final air = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Air Quality Index (AQI)",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 30, color: Colors.white),
                      Text(
                        air.city,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${air.aqi}",
                    style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text("µg/m³",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 20),
                  Text(
                    "Temperature : ${air.temperature} °C",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Air Quality",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  Text(
                    getAirQualityLevel(air.aqi),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      setState(() {
                        futureAirQuality = apiService.fetchAirQuality("Bangkok");
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
