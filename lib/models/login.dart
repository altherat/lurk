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

  final LoginFieldType type;
  final String label;

  LoginField({
    required this.label,
    required this.type
  });

}

enum LoginFieldType {

  identity,
  secret

}