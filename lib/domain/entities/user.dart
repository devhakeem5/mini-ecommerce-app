import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, avatarUrl, role];
}
