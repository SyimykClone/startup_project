// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ARound';

  @override
  String get language => 'Language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get splashTagline => 'Find routes. Save places. Travel smarter.';

  @override
  String get authTagline => 'Explore the world around you';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMin6 => 'At least 6 characters';

  @override
  String get passwordWeak => 'Password must be at least 6 characters';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get connectingGoogle => 'Connecting Google...';

  @override
  String get noAccount => 'No account?';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get registerCreateAccount => 'Create account';

  @override
  String get registerSubtitle => 'Join ARound and start exploring';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => '3-20 characters';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameMin => 'Username must be at least 3 characters';

  @override
  String get usernameMax => 'Username must be at most 20 characters';

  @override
  String get usernameAllowedChars => 'Use letters, digits, ., _, -';

  @override
  String get passwordRule => 'Min 6 chars, upper/lower letters and number';

  @override
  String get passwordStrongRule =>
      'Use 6+ chars with upper/lower letters and number';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsNotMatch => 'Passwords do not match';

  @override
  String get creating => 'Creating...';

  @override
  String get createAccount => 'Create account';

  @override
  String get favoritesTitle => 'Favorite places';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabAr => 'AR';

  @override
  String get tabMap => 'Map';

  @override
  String get tabTours => 'Tours';

  @override
  String get tabProfile => 'Profile';

  @override
  String get details => 'Details';

  @override
  String get openOnMap => 'Open on map';

  @override
  String get buildRoute => 'Build route';

  @override
  String get visitedTitle => 'Visited places';

  @override
  String loadError(Object error) {
    return 'Loading error: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get favoritesEmpty => 'Favorites list is empty';

  @override
  String get visitedEmpty => 'No visited places yet';

  @override
  String get removeFavoriteTitle => 'Remove from favorites?';

  @override
  String removeFavoriteMessage(Object name) {
    return 'Place \"$name\" will be removed from the list.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String removeFailed(Object error) {
    return 'Could not remove: $error';
  }

  @override
  String get visitedBadge => 'Visited';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get tapChoosePhoto => 'Tap to choose photo';

  @override
  String get photoPreviewTitle => 'Photo preview';

  @override
  String get usePhoto => 'Use photo';

  @override
  String get chooseAnotherPhoto => 'Choose another';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordHint => 'Leave empty if you do not want to change it';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get logOut => 'Log out';

  @override
  String get destinations => 'Destinations';

  @override
  String get add => 'Add';

  @override
  String get noDestinations => 'No destinations yet. Tap Add.';

  @override
  String get addDestination => 'Add destination';

  @override
  String get editDestination => 'Edit destination';

  @override
  String get destination => 'Destination';

  @override
  String get travelMode => 'Travel mode';

  @override
  String get save => 'Save';

  @override
  String get directions => 'Directions';

  @override
  String get tapMarkerOrAdd => 'Tap marker or add destination';

  @override
  String favoriteActionFailed(Object error) {
    return 'Favorite action failed: $error';
  }

  @override
  String get couldNotResolveAddress =>
      'Could not resolve address, using pinned coordinates';

  @override
  String get pinnedPoint => 'Pinned point';

  @override
  String get googleTokenEmpty => 'Google token is empty.';

  @override
  String googleSignInFailed(Object error) {
    return 'Google sign-in failed: $error';
  }

  @override
  String get selectTravelModeFirst => 'Select travel mode first';

  @override
  String get userLocationNotFound => 'User location not found';

  @override
  String requestFailed(int code) {
    return 'Request failed ($code)';
  }

  @override
  String get selectMode => 'SELECT MODE';

  @override
  String get minUnit => 'min';

  @override
  String get kmUnit => 'km';

  @override
  String get errorLabel => 'Error';

  @override
  String get modeWalking => 'Walking';

  @override
  String get modeDriving => 'Driving';

  @override
  String get roleUser => 'User';

  @override
  String get roleBusiness => 'Business user';

  @override
  String get toursTitle => 'Tours';

  @override
  String get myToursTitle => 'My tours';

  @override
  String get toursBusinessHint => 'Create, edit and publish your tours';

  @override
  String get toursUserHint => 'Published tours from business users';

  @override
  String get createTour => 'Create tour';

  @override
  String get editTour => 'Edit tour';

  @override
  String get tourTitle => 'Title';

  @override
  String get tourDescription => 'Description';

  @override
  String get tourDurationDays => 'Duration (days)';

  @override
  String get tourPrice => 'Price';

  @override
  String get tourDistanceKm => 'Distance (km)';

  @override
  String get tourStopsCount => 'Stops count';

  @override
  String get tourDifficulty => 'Difficulty';

  @override
  String get tourPublished => 'Published';

  @override
  String get checkFormData => 'Check form data';

  @override
  String get noToursYet => 'No tours yet';

  @override
  String get published => 'Published';

  @override
  String get draft => 'Draft';

  @override
  String get daysUnit => 'days';

  @override
  String get stopsUnit => 'stops';

  @override
  String deleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get gamificationTitle => 'Progress';

  @override
  String get maxLevel => 'MAX';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstRoute => 'First route';

  @override
  String get achievementFiveRoutes => '5 routes';

  @override
  String get achievementFirstNewPlace => 'First new place';

  @override
  String levelLine(int level, int xp) {
    return 'Level $level · $xp XP';
  }

  @override
  String xpToNextLevel(String xp) {
    return 'Next level: $xp XP';
  }

  @override
  String routesBuiltLabel(int count) {
    return 'Routes built: $count';
  }

  @override
  String newPlacesLabel(int count) {
    return 'New places visited: $count';
  }
}
