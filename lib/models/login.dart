import 'package:lurk/models/user.dart';

sealed class LoginResult {}

class LoginSuccess extends LoginResult {

  final LoggedInUser user;

  LoginSuccess(this.user);

}

class LoginError extends LoginResult {

  final String? message;

  LoginError([this.message]);

}

class LoginField {

  final String label;
  final bool isSecret;

  LoginField({
    required this.label,
    required this.isSecret
  });

}