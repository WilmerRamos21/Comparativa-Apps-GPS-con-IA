import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const GpsApp());
}

class GpsApp extends StatelessWidget {
  const GpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const GpsHomePage(),
    );
  }
}

class GpsHomePage extends StatefulWidget {
  const GpsHomePage({super.key});

  @override
  State<GpsHomePage> createState() => _GpsHomePageState();
}

class _GpsHomePageState extends State<GpsHomePage> {
  Position? _position;
  String _message = 'Pulsa el botón para obtener tu ubicación.';
  bool _loading = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
      _message = 'Comprobando permisos y GPS...';
      _position = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _message =
              'El GPS o los servicios de ubicación están desactivados. Actívalos en Ajustes e inténtalo de nuevo.';
        });
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _message =
              'Permiso de ubicación denegado. La app necesita acceso a la ubicación para usar el GPS.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _message =
              'Permiso de ubicación denegado permanentemente. Debes habilitarlo manualmente en Ajustes.';
        });
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _position = position;
        _message = 'Ubicación obtenida correctamente.';
      });
    } on TimeoutException {
      setState(() {
        _message =
            'No se pudo obtener la ubicación a tiempo. Intenta de nuevo en un lugar con mejor señal GPS.';
      });
    } catch (error) {
      setState(() {
        _message = 'Ocurrió un error al obtener la ubicación: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS con Geolocator'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.location_on,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (position != null) ...[
                _InfoRow(label: 'Latitud', value: '${position.latitude}'),
                _InfoRow(label: 'Longitud', value: '${position.longitude}'),
                _InfoRow(
                  label: 'Precisión',
                  value: '${position.accuracy.toStringAsFixed(1)} m',
                ),
                _InfoRow(
                  label: 'Altitud',
                  value: '${position.altitude.toStringAsFixed(1)} m',
                ),
                const SizedBox(height: 24),
              ],
              FilledButton.icon(
                onPressed: _loading ? null : _getCurrentLocation,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(_loading ? 'Obteniendo ubicación...' : 'Usar GPS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}