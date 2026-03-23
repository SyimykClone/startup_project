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
}
