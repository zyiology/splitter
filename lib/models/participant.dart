// lib/models/participant.dart
class Participant {
  final String? id;
  final String name;
  final bool isPending; // For offline operations

  Participant({this.id, required this.name, this.isPending = false});

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
      isPending: false, // Firestore data is never pending
    );
  }

  Participant copyWith({
    String? id,
    String? name,
    bool? isPending,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      isPending: isPending ?? this.isPending,
    );
  }
}
