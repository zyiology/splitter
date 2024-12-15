// lib/models/participant.dart
class Participant {
  final String? id;
  final String name;

  Participant({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
    );
  }
}
