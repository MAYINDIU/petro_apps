import 'package:flutter/material.dart';
import 'package:petro_app/widgets/dashboard_widgets.dart';
import 'package:petro_app/widgets/fuel_animations.dart';

// Shared building blocks for inner pages (profile, wallet, history, QR...).

const Color kPageBackground = Color(0xFFF1F5F9);
const Color _kTextDark = Color(0xFF1F2937);
const Color _kHint = Color(0xFF9CA3AF);
const Color _kBlue = Color(0xFF3B82F6);

/// Curved gradient page header with a back button, title, optional trailing
/// action and optional content (e.g. a summary card) below the title.
class FuelPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  final IconData watermark;

  const FuelPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.watermark = Icons.local_gas_station_rounded,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));
    return Container(
      width: double.infinity,
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
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 10,
              child: Icon(
                watermark,
                size: 96,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop()) ...[
                          GlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    if (child != null) ...[const SizedBox(height: 18), child!],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered icon + message (+ optional retry) for errors and empty lists.
/// Scrollable, so it also works inside a RefreshIndicator.
class FuelStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color color;
  final VoidCallback? onRetry;

  const FuelStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color = kFuelOrange,
    this.onRetry,
  });

  const FuelStateView.error({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
  }) : icon = Icons.cloud_off_rounded,
       color = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: _kHint),
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kFuelBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered spinner in the brand color.
class FuelLoadingView extends StatelessWidget {
  final String? message;
  const FuelLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: kFuelBlue),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: const TextStyle(color: _kHint, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// White rounded card with an optional section title.
class FuelSectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FuelSectionCard({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: kFuelOrange),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
      ),
    );
  }
}

/// Icon + label + value row used inside [FuelSectionCard]s.
class FuelInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  const FuelInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kFuelBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _kHint, fontSize: 11),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: valueColor ?? _kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded status pill (green for success/active, amber otherwise).
class FuelStatusBadge extends StatelessWidget {
  final String status;
  final bool onDark;
  const FuelStatusBadge(this.status, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final ok = s == 'success' || s == 'active' || s == 'approved';
    final color = ok ? const Color(0xFF10B981) : kFuelOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withOpacity(0.18)
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: onDark ? Colors.white : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: onDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials inside an amber ring, for profile headers.
class FuelAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const FuelAvatar({super.key, required this.name, this.radius = 34});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kFuelAmber, kFuelOrange]),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: radius * 0.7,
            color: kFuelBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
