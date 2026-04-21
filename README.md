# ServiceFlow

Aplicativo Flutter para cadastro de clientes e ordens de serviço, com autenticação Supabase, dashboard de KPIs e persistência local básica para mobile/desktop.

O arquivo original da aula foi preservado em [aula.md](./aula.md). Ele descreve uma arquitetura alvo maior. Este README documenta o estado real do projeto atual.

## Estado Atual

Implementado:

- App Flutter com rotas para splash, login, dashboard, cadastro de cliente e nova O.S.
- Autenticação padrão do Supabase com e-mail e senha.
- Cadastro de conta com confirmação por e-mail e redirect configurável.
- Sessão persistida pelo SDK do Supabase.
- Dashboard com KPIs reais vindos de `ordens_servico`.
- Cadastro/listagem de clientes no Supabase quando online.
- Cadastro/listagem de ordens de serviço no Supabase quando online.
- SQLite local para mobile/desktop quando offline.
- Fila local de sincronização para registros criados/editados offline.
- Upload de fotos e assinatura para Supabase Storage quando online.
- Evidências criadas offline são guardadas em Base64 e enviadas ao Storage na sincronização.
- Captura dos caminhos das fotos e assinatura na O.S.
- RLS no Supabase por usuário autenticado.
- Configuração via `.env` usando `flutter_dotenv`.
- `BaseRepository<T>` para CRUD comum Supabase/SQLite.
- `BaseViewModel<T>` com `ChangeNotifier`.
- `DioClient` com interceptor JWT.
- `AuthRepository` com persistência auxiliar em `flutter_secure_storage`.
- Listagem de clientes, listagem de O.S. e detalhe de O.S.
- Integração WhatsApp via `url_launcher`.

Parcial ou ainda pendente:

- Visualização/download das imagens do Storage dentro do app.
- Sync em background automático sem o usuário abrir o dashboard/listagem.
- Testes automatizados.
- Camada REST real. O `DioClient` existe, mas a operação principal usa o SDK do Supabase.

## Requisitos

- Flutter instalado.
- Projeto Supabase criado.
- Provider de e-mail/senha habilitado no Supabase Auth.
- URL de redirect liberada no Supabase Auth.

## Configuração

Copie o exemplo de ambiente:

```bash
cp .env.example .env
```

Preencha:

```env
SUPABASE_URL=https://seu-project-ref.supabase.co
SUPABASE_ANON_PUBLIC=sua-chave-anon-ou-publishable
SUPABASE_REDIRECT_URL=http://localhost:53368/
SUPPORT_WHATSAPP=5511999999999
```

Não coloque `SUPABASE_SERVICE_ROLE` no app Flutter. A service role é segredo de backend e nunca deve ir para frontend, web ou mobile.

No Supabase, adicione a URL de redirect em:

```text
Authentication > URL Configuration > Additional Redirect URLs
```

Exemplo para desenvolvimento:

```text
http://localhost:53368/
```

## Banco de Dados

As migrations ficam em [supabase/migrations](./supabase/migrations).

Tabelas atuais:

- `clientes`
- `ordens_servico`

Storage:

- bucket `evidencias`

Ambas usam RLS por `userId`, vinculado ao usuário autenticado em `auth.users`.

Para criar/ajustar o schema, execute no SQL Editor do Supabase as migrations:

1. `202604211_create_serviceflow_tables.sql`
2. `202604212_optimize_rls_policies.sql`
3. `202604213_create_evidencias_bucket.sql`

## Rodando

Instale as dependências:

```bash
flutter pub get
```

Rode no Chrome usando a mesma porta configurada em `SUPABASE_REDIRECT_URL`:

```bash
flutter run -d chrome --web-port 53368
```

Analise o projeto:

```bash
flutter analyze
```

## Fluxo de Autenticação

1. Usuário clica em `Criar nova conta`.
2. O app chama `Supabase.auth.signUp`.
3. O Supabase envia e-mail de confirmação.
4. O link do e-mail redireciona para `SUPABASE_REDIRECT_URL`.
5. O SDK captura a sessão.
6. O app entra no dashboard.

Se a porta mudar, atualize o `.env` e também a lista de redirects no Supabase.

## Estrutura Principal

```text
lib/
├── app/
│   ├── core/
│   │   ├── base/
│   │   ├── helpers/
│   │   ├── mixins/
│   │   ├── repositories/
│   │   ├── services/
│   │   └── theme/
│   ├── modules/
│   │   ├── auth/
│   │   ├── clientes/
│   │   ├── dashboard/
│   │   ├── ordens/
│   │   └── splash/
│   └── shared/
└── main.dart
```

## Próximos Passos Recomendados

1. Aplicar as migrations no Supabase SQL Editor.
2. Configurar o bucket `evidencias` e as policies pelas migrations.
3. Criar visualização das imagens salvas no Storage.
4. Adicionar testes automatizados para repositories e controllers.
5. Transformar a sincronização em tarefa de background em mobile.
6. Validar com o professor se a camada REST com Dio precisa ser usada no lugar do SDK Supabase.
