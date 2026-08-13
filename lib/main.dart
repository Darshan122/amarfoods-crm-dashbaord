import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/buyer_provider.dart';
import 'views/dashboard_view.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const BuyerCRMApp());
}

class BuyerCRMApp extends StatefulWidget {
  const BuyerCRMApp({super.key});

  @override
  State<BuyerCRMApp> createState() => _BuyerCRMAppState();
}

class _BuyerCRMAppState extends State<BuyerCRMApp> {
  late final BuyerProvider _buyerProvider;

  @override
  void initState() {
    super.initState();
    _buyerProvider = BuyerProvider();
  }

  @override
  void dispose() {
    _buyerProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _buyerProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Amar Foods - Buyer Follow-up CRM',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF4F5F8),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF96387D),
              secondary: Color(0xFF009647),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
          ),
          home: DashboardView(provider: _buyerProvider),
        );
      },
    );
  }
}
