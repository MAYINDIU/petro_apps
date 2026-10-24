import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/widgets/dashboard_widgets.dart';
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:petro_app/widgets/page_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DriverQrCodeScreen extends StatefulWidget {
  const DriverQrCodeScreen({super.key});

  @override
  State<DriverQrCodeScreen> createState() => _DriverQrCodeScreenState();
}

class _DriverQrCodeScreenState extends State<DriverQrCodeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String? _errorMessage;
  Map<String, dynamic>? _qrData;
  bool _isLoading = true;

  // Laser line sweeping over the QR code
  late final AnimationController _scanController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getDriverQrCode();
      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] != null) {
            _qrData = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Failed to load QR Code.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFuelDeepNavy,
      body: FuelAnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'My Fuel Pass',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Fuel authentication',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _isLoading ? () {} : _fetchQrCode,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_qrData == null) {
      return _buildErrorState(message: 'No QR data available.');
    }

    final qrPayload = _qrData!['qr_payload'] as String?;
    final driver = _qrData!['driver'] as Map<String, dynamic>?;
    final assignment = _qrData!['assignment'] as Map<String, dynamic>?;
    final vehicle = assignment?['vehicle'] as Map<String, dynamic>?;
    final wallet = _qrData!['wallet'] as Map<String, dynamic>?;

    final String driverName = driver?['name']?.toString() ?? 'Driver';
    final String plateNumber = vehicle?['plate_number']?.toString() ?? 'N/A';
    final double balance =
        double.tryParse(wallet?['balance']?.toString() ?? '0') ?? 0;

    if (qrPayload == null) {
      return _buildErrorState(message: 'QR payload could not be generated.');
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(
              scale: 0.9 + v * 0.1,
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: Column(
              children: [
                _buildTicket(qrPayload, driverName, plateNumber, balance),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Keep this code private. Refresh if the station '
                        'cannot scan it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _ticketFooterHeight = 84;

  Widget _buildTicket(
    String qrPayload,
    String driverName,
    String plateNumber,
    double balance,
  ) {
    return PhysicalShape(
      clipper: const _TicketClipper(notchFromBottom: _ticketFooterHeight),
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black54,
      child: Column(
        children: [
          // Driver + vehicle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                FuelAvatar(name: driverName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextColorDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kFuelAmber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kFuelOrange.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bus_rounded,
                              size: 13,
                              color: kFuelOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plateNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Color(0xFF9A3412),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.local_gas_station_rounded,
                  color: kFuelBlue,
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR code with corner brackets and laser line
          SizedBox(
            width: 236,
            height: 236,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(236, 236),
                  painter: _CornerBracketsPainter(color: kFuelBlue),
                ),
                QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: kFuelDeepNavy,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: kFuelDeepNavy,
                  ),
                ),
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, _) {
                    final y =
                        -92 +
                        184 * Curves.easeInOut.transform(_scanController.value);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 200,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              kFuelOrange.withOpacity(0),
                              kFuelOrange,
                              kFuelOrange.withOpacity(0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kFuelOrange.withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 16,
                  color: kHintColor,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Show this to the station attendant',
                    style: TextStyle(color: kHintColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Dashed tear line between the notches
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _DashedLine(),
          ),

          // Balance footer
          SizedBox(
            height: _ticketFooterHeight - 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kFuelAmber, kFuelOrange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Available balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: kHintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: balance),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, _) => Text(
                      '৳ ${NumberFormat('#,##0.00').format(value)}',
                      style: const TextStyle(
                        color: kFuelBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: FuelStateView.error(
              title: 'QR code unavailable',
              message: message ?? _errorMessage,
              onRetry: _fetchQrCode,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded ticket with two semicircle notches [notchFromBottom] px above
/// the bottom edge.
class _TicketClipper extends CustomClipper<Path> {
  final double notchFromBottom;
  const _TicketClipper({required this.notchFromBottom});

  @override
  Path getClip(Size size) {
    const radius = 26.0;
    const notch = 14.0;
    final y = size.height - notchFromBottom;
    final ticket = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(radius),
        ),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notch));
    return Path.combine(PathOperation.difference, ticket, notches);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.notchFromBottom != notchFromBottom;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 6.0, gap = 5.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dash,
              height: 1.5,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        );
      },
    );
  }
}

/// Four rounded corner brackets framing the QR code.
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0, r = 12.0;
    final w = size.width, h = size.height;

    void corner(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * len)
        ..lineTo(o.dx, o.dy + sy * r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + sx * r, o.dy)
        ..lineTo(o.dx + sx * len, o.dy);
      canvas.drawPath(path, paint);
    }

    corner(const Offset(2, 2), 1, 1);
    corner(Offset(w - 2, 2), -1, 1);
    corner(Offset(2, h - 2), 1, -1);
    corner(Offset(w - 2, h - 2), -1, -1);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}
