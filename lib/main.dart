import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'providers/course_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/ad_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/banner_ad_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  // Load initial ads
  InterstitialAdHelper.loadAd();
  RewardedAdHelper.loadAd();
  
  runApp(const FoundationHubApp());
}

class FoundationHubApp extends StatelessWidget {
  const FoundationHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()..initializeAds()),
      ],
      child: MaterialApp(
        title: 'AI Foundation School',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}

