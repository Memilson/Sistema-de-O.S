import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  }) : evidenceStorageService = evidenceStorageService ?? EvidenceStorageService();

  @override
  String get tableName => 'ordens_servico';

  @override
  bool get defaultAscending => false;

  @override
  OrdemServico fromMap(Map<String, dynamic> map) => OrdemServico.fromMap(map);

  Future<String> salvarComEvidencias(OrdemServico ordem, {Uint8List? fotoAntes, Uint8List? fotoDepois, Uint8List? assinatura}) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('Usuario nao autenticado');

    final ordemId = ordem.id ?? const Uuid().v4();
    var ordemFinal = ordem.copyWith(id: ordemId);
    final hasEvidence = fotoAntes != null || fotoDepois != null || assinatura != null;

    if (hasEvidence) {
      if (!kIsWeb) {
        // Always save locally first for robust offline support
        final localPaths = <String, String>{};
        if (fotoAntes != null) localPaths['fotoAntesPath'] = await _saveLocalFile(ordemId, 'foto_antes.jpg', fotoAntes);
        if (fotoDepois != null) localPaths['fotoDepoisPath'] = await _saveLocalFile(ordemId, 'foto_depois.jpg', fotoDepois);
        if (assinatura != null) localPaths['assinaturaBase64'] = await _saveLocalFile(ordemId, 'assinatura.png', assinatura);
        
        ordemFinal = ordemFinal.copyWith(
          fotoAntesPath: localPaths['fotoAntesPath'] ?? ordemFinal.fotoAntesPath,
          fotoDepoisPath: localPaths['fotoDepoisPath'] ?? ordemFinal.fotoDepoisPath,
          assinaturaBase64: localPaths['assinaturaBase64'] ?? ordemFinal.assinaturaBase64,
        );
      } else if (kIsWeb && await ConnectivityHelper.isOnline()) {
        // On Web, we must upload immediately as there is no local file system
        final uploaded = <String, String>{};
        if (fotoAntes != null) {
          uploaded['fotoAntesPath'] = await evidenceStorageService.uploadBytes(ordemId: ordemId, fileName: 'foto_antes.jpg', bytes: fotoAntes, contentType: 'image/jpeg');
        }
        if (fotoDepois != null) {
          uploaded['fotoDepoisPath'] = await evidenceStorageService.uploadBytes(ordemId: ordemId, fileName: 'foto_depois.jpg', bytes: fotoDepois, contentType: 'image/jpeg');
        }
        if (assinatura != null) {
          uploaded['assinaturaBase64'] = await evidenceStorageService.uploadBytes(ordemId: ordemId, fileName: 'assinatura.png', bytes: assinatura, contentType: 'image/png');
        }
        ordemFinal = ordemFinal.copyWith(
          fotoAntesPath: uploaded['fotoAntesPath'] ?? ordemFinal.fotoAntesPath,
          fotoDepoisPath: uploaded['fotoDepoisPath'] ?? ordemFinal.fotoDepoisPath,
          assinaturaBase64: uploaded['assinaturaBase64'] ?? ordemFinal.assinaturaBase64,
        );
      }
    }

    // Try to sync immediately if online (awaited so errors are not silently swallowed)
    final savedId = await salvar(ordemFinal);
    if (await ConnectivityHelper.isOnline()) {
      await offlineSyncService.syncPending();
    }
    return savedId;
  }

  Future<String> _saveLocalFile(String ordemId, String fileName, Uint8List bytes) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final serviceFlowDir = Directory('${appDocDir.path}/serviceflow/evidencias/$ordemId');
    if (!await serviceFlowDir.exists()) {
      await serviceFlowDir.create(recursive: true);
    }
    final file = File('${serviceFlowDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> atualizarStatus(OrdemServico ordem, String status) {
    return salvar(ordem.copyWith(status: status));
  }
}
