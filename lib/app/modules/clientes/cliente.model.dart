import 'package:serviceflow/app/core/base/base.model.dart';
class Cliente extends BaseModel {
  final String nome;
  final String cpfCnpj;
  final String email;
  final String telefone;
  Cliente({String? id, DateTime? createdAt, required this.nome, required this.cpfCnpj, required this.email, required this.telefone})
      : super(id: id, createdAt: createdAt);
  Cliente.fromMap(Map<String, dynamic> map)
      : nome = map['nome'] as String,
        cpfCnpj = map['cpfCnpj'] as String? ?? '',
        email = map['email'] as String? ?? '',
        telefone = map['telefone'] as String? ?? '',
        super.fromMap(map);
  Cliente copyWith({String? id, DateTime? createdAt, String? nome, String? cpfCnpj, String? email, String? telefone}) {
    return Cliente(
      id: id ?? this.id, createdAt: createdAt ?? this.createdAt,
      nome: nome ?? this.nome, cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      email: email ?? this.email, telefone: telefone ?? this.telefone,
    );
  }
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {...baseMap, 'nome': nome, 'cpfCnpj': cpfCnpj, 'email': email, 'telefone': telefone};
  }
}
