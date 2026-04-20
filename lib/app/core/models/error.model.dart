class ErrorModel {
  final int codeErro;
  final String titulo;
  final String mensagem;

  ErrorModel({
    required this.codeErro,
    required this.titulo,
    required this.mensagem,
  });

  // Converte o JSON vindo do Backend para o nosso modelo de erro
  factory ErrorModel.fromJson(Map<String, dynamic> json) {
    return ErrorModel(
      codeErro: json['codeErro'] ?? 500,
      titulo: json['titulo'] ?? 'Erro no Servidor',
      mensagem: json['mensagem'] ?? 'Ocorreu um erro inesperado.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeErro': codeErro,
      'titulo': titulo,
      'mensagem': mensagem,
    };
  }
}
