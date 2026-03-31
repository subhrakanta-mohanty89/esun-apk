/// Shared "Pay via Apps" section for bill payment screens.
///
/// Shows popular UPI / payment apps (PhonePe, Google Pay, Paytm, CRED, Amazon Pay)
/// as alternate payment channels.

import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class PayViaAppsSection extends StatelessWidget {
  const PayViaAppsSection({super.key});

  static const _apps = [
    _PayApp('PhonePe', Color(0xFF5F259F), 'https://logo.clearbit.com/phonepe.com'),
    _PayApp('Google Pay', Color(0xFF4285F4), 'https://logo.clearbit.com/pay.google.com'),
    _PayApp('Paytm', Color(0xFF00BAF2), 'https://logo.clearbit.com/paytm.com'),
    _PayApp('CRED', Color(0xFF1A1A2E), 'https://logo.clearbit.com/cred.club'),
    _PayApp('Amazon Pay', Color(0xFFFF9900), 'https://logo.clearbit.com/amazon.in'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Also Pay Via',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _apps.map((app) => _buildAppItem(app)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(_PayApp app) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ESUNColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                app.logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildFallback(app),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          app.name,
          style: ESUNTypography.labelSmall.copyWith(fontSize: 9.5),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFallback(_PayApp app) {
    final initial = app.name.substring(0, 1);
    return Container(
      decoration: BoxDecoration(
        color: app.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: app.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _PayApp {
  final String name;
  final Color color;
  final String logoUrl;

  const _PayApp(this.name, this.color, this.logoUrl);
}
