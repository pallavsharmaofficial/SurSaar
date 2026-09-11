import 'package:equatable/equatable.dart';

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.earnedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final DateTime earnedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    description,
    iconAsset,
    earnedAt,
  ];
}
