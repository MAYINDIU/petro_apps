import 'dart:math' as math;

import 'package:flutter/material.dart';

// Shared fuel / cashless theme colors and animated widgets used by the
// authentication screens (login, register).
const Color kFuelDeepNavy = Color(0xFF0B1F5C);
const Color kFuelBlue = Color(0xFF1E40AF);
const Color kFuelCyan = Color(0xFF0EA5E9);
const Color kFuelAmber = Color(0xFFFBBF24);
const Color kFuelOrange = Color(0xFFF97316);

/// Full-screen animated background: shifting gradient, drifting fuel and
/// payment icons, rising fuel drops and layered waves at the bottom.
class FuelAnimatedBackground extends StatefulWidget {
  final Widget child;
  const FuelAnimatedBackground({super.key, required this.child});

  @override
  State<FuelAnimatedBackground> createState() => _FuelAnimatedBackgroundState();
}

class _FuelAnimatedBackgroundState extends State<FuelAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  static const _icons = [
    (Icons.local_gas_station_rounded, 0.08, 0.10, 46.0),
    (Icons.qr_code_2_rounded, 0.80, 0.07, 40.0),
    (Icons.account_balance_wallet_rounded, 0.86, 0.38, 36.0),
    (Icons.credit_card_rounded, 0.04, 0.48, 34.0),
    (Icons.oil_barrel_rounded, 0.12, 0.82, 42.0),
    (Icons.local_shipping_rounded, 0.78, 0.86, 40.0),
    (Icons.contactless_rounded, 0.50, 0.03, 30.0),
  ];

  static const _dropSeeds = [0.05, 0.22, 0.37, 0.51, 0.66, 0.79, 0.93];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final size = MediaQuery.of(context).size;
        return Stack(
          children: [
            // 1. Slowly shifting fuel-blue gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + math.sin(t * 2 * math.pi) * 0.6, -1),
                    end: Alignment(1, 1 + math.cos(t * 2 * math.pi) * 0.6),
                    colors: const [kFuelDeepNavy, kFuelBlue, kFuelCyan],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // 2. Floating cashless / fuel icons
            for (var i = 0; i < _icons.length; i++)
              Positioned(
                left: size.width * _icons[i].$2,
                top:
                    size.height * _icons[i].$3 +
                    math.sin((t * 2 * math.pi * 2) + i) * 14,
                child: Transform.rotate(
                  angle: math.sin((t * 2 * math.pi) + i * 0.7) * 0.25,
                  child: Icon(
                    _icons[i].$1,
                    size: _icons[i].$4,
                    color: Colors.white.withOpacity(0.09),
                  ),
                ),
              ),
            // 3. Fuel drops rising like bubbles
            for (var i = 0; i < _dropSeeds.length; i++)
              Builder(
                builder: (_) {
                  final p = (t * (1.5 + i % 3 * 0.5) + _dropSeeds[i]) % 1.0;
                  return Positioned(
                    left:
                        size.width * _dropSeeds[(i * 3) % _dropSeeds.length] +
                        math.sin(p * 6 * math.pi) * 10,
                    top: size.height * (1.05 - p * 1.15),
                    child: Opacity(
                      opacity: (math.sin(p * math.pi) * 0.35).clamp(0.0, 1.0),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 10.0 + (i % 3) * 6,
                        color: kFuelAmber,
                      ),
                    ),
                  );
                },
              ),
            // 4. Waves at the bottom
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BackgroundWavePainter(progress: t),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Round fuel tank whose amber liquid waves, fills and drains, with bubbles,
/// a rotating gauge ring, a pulsing glow and a pump icon on top.
class FuelTankLogo extends StatefulWidget {
  final double size;
  const FuelTankLogo({super.key, this.size = 150});

  @override
  State<FuelTankLogo> createState() => _FuelTankLogoState();
}

class _FuelTankLogoState extends State<FuelTankLogo>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final tank = s * 0.79;
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _pulse]),
      builder: (context, _) {
        final t = _controller.value;
        final glow = 0.7 + Curves.easeInOut.transform(_pulse.value) * 0.3;
        // Tank level gently fills and drains
        final level = 0.45 + math.sin(t * 2 * math.pi) * 0.2;
        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s * glow,
                height: s * glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kFuelAmber.withOpacity(0.35),
                      blurRadius: s * 0.27,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: CustomPaint(
                  size: Size(s, s),
                  painter: _GaugeRingPainter(),
                ),
              ),
              ClipOval(
                child: Container(
                  width: tank,
                  height: tank,
                  color: Colors.white.withOpacity(0.12),
                  child: CustomPaint(
                    painter: _TankLiquidPainter(progress: t, level: level),
                  ),
                ),
              ),
              Container(
                width: tank,
                height: tank,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              Icon(
                Icons.local_gas_station_rounded,
                size: s * 0.36,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wide gradient button with a light shine sweeping across it.
class FuelGradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const FuelGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.local_gas_station_rounded,
    this.isLoading = false,
  });

  @override
  State<FuelGradientButton> createState() => _FuelGradientButtonState();
}

