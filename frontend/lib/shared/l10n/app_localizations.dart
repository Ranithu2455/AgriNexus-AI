import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// App name shown in title bars
  ///
  /// In en, this message translates to:
  /// **'AgriNexus AI'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please check your details.'**
  String get registrationFailed;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @myFarms.
  ///
  /// In en, this message translates to:
  /// **'My Farms'**
  String get myFarms;

  /// No description provided for @myCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get myCrops;

  /// No description provided for @aiPlantDoctor.
  ///
  /// In en, this message translates to:
  /// **'AI Plant Doctor'**
  String get aiPlantDoctor;

  /// No description provided for @pestIdentification.
  ///
  /// In en, this message translates to:
  /// **'Pest Identification'**
  String get pestIdentification;

  /// No description provided for @cropRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get cropRecommendation;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @farmerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get farmerFeedback;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @farmerInfo.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get farmerInfo;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add Farm'**
  String get addFarm;

  /// No description provided for @editFarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Farm'**
  String get editFarm;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmName;

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm Size (acres)'**
  String get farmSize;

  /// No description provided for @soilInfo.
  ///
  /// In en, this message translates to:
  /// **'Soil Information'**
  String get soilInfo;

  /// No description provided for @waterAvailability.
  ///
  /// In en, this message translates to:
  /// **'Water Availability'**
  String get waterAvailability;

  /// No description provided for @deleteFarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Farm'**
  String get deleteFarm;

  /// No description provided for @confirmDeleteFarm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this farm? This cannot be undone.'**
  String get confirmDeleteFarm;

  /// No description provided for @noFarmsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any farms yet.'**
  String get noFarmsYet;

  /// No description provided for @addCrop.
  ///
  /// In en, this message translates to:
  /// **'Add Crop'**
  String get addCrop;

  /// No description provided for @cropName.
  ///
  /// In en, this message translates to:
  /// **'Crop Name'**
  String get cropName;

  /// No description provided for @plantingDate.
  ///
  /// In en, this message translates to:
  /// **'Planting Date'**
  String get plantingDate;

  /// No description provided for @expectedHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Harvest Date'**
  String get expectedHarvestDate;

  /// No description provided for @cropStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get cropStatus;

  /// No description provided for @cropHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop History'**
  String get cropHistory;

  /// No description provided for @noCropsYet.
  ///
  /// In en, this message translates to:
  /// **'No crops added yet.'**
  String get noCropsYet;

  /// No description provided for @selectFarmFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a farm first'**
  String get selectFarmFirst;

  /// No description provided for @captureImage.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get captureImage;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get analyzing;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @recommendedActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Actions'**
  String get recommendedActions;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This AI result is not guaranteed to be accurate. Please consult an agricultural expert before taking major action.'**
  String get aiDisclaimer;

  /// No description provided for @mockResultNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: this result is from a test model, not a trained AI model.'**
  String get mockResultNotice;

  /// No description provided for @detectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Detection History'**
  String get detectionHistory;

  /// No description provided for @soilPh.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get soilPh;

  /// No description provided for @nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen'**
  String get nitrogen;

  /// No description provided for @phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus'**
  String get phosphorus;

  /// No description provided for @potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get potassium;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity (%)'**
  String get humidity;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall (mm)'**
  String get rainfall;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @getRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get Recommendations'**
  String get getRecommendations;

  /// No description provided for @suitability.
  ///
  /// In en, this message translates to:
  /// **'Suitability'**
  String get suitability;

  /// No description provided for @reasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get reasons;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @recommendationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These recommendations are decision support based on general agronomic guidelines, not guaranteed agricultural advice.'**
  String get recommendationDisclaimer;

  /// No description provided for @currentWeather.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get currentWeather;

  /// No description provided for @agriAdvisories.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Advisories'**
  String get agriAdvisories;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter your location'**
  String get enterLocation;

  /// No description provided for @feedbackType.
  ///
  /// In en, this message translates to:
  /// **'Type of Issue'**
  String get feedbackType;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitFeedback;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get feedbackSubmitted;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noDataYet;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet connection.'**
  String get networkError;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @waterAvailabilityAbundant.
  ///
  /// In en, this message translates to:
  /// **'Abundant'**
  String get waterAvailabilityAbundant;

  /// No description provided for @waterAvailabilityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get waterAvailabilityModerate;

  /// No description provided for @waterAvailabilityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get waterAvailabilityLimited;

  /// No description provided for @waterAvailabilityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get waterAvailabilityNone;

  /// No description provided for @cropStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get cropStatusPlanned;

  /// No description provided for @cropStatusPlanted.
  ///
  /// In en, this message translates to:
  /// **'Planted'**
  String get cropStatusPlanted;

  /// No description provided for @cropStatusGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get cropStatusGrowing;

  /// No description provided for @cropStatusReadyForHarvest.
  ///
  /// In en, this message translates to:
  /// **'Ready for Harvest'**
  String get cropStatusReadyForHarvest;

  /// No description provided for @cropStatusHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get cropStatusHarvested;

  /// No description provided for @cropStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get cropStatusFailed;

  /// No description provided for @feedbackWaterlogging.
  ///
  /// In en, this message translates to:
  /// **'Waterlogging'**
  String get feedbackWaterlogging;

  /// No description provided for @feedbackDrought.
  ///
  /// In en, this message translates to:
  /// **'Drought'**
  String get feedbackDrought;

  /// No description provided for @feedbackSalinity.
  ///
  /// In en, this message translates to:
  /// **'Salinity'**
  String get feedbackSalinity;

  /// No description provided for @feedbackPestOutbreak.
  ///
  /// In en, this message translates to:
  /// **'Pest Outbreak'**
  String get feedbackPestOutbreak;

  /// No description provided for @feedbackDiseaseOutbreak.
  ///
  /// In en, this message translates to:
  /// **'Disease Outbreak'**
  String get feedbackDiseaseOutbreak;

  /// No description provided for @feedbackUnexpectedWeather.
  ///
  /// In en, this message translates to:
  /// **'Unexpected Weather'**
  String get feedbackUnexpectedWeather;

  /// No description provided for @feedbackCropGrowthProblem.
  ///
  /// In en, this message translates to:
  /// **'Crop Growth Problem'**
  String get feedbackCropGrowthProblem;

  /// No description provided for @feedbackOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
