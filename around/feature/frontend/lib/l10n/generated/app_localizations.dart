import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ARound'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Find routes. Save places. Travel smarter.'**
  String get splashTagline;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Explore the world around you'**
  String get authTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMin6;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordWeak;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @connectingGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connecting Google...'**
  String get connectingGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyAccount;

  /// No description provided for @registerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCreateAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join ARound and start exploring'**
  String get registerSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameMin.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMin;

  /// No description provided for @usernameMax.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 20 characters'**
  String get usernameMax;

  /// No description provided for @usernameAllowedChars.
  ///
  /// In en, this message translates to:
  /// **'Use letters, digits, ., _, -'**
  String get usernameAllowedChars;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars, upper/lower letters and number'**
  String get passwordRule;

  /// No description provided for @passwordStrongRule.
  ///
  /// In en, this message translates to:
  /// **'Use 6+ chars with upper/lower letters and number'**
  String get passwordStrongRule;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNotMatch;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite places'**
  String get favoritesTitle;

  /// No description provided for @visitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Visited places'**
  String get visitedTitle;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error: {error}'**
  String loadError(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Favorites list is empty'**
  String get favoritesEmpty;

  /// No description provided for @visitedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visited places yet'**
  String get visitedEmpty;

  /// No description provided for @removeFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites?'**
  String get removeFavoriteTitle;

  /// No description provided for @removeFavoriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Place \"{name}\" will be removed from the list.'**
  String removeFavoriteMessage(Object name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove: {error}'**
  String removeFailed(Object error);

  /// No description provided for @visitedBadge.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get visitedBadge;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @tapChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose photo'**
  String get tapChoosePhoto;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you do not want to change it'**
  String get newPasswordHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @destinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get destinations;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noDestinations.
  ///
  /// In en, this message translates to:
  /// **'No destinations yet. Tap Add.'**
  String get noDestinations;

  /// No description provided for @addDestination.
  ///
  /// In en, this message translates to:
  /// **'Add destination'**
  String get addDestination;

  /// No description provided for @editDestination.
  ///
  /// In en, this message translates to:
  /// **'Edit destination'**
  String get editDestination;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @travelMode.
  ///
  /// In en, this message translates to:
  /// **'Travel mode'**
  String get travelMode;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @tapMarkerOrAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap marker or add destination'**
  String get tapMarkerOrAdd;

  /// No description provided for @favoriteActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Favorite action failed: {error}'**
  String favoriteActionFailed(Object error);

  /// No description provided for @couldNotResolveAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve address, using pinned coordinates'**
  String get couldNotResolveAddress;

  /// No description provided for @pinnedPoint.
  ///
  /// In en, this message translates to:
  /// **'Pinned point'**
  String get pinnedPoint;

  /// No description provided for @googleTokenEmpty.
  ///
  /// In en, this message translates to:
  /// **'Google token is empty.'**
  String get googleTokenEmpty;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String googleSignInFailed(Object error);

  /// No description provided for @selectTravelModeFirst.
  ///
  /// In en, this message translates to:
  /// **'Select travel mode first'**
  String get selectTravelModeFirst;

  /// No description provided for @userLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'User location not found'**
  String get userLocationNotFound;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({code})'**
  String requestFailed(int code);

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'SELECT MODE'**
  String get selectMode;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @modeWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get modeWalking;

  /// No description provided for @modeDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get modeDriving;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @roleBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business user'**
  String get roleBusiness;

  /// No description provided for @toursTitle.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get toursTitle;

  /// No description provided for @myToursTitle.
  ///
  /// In en, this message translates to:
  /// **'My tours'**
  String get myToursTitle;

  /// No description provided for @toursBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Create, edit and publish your tours'**
  String get toursBusinessHint;

  /// No description provided for @toursUserHint.
  ///
  /// In en, this message translates to:
  /// **'Published tours from business users'**
  String get toursUserHint;

  /// No description provided for @createTour.
  ///
  /// In en, this message translates to:
  /// **'Create tour'**
  String get createTour;

  /// No description provided for @editTour.
  ///
  /// In en, this message translates to:
  /// **'Edit tour'**
  String get editTour;

  /// No description provided for @tourTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tourTitle;

  /// No description provided for @tourDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tourDescription;

  /// No description provided for @tourDurationDays.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get tourDurationDays;

  /// No description provided for @tourPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get tourPrice;

  /// No description provided for @tourDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get tourDistanceKm;

  /// No description provided for @tourStopsCount.
  ///
  /// In en, this message translates to:
  /// **'Stops count'**
  String get tourStopsCount;

  /// No description provided for @tourDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get tourDifficulty;

  /// No description provided for @tourPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get tourPublished;

  /// No description provided for @checkFormData.
  ///
  /// In en, this message translates to:
  /// **'Check form data'**
  String get checkFormData;

  /// No description provided for @noToursYet.
  ///
  /// In en, this message translates to:
  /// **'No tours yet'**
  String get noToursYet;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @stopsUnit.
  ///
  /// In en, this message translates to:
  /// **'stops'**
  String get stopsUnit;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
