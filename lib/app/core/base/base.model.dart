abstract class BaseModel {
  final String? id;
  final DateTime? createdAt;
  BaseModel({
    this.id,
    this.createdAt,
  });
  BaseModel.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String?,
        createdAt = map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null;
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