class _FuelGradientButtonState extends State<FuelGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [kFuelBlue, Color(0xFF3B82F6)]),
        boxShadow: [
          BoxShadow(
            color: kFuelBlue.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            if (!widget.isLoading)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: Alignment(-2.5 + _shine.value * 5, 0),
                    widthFactor: 0.25,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.text,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(widget.icon, color: kFuelAmber, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text field styled for the auth cards (label above, filled, rounded).
class FuelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const FuelTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  static const _textDark = Color(0xFF1F2937);
  static const _hint = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: _hint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: _textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: hint,
            hintStyle: const TextStyle(color: _hint),
            prefixIcon: Icon(icon, color: kFuelBlue),
            suffixIcon: suffixIcon,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// --- Painters ---

/// Amber fuel liquid with two moving waves and bubbles, drawn inside the tank.
class _TankLiquidPainter extends CustomPainter {
  final double progress;
  final double level;
  _TankLiquidPainter({required this.progress, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * math.pi * 3;

    Path wave(double offset, double amp) {
      final baseY = size.height * (1 - level);
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y =
            baseY +
            math.sin((x / size.width * 2 * math.pi) + phase + offset) * amp;
        path.lineTo(x, y);
      }
      return path
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(
      wave(math.pi, 5),
      Paint()..color = kFuelOrange.withOpacity(0.55),
    );
    canvas.drawPath(
      wave(0, 4),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kFuelAmber, kFuelOrange],
        ).createShader(Offset.zero & size),
    );

    // Bubbles rising through the fuel
    final bubble = Paint()..color = Colors.white.withOpacity(0.45);
    for (var i = 0; i < 5; i++) {
      final p = (progress * 4 + i * 0.2) % 1.0;
      final top = size.height * (1 - level) + 8;
      final y = size.height - (size.height - top) * p;
      final x = size.width * (0.2 + i * 0.15) + math.sin(p * 8) * 3;
      canvas.drawCircle(Offset(x, y), 1.5 + i % 2, bubble);
    }
  }

  @override
  bool shouldRepaint(_TankLiquidPainter old) =>
      old.progress != progress || old.level != level;
}

/// Dashed fuel-gauge ring with an amber "needle" arc.
class _GaugeRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final tick = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
      final a = i * 2 * math.pi / 36;
      final len = i % 3 == 0 ? 7.0 : 3.0;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * radius,
        center + Offset(math.cos(a), math.sin(a)) * (radius - len),
        tick,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..color = kFuelAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugeRingPainter old) => false;
}

/// Layered translucent waves along the bottom of the screen.
class _BackgroundWavePainter extends CustomPainter {
  final double progress;
  _BackgroundWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    void drawWave(double heightFactor, double amp, double speed, Color color) {
      final baseY = size.height * (1 - heightFactor);
      final phase = progress * 2 * math.pi * speed;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        path.lineTo(
          x,
          baseY + math.sin((x / size.width * 2 * math.pi) + phase) * amp,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    drawWave(0.16, 14, 1, Colors.white.withOpacity(0.05));
    drawWave(0.11, 10, -2, kFuelAmber.withOpacity(0.08));
    drawWave(0.07, 8, 3, Colors.white.withOpacity(0.06));
  }

  @override
  bool shouldRepaint(_BackgroundWavePainter old) => old.progress != progress;
}
