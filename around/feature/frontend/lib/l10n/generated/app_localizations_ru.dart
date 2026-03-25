// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ARound';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get splashTagline =>
      'Строй маршруты. Сохраняй места. Путешествуй умнее.';

  @override
  String get authTagline => 'Исследуй мир вокруг себя';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get loginWelcomeBack => 'С возвращением';

  @override
  String get loginContinue => 'Войдите, чтобы продолжить';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Укажите email';

  @override
  String get emailInvalid => 'Введите корректный email';

  @override
  String get password => 'Пароль';

  @override
  String get passwordRequired => 'Укажите пароль';

  @override
  String get passwordMin6 => 'Минимум 6 символов';

  @override
  String get passwordWeak => 'Пароль должен быть не короче 6 символов';

  @override
  String get signingIn => 'Вход...';

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String get connectingGoogle => 'Подключаем Google...';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get alreadyAccount => 'Уже есть аккаунт?';

  @override
  String get registerCreateAccount => 'Создать аккаунт';

  @override
  String get registerSubtitle =>
      'Присоединяйтесь к ARound и начните исследовать';

  @override
  String get username => 'Имя пользователя';

  @override
  String get usernameHint => '3-20 символов';

  @override
  String get usernameRequired => 'Укажите имя пользователя';

  @override
  String get usernameMin => 'Минимум 3 символа';

  @override
  String get usernameMax => 'Максимум 20 символов';

  @override
  String get usernameAllowedChars => 'Используйте буквы, цифры, ., _, -';

  @override
  String get passwordRule =>
      'Минимум 6 символов, верхний/нижний регистр и цифра';

  @override
  String get passwordStrongRule =>
      'Нужно 6+ символов, верхний/нижний регистр и цифра';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get confirmPasswordRequired => 'Подтвердите пароль';

  @override
  String get passwordsNotMatch => 'Пароли не совпадают';

  @override
  String get creating => 'Создание...';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get favoritesTitle => 'Любимые места';

  @override
  String get visitedTitle => 'Посещенные места';

  @override
  String loadError(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get favoritesEmpty => 'Список избранного пуст';

  @override
  String get visitedEmpty => 'Пока нет посещенных мест';

  @override
  String get removeFavoriteTitle => 'Удалить из избранного?';

  @override
  String removeFavoriteMessage(Object name) {
    return 'Место \"$name\" будет удалено из списка.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get remove => 'Удалить';

  @override
  String removeFailed(Object error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get visitedBadge => 'Посещено';

  @override
  String get editProfile => 'Редактирование профиля';

  @override
  String get tapChoosePhoto => 'Нажмите, чтобы выбрать фото';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get newPasswordHint => 'Оставьте пустым, если не хотите менять';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get profileUpdated => 'Профиль обновлен';

  @override
  String get logOut => 'Выйти';

  @override
  String get destinations => 'Маршруты';

  @override
  String get add => 'Добавить';

  @override
  String get noDestinations => 'Пока нет точек маршрута. Нажмите «Добавить».';

  @override
  String get addDestination => 'Добавить точку';

  @override
  String get editDestination => 'Изменить точку';

  @override
  String get destination => 'Точка назначения';

  @override
  String get travelMode => 'Тип передвижения';

  @override
  String get save => 'Сохранить';

  @override
  String get directions => 'Маршрут';

  @override
  String get tapMarkerOrAdd => 'Выберите метку или добавьте точку';

  @override
  String favoriteActionFailed(Object error) {
    return 'Ошибка избранного: $error';
  }

  @override
  String get couldNotResolveAddress =>
      'Не удалось определить адрес, используем координаты';

  @override
  String get pinnedPoint => 'Отмеченная точка';

  @override
  String get googleTokenEmpty => 'Google-токен пуст.';

  @override
  String googleSignInFailed(Object error) {
    return 'Ошибка входа через Google: $error';
  }

  @override
  String get selectTravelModeFirst => 'Сначала выберите тип маршрута';

  @override
  String get userLocationNotFound =>
      'Не удалось определить местоположение пользователя';

  @override
  String requestFailed(int code) {
    return 'Запрос не выполнен ($code)';
  }

  @override
  String get selectMode => 'ВЫБЕРИТЕ РЕЖИМ';

  @override
  String get minUnit => 'мин';

  @override
  String get kmUnit => 'км';

  @override
  String get errorLabel => 'Ошибка';

  @override
  String get modeWalking => 'Пешком';

  @override
  String get modeDriving => 'На машине';

  @override
  String get roleUser => 'Пользователь';

  @override
  String get roleBusiness => 'Бизнес-пользователь';

  @override
  String get toursTitle => 'Туры';

  @override
  String get myToursTitle => 'Мои туры';

  @override
  String get toursBusinessHint =>
      'Создавайте, редактируйте и публикуйте свои туры';

  @override
  String get toursUserHint => 'Опубликованные туры от бизнес-пользователей';

  @override
  String get createTour => 'Создать тур';

  @override
  String get editTour => 'Редактировать тур';

  @override
  String get tourTitle => 'Название';

  @override
  String get tourDescription => 'Описание';

  @override
  String get tourDurationDays => 'Длительность (дни)';

  @override
  String get tourPrice => 'Стоимость';

  @override
  String get tourDistanceKm => 'Дистанция (км)';

  @override
  String get tourStopsCount => 'Количество остановок';

  @override
  String get tourDifficulty => 'Сложность';

  @override
  String get tourPublished => 'Опубликован';

  @override
  String get checkFormData => 'Проверьте данные формы';

  @override
  String get noToursYet => 'Пока нет туров';

  @override
  String get published => 'Опубликован';

  @override
  String get draft => 'Черновик';

  @override
  String get daysUnit => 'дн.';

  @override
  String get stopsUnit => 'ост.';

  @override
  String deleteFailed(Object error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get difficultyEasy => 'Легко';

  @override
  String get difficultyMedium => 'Средне';

  @override
  String get difficultyHard => 'Сложно';
}
