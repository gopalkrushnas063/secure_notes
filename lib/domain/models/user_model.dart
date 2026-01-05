// lib/domain/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;

  const UserModel({
    required this.id,
    required this.email,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, email];
}