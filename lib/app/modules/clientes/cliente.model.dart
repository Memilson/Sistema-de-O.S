import 'package:serviceflow/app/core/base/base.model.dart';

class Cliente extends BaseModel {
  final String nome;
  final String cpfCnpj;
  final String email;
  final String telefone;

  Cliente({
    String? id,
    DateTime? createdAt,
    required this.nome,
    required this.cpfCnpj,
    required this.email,
    required this.telefone,
  }) : super(id: id, createdAt: createdAt);

  Cliente.fromMap(Map<String, dynamic> map)
      : nome = map['nome'] as String,
        cpfCnpj = map['cpfCnpj'] as String? ?? '',
        email = map['email'] as String? ?? '',
        telefone = map['telefone'] as String? ?? '',
        super.fromMap(map);

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'email': email,
      'telefone': telefone,
    };
  }
}
