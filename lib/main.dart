import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app_widget.dart';
import 'app/core/helpers/app.config.dart';
import 'app/core/helpers/database_helper.dart';
import 'app/core/services/dio_client.dart';
import 'app/core/services/evidence_storage_service.dart';
import 'app/core/services/offline_sync_service.dart';
import 'app/core/services/service_locator.dart';
import 'app/core/services/whatsapp_service.dart';
import 'app/modules/auth/auth_repository.dart';
import 'app/modules/clientes/cliente_repository.dart';
import 'app/modules/ordens/ordem_servico_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseKey);
  if (!kIsWeb) await DatabaseHelper.instance.db;
  _registerDependencies();
  runApp(const AppEntry());
}
void _registerDependencies() {
  final locator = ServiceLocator.instance;
  final offlineSyncService = OfflineSyncService();
  final evidenceStorageService = EvidenceStorageService();
  locator.registerSingleton(DioClient());
  locator.registerSingleton(offlineSyncService);
  locator.registerSingleton(evidenceStorageService);
  locator.registerSingleton(WhatsappService());
  locator.registerSingleton(AuthRepository());
  locator.registerSingleton(ClienteRepository(offlineSyncService: offlineSyncService));
  locator.registerSingleton(OrdemServicoRepository(offlineSyncService: offlineSyncService, evidenceStorageService: evidenceStorageService));
}
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});
  @override
  Widget build(BuildContext context) {
    return AppWidget();
  }
}
