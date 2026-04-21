import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/helpers/connectivity_helper.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/services/evidence_storage_service.dart';
import 'ordem_servico.model.dart';

class OrdemServicoRepository extends BaseRepository<OrdemServico> {
  final EvidenceStorageService evidenceStorageService;

  OrdemServicoRepository({
    super.supabase,
    super.databaseHelper,
    super.offlineSyncService,
    EvidenceStorageService? evidenceStorageService,
  }) : evidenceStorageService =
            evidenceStorageService ?? EvidenceStorageService();

  @override
  String get tableName => 'ordens_servico';

  @override
  bool get defaultAscending => false;

  @override
  OrdemServico fromMap(Map<String, dynamic> map) => OrdemServico.fromMap(map);

  Future<String> salvarComEvidencias(
    OrdemServico ordem, {
    Uint8List? fotoAntes,
    Uint8List? fotoDepois,
    Uint8List? assinatura,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuario nao autenticado');
    }

    final ordemId = ordem.id ?? const Uuid().v4();
    var ordemFinal = ordem.copyWith(id: ordemId);

    final hasEvidence =
        fotoAntes != null || fotoDepois != null || assinatura != null;

    if (hasEvidence && await ConnectivityHelper.isOnline()) {
      final uploaded = <String, String>{};

      if (fotoAntes != null) {
        uploaded['fotoAntesPath'] = await evidenceStorageService.uploadBytes(
          ordemId: ordemId,
          fileName: 'foto_antes.jpg',
          bytes: fotoAntes,
          contentType: 'image/jpeg',
        );
      }

      if (fotoDepois != null) {
        uploaded['fotoDepoisPath'] = await evidenceStorageService.uploadBytes(
          ordemId: ordemId,
          fileName: 'foto_depois.jpg',
          bytes: fotoDepois,
          contentType: 'image/jpeg',
        );
      }

      if (assinatura != null) {
        uploaded['assinaturaBase64'] = await evidenceStorageService.uploadBytes(
          ordemId: ordemId,
          fileName: 'assinatura.png',
          bytes: assinatura,
          contentType: 'image/png',
        );
      }

      ordemFinal = ordemFinal.copyWith(
        fotoAntesPath: uploaded['fotoAntesPath'],
        fotoDepoisPath: uploaded['fotoDepoisPath'],
        assinaturaBase64: uploaded['assinaturaBase64'],
      );
    } else if (hasEvidence) {
      ordemFinal = ordemFinal.copyWith(
        fotoAntesPath: fotoAntes == null
            ? null
            : 'data:image/jpeg;base64,${base64Encode(fotoAntes)}',
        fotoDepoisPath: fotoDepois == null
            ? null
            : 'data:image/jpeg;base64,${base64Encode(fotoDepois)}',
        assinaturaBase64: assinatura == null
            ? null
            : 'data:image/png;base64,${base64Encode(assinatura)}',
      );
    }

    return salvar(ordemFinal);
  }

  Future<void> atualizarStatus(OrdemServico ordem, String status) {
    return salvar(ordem.copyWith(status: status));
  }
}
