import 'dart:math';
import 'dart:convert';
import 'package:uuid/uuid.dart';

String generateSecureToken([int length=32]) {
  final rand = Random.secure();
  final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String generateInviteToken() {
  var uuid = Uuid();
  return uuid.v4();
}
