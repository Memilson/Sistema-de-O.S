import 'package:serviceflow/app/core/base/base.model.dart';

class OrdemServico extends BaseModel {
  final String clienteId;
  final String clienteNome;
  final String descricao;
  final double valor;
  final String status;

  OrdemServico({
    String? id,
    DateTime? createdAt,
    required this.clienteId,
    required this.clienteNome,
    required this.descricao,
    required this.valor,
    this.status = 'Em aberto',
  }) : super(id: id, createdAt: createdAt);

  OrdemServico.fromMap(Map<String, dynamic> map)
      : clienteId = map['clienteId'] as String,
        clienteNome = map['clienteNome'] as String,
        descricao = map['descricao'] as String,
        valor = (map['valor'] as num).toDouble(),
        status = map['status'] as String,
        super.fromMap(map);

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'descricao': descricao,
      'valor': valor,
      'status': status,
    };
  }
}
