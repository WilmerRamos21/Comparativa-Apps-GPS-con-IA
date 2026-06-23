import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const GpsApp());
}

// ──────────────────────────────────────────────
// Root App
// ──────────────────────────────────────────────
class GpsApp extends StatelessWidget {
  const GpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFF7C4DFF),
          surface: const Color(0xFF1A1A2E),
          onPrimary: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const GpsHomePage(),
    );
  }
}

// ──────────────────────────────────────────────
// GPS Status enum
// ──────────────────────────────────────────────
enum GpsStatus { idle, loading, success, error }

// ──────────────────────────────────────────────
// Home Page
// ──────────────────────────────────────────────
class GpsHomePage extends StatefulWidget {
  const GpsHomePage({super.key});

  @override
  State<GpsHomePage> createState() => _GpsHomePageState();
}

class _GpsHomePageState extends State<GpsHomePage>
    with TickerProviderStateMixin {
  GpsStatus _status = GpsStatus.idle;
  Position? _position;
  String _errorMessage = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Core GPS logic ──────────────────────────
  Future<void> _fetchLocation() async {
    setState(() {
      _status = GpsStatus.loading;
      _errorMessage = '';
      _position = null;
    });
    _fadeController.reset();

    try {
      // 1. Check if location services are enabled on the device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          '📡 GPS desactivado',
          'Los servicios de ubicación están apagados en tu dispositivo.\n\n'
          'Ve a Ajustes → Privacidad y Seguridad → Localización y actívalos.',
        );
        return;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. Request permission if not yet granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError(
            '🔒 Permiso denegado',
            'La aplicación necesita acceso a la ubicación para funcionar.\n\n'
            'Toca "Reintentar" o ve a Ajustes → flutter_gps → Localización.',
          );
          return;
        }
      }

      // 4. Handle permanently denied case
      if (permission == LocationPermission.deniedForever) {
        _setError(
          '🚫 Permiso bloqueado permanentemente',
          'Has bloqueado el acceso a la ubicación de forma permanente.\n\n'
          'Ve a Ajustes → flutter_gps → Localización y selecciona "Al usar la app".',
        );
        return;
      }

      // 5. Get the actual position (high accuracy, 15 s timeout)
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _position = position;
        _status = GpsStatus.success;
      });
      _fadeController.forward();
    } on LocationServiceDisabledException {
      _setError(
        '📡 GPS desactivado',
        'Los servicios de ubicación están apagados en tu dispositivo.\n\n'
        'Ve a Ajustes → Privacidad y Seguridad → Localización y actívalos.',
      );
    } on PermissionDeniedException catch (e) {
      _setError('🔒 Permiso denegado', e.message ?? 'Permiso de ubicación denegado.');
    } on TimeoutException {
      _setError(
        '⏱ Tiempo de espera agotado',
        'No se pudo obtener la ubicación en 15 segundos.\n\n'
        'Asegúrate de tener buena señal GPS o Wi-Fi y vuelve a intentarlo.',
      );
    } catch (e) {
      _setError(
        '⚠️ Error inesperado',
        'Ocurrió un error al obtener la ubicación:\n$e',
      );
    }
  }

  void _setError(String title, String detail) {
    setState(() {
      _status = GpsStatus.error;
      _errorMessage = '$title\n\n$detail';
    });
    _fadeController.forward();
  }

  // ── Open iOS/Android location settings ───────
  Future<void> _openSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildGpsButton(),
              const SizedBox(height: 40),
              Expanded(child: _buildResultPanel()),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.gps_fixed_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS Tracker',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Ubicación en tiempo real',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── GPS Button ───────────────────────────────
  Widget _buildGpsButton() {
    final bool isLoading = _status == GpsStatus.loading;

    return Center(
      child: ScaleTransition(
        scale: isLoading ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: GestureDetector(
          onTap: isLoading ? null : _fetchLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isLoading
                    ? [const Color(0xFF7C4DFF), const Color(0xFF3D1A8C)]
                    : [const Color(0xFF00E5FF), const Color(0xFF0077B6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: isLoading
                      ? const Color(0xFF7C4DFF).withOpacity(0.5)
                      : const Color(0xFF00E5FF).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? const Column(
                      key: ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Buscando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      key: ValueKey('idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Obtener\nUbicación',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Result Panel ─────────────────────────────
  Widget _buildResultPanel() {
    if (_status == GpsStatus.idle) return _buildIdleHint();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _status == GpsStatus.success && _position != null
            ? _buildSuccessCard(_position!)
            : _status == GpsStatus.error
            ? _buildErrorCard()
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildIdleHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 40,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Pulsa el botón para\nobtener tu ubicación',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Success Card ─────────────────────────────
  Widget _buildSuccessCard(Position pos) {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF00E5FF),
                ),
                SizedBox(width: 6),
                Text(
                  'Ubicación obtenida',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _coordRow(Icons.location_on_rounded, 'Latitud',
              '${pos.latitude.toStringAsFixed(6)}°'),
          const SizedBox(height: 14),
          _coordRow(Icons.explore_rounded, 'Longitud',
              '${pos.longitude.toStringAsFixed(6)}°'),
          const SizedBox(height: 14),
          _coordRow(Icons.height_rounded, 'Altitud',
              '${pos.altitude.toStringAsFixed(1)} m'),
          const SizedBox(height: 14),
          _coordRow(Icons.speed_rounded, 'Velocidad',
              '${(pos.speed * 3.6).toStringAsFixed(1)} km/h'),
          const SizedBox(height: 14),
          _coordRow(Icons.radar_rounded, 'Precisión',
              '±${pos.accuracy.toStringAsFixed(0)} m'),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchLocation,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar ubicación'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7C4DFF)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Error Card ───────────────────────────────
  Widget _buildErrorCard() {
    final bool showSettingsButton =
        _errorMessage.contains('bloqueado permanentemente') ||
        _errorMessage.contains('desactivado');

    return Container(
      key: const ValueKey('error'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF4D6D).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D6D).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D6D).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Color(0xFFFF4D6D),
                ),
                SizedBox(width: 6),
                Text(
                  'Error de ubicación',
                  style: TextStyle(
                    color: Color(0xFFFF4D6D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fetchLocation,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4D6D),
                    side: const BorderSide(color: Color(0xFFFF4D6D)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (showSettingsButton) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Ajustes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
