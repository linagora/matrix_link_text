import 'package:equatable/equatable.dart';

class Pill with EquatableMixin {
  final String identifier;
  final String url;

  Pill({
    required this.identifier,
    required this.url,
  });

  @override
  List<Object?> get props => [identifier, url];
}
