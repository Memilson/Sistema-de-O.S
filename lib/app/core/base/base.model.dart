abstract class BaseModel {
  final String? id;
  final DateTime? createdAt;

  BaseModel({
    this.id,
    this.createdAt,
  });

  // Construtor nomeado para criar a base a partir de um Map
  BaseModel.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String?,
        createdAt = map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null;

  // Método para converter os atributos da base para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt':
          createdAt?.toIso8601String(), // Converte DateTime para String ISO8601
    };
  }
}
