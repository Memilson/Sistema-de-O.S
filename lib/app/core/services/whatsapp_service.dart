import 'package:url_launcher/url_launcher.dart';

import '../helpers/app.config.dart';

class WhatsappService {
  Future<bool> abrirSuporte({String? mensagem}) async {
    final phone = AppConfig.supportWhatsappNumber;
    if (phone == null) return false;

    final text = Uri.encodeComponent(
      mensagem ?? 'Ola, preciso de suporte no ServiceFlow.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$text');

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
