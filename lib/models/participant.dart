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

  factory Participant.fromFirestore(String id, Map<String, dynamic> map) {
    return Participant(
      id: id,
      name: map['name'],
    );
  }
}
