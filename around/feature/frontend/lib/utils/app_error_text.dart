import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AppErrorText {
  static String fromObject(BuildContext context, Object error) {
    if (error is DioException) {
      return _fromDio(context, error);
    }
    return fromMessage(context, error.toString());
  }

  static String fromMessage(BuildContext context, String message) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final lower = message.toLowerCase();

    if (message.trim().isEmpty) {
      return isRu ? 'Что-то пошло не так.' : 'Something went wrong.';
    }

    if (lower.contains('connection timeout') ||
        lower.contains('send timeout') ||
        lower.contains('receive timeout') ||
        lower.contains('timeout')) {
      return isRu
          ? 'Сервер долго не отвечает. Попробуйте ещё раз.'
          : 'The server is taking too long to respond. Please try again.';
    }

    if (lower.contains('connection error') ||
        lower.contains('cannot connect') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('socketexception')) {
      return isRu
          ? 'Нет соединения с сервером. Проверьте интернет и попробуйте снова.'
          : 'Cannot connect to the server. Check your internet and try again.';
    }

    if (lower.contains('status code of 401') ||
        lower.contains('401') ||
        lower.contains('invalid credentials') ||
        lower.contains('bad credentials') ||
        lower.contains('wrong credentials') ||
        lower.contains('unauthorized') ||
        lower.contains('invalid email or password') ||
        lower.contains('incorrect password')) {
      return isRu
          ? 'Неверный email или пароль.'
          : 'Invalid email or password.';
    }

    if (lower.contains('user not found') ||
        lower.contains('email not found') ||
        lower.contains('account not found')) {
      return isRu
          ? 'Пользователь с такими данными не найден.'
          : 'No user was found with these details.';
    }

    if (lower.contains('bad request') ||
        lower.contains('invalid input') ||
        lower.contains('validation') ||
        lower.contains('invalid data')) {
      return isRu
          ? 'Проверьте введённые данные и попробуйте снова.'
          : 'Check the entered data and try again.';
    }

    if (lower.contains('password too short') ||
        lower.contains('short password') ||
        lower.contains('password must')) {
      return isRu
          ? 'Пароль слишком короткий. Укажите более надёжный пароль.'
          : 'The password is too short. Use a stronger password.';
    }

    if (lower.contains('current password') ||
        lower.contains('old password')) {
      return isRu
          ? 'Текущий пароль указан неверно.'
          : 'The current password is incorrect.';
    }

    if (lower.contains('status code of 403') || lower.contains('403')) {
      return isRu
          ? 'У вас нет доступа к этому действию.'
          : 'You do not have access to this action.';
    }

    if (lower.contains('status code of 404') || lower.contains('404')) {
      return isRu
          ? 'Данные не найдены. Обновите экран и попробуйте снова.'
          : 'Data was not found. Refresh the screen and try again.';
    }

    if (lower.contains('status code of 409') ||
        lower.contains('409') ||
        lower.contains('already exists') ||
        lower.contains('duplicate key') ||
        lower.contains('unique constraint') ||
        lower.contains('email already') ||
        lower.contains('username already')) {
      return isRu
          ? 'Email или имя пользователя уже используются.'
          : 'Email or username is already used.';
    }

    if (lower.contains('status code of 500') ||
        lower.contains('500') ||
        lower.contains('internal server error')) {
      return isRu
          ? 'На сервере произошла ошибка. Попробуйте позже.'
          : 'Something went wrong on the server. Please try again later.';
    }

    if (lower.contains('dioexception') ||
        lower.contains('requestoptions') ||
        lower.contains('developer.mozilla.org') ||
        lower.contains('status code')) {
      return isRu
          ? 'Не удалось выполнить запрос. Попробуйте ещё раз.'
          : 'Could not complete the request. Please try again.';
    }

    return _cleanup(message);
  }

  static String _fromDio(BuildContext context, DioException error) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final data = error.response?.data;

    if (data is Map && data['detail'] != null) {
      return fromMessage(context, data['detail'].toString());
    }
    if (data is String && data.trim().isNotEmpty) {
      return fromMessage(context, data);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return isRu
            ? 'Сервер долго не отвечает. Попробуйте ещё раз.'
            : 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return isRu
            ? 'Нет соединения с сервером. Проверьте интернет и попробуйте снова.'
            : 'Cannot connect to the server. Check your internet and try again.';
      default:
        break;
    }

    final code = error.response?.statusCode;
    if (code != null) {
      return fromMessage(context, code.toString());
    }

    return fromMessage(
      context,
      error.message ?? (isRu ? 'Неизвестная ошибка.' : 'Unknown error.'),
    );
  }

  static String _cleanup(String message) {
    final trimmed = message.trim();
    if (trimmed.length <= 160) return trimmed;
    return '${trimmed.substring(0, 157)}...';
  }
}
