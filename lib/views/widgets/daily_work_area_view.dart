import 'package:flutter/material.dart';
import '../../providers/buyer_provider.dart';
import 'email_work_section.dart';

/// DailyWorkAreaView
///
/// Thin wrapper — delegates all UI to the shared [EmailWorkSection] widget.
/// EmailWorkSection reads live data directly from Google Sheet via [BuyerProvider].
class DailyWorkAreaView extends StatelessWidget {
  final BuyerProvider provider;

  const DailyWorkAreaView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return EmailWorkSection(provider: provider);
  }
}
