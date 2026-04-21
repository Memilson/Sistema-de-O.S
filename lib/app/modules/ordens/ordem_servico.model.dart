import 'package:serviceflow/app/core/base/base.model.dart';
class OrdemServico extends BaseModel {
  final String clienteId;
  final String clienteNome;
  final String descricao;
  final double valor;
  final String status;
  final String? fotoAntesPath;
  final String? fotoDepoisPath;
  final String? assinaturaBase64;
  OrdemServico({
    String? id, DateTime? createdAt, required this.clienteId, required this.clienteNome,
    required this.descricao, required this.valor, this.status = 'Em aberto',
    this.fotoAntesPath, this.fotoDepoisPath, this.assinaturaBase64,
  }) : super(id: id, createdAt: createdAt);
  OrdemServico.fromMap(Map<String, dynamic> map)
      : clienteId = map['clienteId'] as String,
        clienteNome = map['clienteNome'] as String,
        descricao = map['descricao'] as String,
        valor = (map['valor'] as num).toDouble(),
        status = map['status'] as String,
        fotoAntesPath = map['fotoAntesPath'] as String?,
        fotoDepoisPath = map['fotoDepoisPath'] as String?,
        assinaturaBase64 = map['assinaturaBase64'] as String?,
        super.fromMap(map);
  OrdemServico copyWith({
    String? id, DateTime? createdAt, String? clienteId, String? clienteNome,
    String? descricao, double? valor, String? status, String? fotoAntesPath,
    String? fotoDepoisPath, String? assinaturaBase64,
  }) {
    return OrdemServico(
      id: id ?? this.id, createdAt: createdAt ?? this.createdAt,
      clienteId: clienteId ?? this.clienteId, clienteNome: clienteNome ?? this.clienteNome,
      descricao: descricao ?? this.descricao, valor: valor ?? this.valor,
      status: status ?? this.status, fotoAntesPath: fotoAntesPath ?? this.fotoAntesPath,
      fotoDepoisPath: fotoDepoisPath ?? this.fotoDepoisPath, assinaturaBase64: assinaturaBase64 ?? this.assinaturaBase64,
    );
  }
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap, 'clienteId': clienteId, 'clienteNome': clienteNome,
      'descricao': descricao, 'valor': valor, 'status': status,
      'fotoAntesPath': fotoAntesPath, 'fotoDepoisPath': fotoDepoisPath,
      'assinaturaBase64': assinaturaBase64,
    };
  }
}
