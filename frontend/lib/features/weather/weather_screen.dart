import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/weather.dart';
import '../../shared/services/weather_service.dart';
import '../../shared/widgets/common_widgets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _locationController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  WeatherInfo? _weather;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final t = AppLocalizations.of(context)!;
    final location = _locationController.text.trim();
    if (location.isEmpty) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final weather = await WeatherService.instance.getWeather(location);
      if (mounted) setState(() => _weather = weather);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.weather)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: t.enterLocation, border: const OutlineInputBorder()),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _loading ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const LoadingView(),
          if (_errorMessage != null) ErrorView(message: _errorMessage!, onRetry: _search),
          if (_weather != null) ...[
            Text(t.currentWeather, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.currentWeather, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_weather!.location, style: Theme.of(context).textTheme.titleLarge),
                      Text('${_weather!.temperatureC.toStringAsFixed(0)}°C',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  Text(_weather!.description),
                  const Divider(height: 24),
                  _StatRow(icon: Icons.water_drop_outlined, label: t.humidity, value: '${_weather!.humidityPct.toStringAsFixed(0)}%'),
                  _StatRow(icon: Icons.grain, label: t.rainfall, value: '${_weather!.rainfallMmLastHour.toStringAsFixed(1)} mm'),
                  _StatRow(icon: Icons.air, label: 'Wind', value: '${_weather!.windSpeedMs.toStringAsFixed(1)} m/s'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.agriAdvisories, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _weather!.advisories
                    .map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
