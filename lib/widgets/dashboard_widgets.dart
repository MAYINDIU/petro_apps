import 'package:flutter/material.dart';
import 'package:petro_app/widgets/fuel_animations.dart';

// Shared building blocks for the driver and station dashboards.

const Color _kTextDark = Color(0xFF1F2937);
const Color _kHint = Color(0xFF9CA3AF);

class DashboardServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const DashboardServiceItem(this.icon, this.title, this.subtitle, this.color);
}

/// Curved gradient backdrop for the top of a dashboard.
class DashboardHeaderBackground extends StatelessWidget {
  final double height;
  final IconData watermark;
  const DashboardHeaderBackground({
    super.key,
    this.height = 230,
    this.watermark = Icons.local_gas_station_rounded,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kFuelDeepNavy, kFuelBlue, kFuelCyan],
        ),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _circle(160, Colors.white.withOpacity(0.07)),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: _circle(180, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              right: 18,
              bottom: 30,
              child: Icon(
                watermark,
                size: 110,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Translucent square icon button used on gradient headers.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlassIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Section heading with an amber accent bar.
class DashboardSectionTitle extends StatelessWidget {
  final String title;
  const DashboardSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kFuelAmber, kFuelOrange],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark payment-card shell with decorative rings and a sweeping shine,
/// which also tilts in when first shown.
class FuelPaymentCard extends StatefulWidget {
  final Widget child;
  final double aspectRatio;
  const FuelPaymentCard({
    super.key,
    required this.child,
    this.aspectRatio = 1.75,
  });

  @override
  State<FuelPaymentCard> createState() => _FuelPaymentCardState();
}

class _FuelPaymentCardState extends State<FuelPaymentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX((1 - value) * 0.5)
            ..translateByDouble(0.0, (1 - value) * 40, 0.0, 1.0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111827), Color(0xFF1E3A8A), kFuelDeepNavy],
            ),
            boxShadow: [
              BoxShadow(
                color: kFuelDeepNavy.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kFuelAmber.withOpacity(0.18),
                        width: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  bottom: -70,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kFuelCyan.withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment(-3 + _shine.value * 6, 0),
                      widthFactor: 0.3,
                      child: Transform.rotate(
                        angle: 0.35,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Golden EMV-style chip for payment cards.
class CardChip extends StatelessWidget {
  const CardChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDE68A), kFuelAmber, Color(0xFFD97706)],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66784A06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(0, h / 3), Offset(w * 0.32, h / 3), paint);
    canvas.drawLine(Offset(0, h * 2 / 3), Offset(w * 0.32, h * 2 / 3), paint);
    canvas.drawLine(Offset(w * 0.68, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(w * 0.68, h * 2 / 3), Offset(w, h * 2 / 3), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.2, w * 0.36, h * 0.6),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChipLinesPainter old) => false;
}

/// Large amber call-to-action with a pulsing icon tile.
class PulsingActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const PulsingActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<PulsingActionCard> createState() => _PulsingActionCardState();
}

class _PulsingActionCardState extends State<PulsingActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kFuelAmber, kFuelOrange],
            ),
            boxShadow: [
              BoxShadow(
                color: kFuelOrange.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final v = Curves.easeInOut.transform(_pulse.value);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6 * v),
                          blurRadius: 6 + 12 * v,
                          spreadRadius: 2 * v,
                        ),
                      ],
                    ),
                    child: Transform.scale(scale: 1 + v * 0.08, child: child),
                  );
                },
                child: Icon(widget.icon, size: 34, color: kFuelOrange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: kFuelDeepNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF3B2A06),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kFuelDeepNavy.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: kFuelDeepNavy,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White card connecting a few steps with lines, e.g. "Scan → Fuel → Paid".
class HowItWorksStrip extends StatelessWidget {
  final List<(IconData, String)> steps;
  const HowItWorksStrip({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [blue.withOpacity(0.2), blue.withOpacity(0.6)],
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(steps[i].$1, color: kFuelBlue, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].$2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Grid of colorful service cards that slide in one after another.
class DashboardServiceGrid extends StatelessWidget {
  final List<DashboardServiceItem> items;
  final ValueChanged<DashboardServiceItem> onTap;
  const DashboardServiceGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _AnimatedServiceCard(
        item: items[index],
        index: index,
        onTap: () => onTap(items[index]),
      ),
    );
  }
}

class _AnimatedServiceCard extends StatefulWidget {
  final DashboardServiceItem item;
  final int index;
  final VoidCallback onTap;

  const _AnimatedServiceCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.color;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (widget.index * 120)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? color.withOpacity(0.5) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: color.withOpacity(0.08),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -18,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color.withOpacity(0.85), color],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.item.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kHint,
                                ),
                              ),
                            ),
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 200),
                              offset: Offset(_isHovered ? 0.2 : 0, 0),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

/// Drawer with a gradient profile header, rounded menu items and a logout
/// button pinned to the bottom.
class DashboardDrawer extends StatelessWidget {
  final String name;
  final String email;
  final String mobile;
  final String roleLabel;
  final List<(IconData, String, VoidCallback)> items;
  final List<(IconData, String, VoidCallback)> footerItems;
  final VoidCallback onLogout;

  const DashboardDrawer({
    super.key,
    required this.name,
    required this.email,
    required this.mobile,
    required this.roleLabel,
    required this.items,
    this.footerItems = const [],
    required this.onLogout,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3B82F6);

    Widget menuItem((IconData, String, VoidCallback) item) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          hoverColor: blue.withOpacity(0.06),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.$1, color: kFuelBlue, size: 20),
          ),
          title: Text(
            item.$2,
            style: const TextStyle(
              color: _kTextDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: _kHint),
          onTap: () {
            Navigator.pop(context);
            item.$3();
          },
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kFuelDeepNavy, kFuelBlue, kFuelCyan],
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [kFuelAmber, kFuelOrange]),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 22,
                        color: kFuelBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  mobile,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final item in items) menuItem(item),
                if (footerItems.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Divider(),
                  ),
                for (final item in footerItems) menuItem(item),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple "coming soon" screen for features that are not built yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 48,
                  color: kFuelBlue,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This feature is coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _kHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Greeting for the current time of day.
String timeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
