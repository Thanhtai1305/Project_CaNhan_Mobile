import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  );
}

// Models
class WeatherData {
  final double temp, feelsLike, windSpeed;
  final String condition, icon;
  final int humidity;
  final DateTime lastUpdated;
  final List<ForecastDay> forecasts;

  WeatherData({required this.temp, required this.condition, required this.icon, 
    required this.feelsLike, required this.humidity, required this.windSpeed, 
    required this.lastUpdated, required this.forecasts});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return WeatherData(
      temp: current['temp_c'].toDouble(),
      condition: current['condition']['text'],
      icon: current['condition']['icon'],
      feelsLike: current['feelslike_c'].toDouble(),
      humidity: current['humidity'],
      windSpeed: current['wind_kph'].toDouble(),
      lastUpdated: DateTime.parse(current['last_updated']),
      forecasts: (json['forecast']['forecastday'] as List)
          .map((f) => ForecastDay.fromJson(f)).toList(),
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double maxTemp, minTemp;
  final String condition, icon;

  ForecastDay({required this.date, required this.maxTemp, required this.minTemp, 
    required this.condition, required this.icon});

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    return ForecastDay(
      date: DateTime.parse(json['date']),
      maxTemp: day['maxtemp_c'].toDouble(),
      minTemp: day['mintemp_c'].toDouble(),
      condition: day['condition']['text'],
      icon: day['condition']['icon'],
    );
  }
}

// Service
class WeatherService {
  static const _apiKey = '251861f92d164c5e95e85153250205';
  static const _baseUrl = 'https://api.weatherapi.com/v1';

  Future<WeatherData> getWeatherData(String city) async {
    final response = await http.get(Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=5&aqi=no&alerts=no'));

    if (response.statusCode == 200) {
      print('=== JSON TRẢ VỀ TỪ API ===');
      print(response.body); // 👉 in JSON tại đây
      return WeatherData.fromJson(jsonDecode(response.body));
    }

    throw Exception('Lỗi: ${response.statusCode}');
  }
}

// Main Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = WeatherService();
  WeatherData? _data;
  bool _loading = true;
  String _error = '', _city = 'Hà Nội';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getWeatherData(_city);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error.isNotEmpty) return Scaffold(body: Center(child: Text(_error)));
    if (_data == null) return const Scaffold(body: Center(child: Text('Không có dữ liệu')));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _LocationSearch(
                city: _city,
                onChanged: (city) {
                  _city = city;
                  _loadData();
                },
              ),
              _WeatherHeader(_city, _data!),
              _WeatherDetails(_data!),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Dự báo 5 ngày tới', style: Theme.of(context).textTheme.titleLarge),
              ),
              _ForecastList(_data!.forecasts),
            ],
          ),
        ),
      ),
    );
  }
}

// Widgets
class _LocationSearch extends StatefulWidget {
  final String city;
  final Function(String) onChanged;
  const _LocationSearch({required this.city, required this.onChanged});
  @override State<_LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<_LocationSearch> {
  late final _controller = TextEditingController(text: widget.city);
  final _cities = ['Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Huế', 'Nha Trang', 'Đà Lạt', 'Hải Phòng', 'Cần Thơ'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thành phố...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (v) => v.isNotEmpty ? widget.onChanged(v) : null,
          ),
          const SizedBox(height: 16),
          Text('Thành phố phổ biến', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _cities.map((city) => InkWell(
              onTap: () {
                _controller.text = city;
                widget.onChanged(city);
              },
              child: Chip(label: Text(city), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  final String city;
  final WeatherData data;
  const _WeatherHeader(this.city, this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(city, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('${data.temp.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(data.condition, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text('Cập nhật: ${DateFormat('HH:mm - dd/MM/yyyy').format(data.lastUpdated)}', 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _WeatherDetails extends StatelessWidget {
  final WeatherData data;
  const _WeatherDetails(this.data);

  Widget _item(BuildContext context, IconData icon, String label, String value) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
      const SizedBox(height: 8),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text('Chi tiết', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, Icons.thermostat, 'Nhiệt độ', '${data.feelsLike.toStringAsFixed(1)}°C'),
              _item(context, Icons.water_drop, 'Độ ẩm', '${data.humidity}%'),
              _item(context, Icons.air, 'Gió', '${data.windSpeed} km/h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastList extends StatelessWidget {
  final List<ForecastDay> forecasts;
  const _ForecastList(this.forecasts);

  Widget _item(BuildContext context, ForecastDay f) => Container(
    width: 120,
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.122), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(DateFormat('E, dd/MM').format(f.date), style: Theme.of(context).textTheme.titleSmall),
        Image.network('https:${f.icon}', width: 50, height: 50, 
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50)),
        Text(f.condition, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${f.minTemp.toInt()}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue)),
            const SizedBox(width: 8),
            Text('${f.maxTemp.toInt()}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: forecasts.length,
        itemBuilder: (context, i) => _item(context, forecasts[i]),
      ),
    );
  }
}
