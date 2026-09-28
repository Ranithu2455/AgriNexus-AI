import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'shared/l10n/app_localizations.dart';
import 'shared/models/detection_result.dart';
import 'shared/models/farm.dart';
import 'shared/routes.dart';
import 'shared/state/auth_provider.dart';
import 'shared/state/locale_provider.dart';
import 'shared/widgets/common_widgets.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/farmer_dashboard_screen.dart';
import 'features/profile/farmer_profile_screen.dart';
import 'features/farms/my_farms_screen.dart';
import 'features/farms/add_edit_farm_screen.dart';
import 'features/farms/farm_details_screen.dart';
import 'features/crops/my_crops_screen.dart';
import 'features/crops/add_crop_screen.dart';
import 'features/crops/crop_details_screen.dart';
import 'features/ai_disease/ai_plant_doctor_screen.dart';
import 'features/ai_disease/disease_result_screen.dart';
import 'features/pest/pest_identification_screen.dart';
import 'features/recommendation/crop_recommendation_screen.dart';
import 'features/weather/weather_screen.dart';
import 'features/feedback/farmer_feedback_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgriNexusApp());
}

class AgriNexusApp extends StatelessWidget {
  const AgriNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'AgriNexus AI',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorSchemeSeed: Colors.green,
              useMaterial3: true,
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
              ),
            ),
            home: const _AuthGate(),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const FarmerDashboardScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const FarmerProfileScreen());
      case AppRoutes.myFarms:
        return MaterialPageRoute(builder: (_) => const MyFarmsScreen());
      case AppRoutes.addEditFarm:
        final farm = settings.arguments as Farm?;
        return MaterialPageRoute(builder: (_) => AddEditFarmScreen(existingFarm: farm));
      case AppRoutes.farmDetails:
        final farmId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => FarmDetailsScreen(farmId: farmId));
      case AppRoutes.myCrops:
        return MaterialPageRoute(builder: (_) => const MyCropsScreen());
      case AppRoutes.addCrop:
        final farmId = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => AddCropScreen(preselectedFarmId: farmId));
      case AppRoutes.cropDetails:
        final cropId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => CropDetailsScreen(cropId: cropId));
      case AppRoutes.aiPlantDoctor:
        return MaterialPageRoute(builder: (_) => const AiPlantDoctorScreen());
      case AppRoutes.diseaseResult:
        final result = settings.arguments as DiseaseResult;
        return MaterialPageRoute(builder: (_) => DiseaseResultScreen(result: result));
      case AppRoutes.pestIdentification:
        return MaterialPageRoute(builder: (_) => const PestIdentificationScreen());
      case AppRoutes.cropRecommendation:
        return MaterialPageRoute(builder: (_) => const CropRecommendationScreen());
      case AppRoutes.weather:
        return MaterialPageRoute(builder: (_) => const WeatherScreen());
      case AppRoutes.farmerFeedback:
        return MaterialPageRoute(builder: (_) => const FarmerFeedbackScreen());
      default:
        return null;
    }
  }
}

/// Shows the dashboard if a valid session exists, otherwise the login
/// screen. This is the app's home widget; all other navigation goes through
/// named routes.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: LoadingView());
      case AuthStatus.authenticated:
        return const FarmerDashboardScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
