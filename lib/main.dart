import 'dart:async';
import 'dart:ui';
import 'package:calcwise_core/calcwise_core.dart'
    show
        themeModeService,
        CalcwiseAdService,
        CalcwiseAdConfig,
        PaywallSessionService,
        CalcwiseAdFooter,
        CalcwiseRewardAdSheet,
        CalcwiseRemoteConfig,
        requestCalcwiseConsent,
        SmartHistoryService,
        CalcwiseTax,
        calcwiseTaxRemoteFetch;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/firebase/firebase_options.dart';
import 'core/freemium/freemium_service.dart';
import 'core/freemium/iap_service.dart';
import 'core/db/job_offer_us_database_adapter.dart';
import 'core/ads/ad_config.dart';
import 'core/services/analytics_service.dart';
import 'widgets/paywall_hard.dart';
import 'widgets/paywall_soft.dart';
import 'core/language/language_notifier.dart';
import 'core/services/deadline_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'l10n/strings_en.dart';
import 'l10n/strings_es.dart';

final adService = CalcwiseAdService(
  config: CalcwiseAdConfig(
    bannerAndroid: AdConfig.bannerAndroid,
    interstitialAndroid: AdConfig.interstitialAndroid,
    rewardedAndroid: AdConfig.rewardedAndroid,
    calcThreshold: 7,
    cooldownMinutes: 5,
  ),
  freemium: freemiumService,
  analytics: AnalyticsService.instance,
);

final paywallSession = PaywallSessionService(
  appKey: 'jobofferus',
  hasFullAccess: () => freemiumService.hasFullAccess,
);

/// SmartHistory ring buffer + pinned scenarios service.
final smartHistoryService = SmartHistoryService(
  db: JobOfferUSDatabaseAdapter(),
  freemium: freemiumService,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ (API 35) forces edge-to-edge; draw under transparent system
  // bars ourselves instead of painting them opaque (deprecated pattern).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('es_US', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CalcwiseTax.init(remoteFetcher: calcwiseTaxRemoteFetch);
  await CalcwiseRemoteConfig.initialize();
  // Debug builds must not report to the same Crashlytics project as
  // production — testing on-device would otherwise pollute the live
  // crash dashboard alongside real user reports.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await requestCalcwiseConsent();
  await MobileAds.instance.initialize();
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['FD16D4616C3A21C3ACE5E48F8DC9C1DC']),
    );
  }
  if (AdConfig.adsEnabled) await adService.initialize();
  await freemiumService.initialize();
  await paywallSession.initialize();
  await IAPService.instance.initialize();
  unawaited(AnalyticsService.instance.initialize());
  await AnalyticsService.instance.logAppOpen();
  AnalyticsService.instance.setUserPremium(freemiumService.hasFullAccess);
  await themeModeService.initialize();

  // EN/ES: saved preference first, then system locale detection
  {
    final locales = PlatformDispatcher.instance.locales;
    final systemLang = locales.isNotEmpty ? locales.first.languageCode : 'en';
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language');
    isSpanishNotifier.value = (savedLang ?? systemLang) == 'es';
  }

  CalcwiseAdFooter.configure(
    adService: adService,
    freemium: freemiumService,
    isSpanishNotifier: isSpanishNotifier,
    onGetPremium: () => IAPService.instance.buy(),
    analytics: AnalyticsService.instance,
  );

  CalcwiseRewardAdSheet.configure(
    adService: adService,
    freemium: freemiumService,
    isSpanishNotifier: isSpanishNotifier,
  );

  await DeadlineNotificationService.instance.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initial style — brightness-aware override applied per-screen in build()
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
  PaywallHard.setAnalytics(AnalyticsService.instance);
  PaywallSoft.setAnalytics(AnalyticsService.instance);
  runApp(const JobOfferApp());
}

class JobOfferApp extends StatelessWidget {
  const JobOfferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSpanishNotifier,
      builder: (_, isSpanish, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeService.notifier,
        builder: (_, themeMode, __) => MaterialApp(
          title: isSpanish ? const AppStringsEs().appTitle : const AppStringsEn().appTitle,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
          builder: (context, child) {
            if (!MediaQuery.of(context).disableAnimations) return child!;
            return Theme(
              data: Theme.of(context).copyWith(
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: _NoAnimPageTransitionsBuilder(),
                    TargetPlatform.iOS: _NoAnimPageTransitionsBuilder(),
                  },
                ),
              ),
              child: child!,
            );
          },
          theme: AppTheme.theme,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class _NoAnimPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
