# � ConectaBoi Mobile - Sistema de Controle de Combustível

[![Flutter](https://img.shields.io/badge/Flutter-3.32.8-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![OAuth](https://img.shields.io/badge/OAuth-Google-red.svg)](https://developers.google.com/identity)

Aplicativo móvel para controle e gerenciamento de combustível em fazendas e confinamentos, desenvolvido em Flutter com autenticação OAuth Google e backend Supabase.

## 📱 Funcionalidades

### ✅ Autenticação

- **Login OAuth Google** - Integração completa e segura
- **Sessões persistentes** com refresh token automático
- **Controle de acesso** baseado em perfis de usuário

### ✅ Dashboard Principal

- **Resumo executivo** com métricas do dia
- **Status dos tanques** em tempo real
- **Alertas críticos** e notificações
- **Ações rápidas** para navegação

### ✅ Controle de Combustível

- **CRUD completo** de lançamentos
- **Filtros avançados** por período, tipo, equipamento
- **Validação de dados** em tempo real
- **Cálculo automático** de valores
- **Estatísticas** e relatórios

### ✅ Interface Moderna

- **Design responsivo** para web e mobile
- **Material Design** com tema escuro/claro
- **Estados de loading** e feedback visual
- **Navegação intuitiva** com bottom navigation

## 🏗️ Arquitetura

```
lib/
├── core/                     # Configurações centrais
│   ├── constants/           # Constantes e configurações
│   └── services/            # Serviços de autenticação
├── data/                    # Camada de dados
│   └── models/             # Modelos de dados legacy
├── models/                  # Modelos principais
│   └── lancamento_combustivel.dart
├── services/                # Serviços de negócio
│   └── combustivel_service.dart
├── providers/               # Gerenciamento de estado
│   └── combustivel_provider.dart
├── pages/                   # Páginas da nova funcionalidade
│   ├── combustivel_list_page.dart
│   └── combustivel_form_page.dart
├── presentation/            # Camada de apresentação
│   └── pages/              # Páginas principais
├── shared/                  # Componentes compartilhados
│   ├── themes/             # Temas da aplicação
│   └── widgets/            # Widgets reutilizáveis
└── main.dart               # Ponto de entrada
```

## � Como Executar

### Pré-requisitos

- Flutter 3.32.8 ou superior
- Dart SDK
- Chrome (para desenvolvimento web)
- Conta no Supabase configurada
- Projeto no Google Console configurado

### Configuração

1. Clone o repositório:

```bash
git clone https://github.com/AlanCrestani/ConectaBoi-Mobile.git
cd ConectaBoi-Mobile
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Configure as variáveis de ambiente:

- Supabase URL e Anon Key em `lib/core/constants/supabase_config.dart`
- OAuth redirect URLs no Supabase Dashboard

### Execução

```bash
# Desenvolvimento Web (porta fixa 3000)
flutter run -d chrome --web-port=3000

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## �️ Modelo de Dados

### LançamentoCombustível

```dart
{
  id: String?                   // UUID gerado automaticamente
  confinamentoId: String        // ID do confinamento
  data: DateTime                // Data do lançamento
  tipoCombustivel: String       // Diesel, Gasolina, Etanol, GNV
  quantidadeLitros: double      // Quantidade em litros
  precoUnitario: double         // Preço por litro
  valorTotal: double            // Valor total da compra
  equipamento: String           // Equipamento utilizado
  operador: String              // Operador responsável
  observacoes: String?          // Observações opcionais
  createdAt: DateTime?          // Data de criação
  updatedAt: DateTime?          // Data de atualização
  createdBy: String?            // ID do usuário criador
  mobileCreatedAt: DateTime?    // Data de criação no mobile
  mobileSyncedAt: DateTime?     // Data de sincronização
  isSynced: bool                // Status de sincronização
}
```

## � Tecnologias

- **Frontend:** Flutter 3.32.8
- **Backend:** Supabase (PostgreSQL + APIs)
- **Autenticação:** OAuth 2.0 Google + Supabase Auth
- **Estado:** Provider Pattern
- **UI:** Material Design
- **Validação:** Flutter Form Validation
- **HTTP:** Supabase Client

## 📊 Dependências Principais

```yaml
dependencies:
  flutter: sdk
  supabase_flutter: ^2.5.6 # Backend integration
  provider: ^6.1.2 # State management
  google_sign_in: ^6.2.1 # OAuth Google
  intl: ^0.19.0 # Internationalization
  http: ^1.1.0 # HTTP requests
  shared_preferences: ^2.2.2 # Local storage
```

## 🎯 Status do Projeto

### ✅ Funcionalidades Implementadas

- [x] Autenticação OAuth Google
- [x] Dashboard com métricas
- [x] CRUD de lançamentos de combustível
- [x] Sistema de filtros
- [x] Validações e cálculos
- [x] Interface responsiva
- [x] Provider state management
- [x] Integração Supabase completa

### 🔄 Próximas Funcionalidades

- [ ] Relatórios PDF
- [ ] Gráficos e analytics
- [ ] Notificações push
- [ ] Modo offline
- [ ] Sincronização automática
- [ ] Gestão de usuários
- [ ] Backup automático

## 🔐 Configuração OAuth

### Google Console

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Configure OAuth 2.0 client IDs
3. Adicione URLs autorizadas:
   - `http://localhost:3000` (desenvolvimento)
   - Seu domínio de produção

### Supabase

1. Configure Provider OAuth Google
2. Adicione redirect URLs:
   - `http://localhost:3000/auth/callback`
   - URLs de produção
3. Configure RLS (Row Level Security)

## 👨‍💻 Desenvolvedor

**Alan Crestani**

- GitHub: [@AlanCrestani](https://github.com/AlanCrestani)

## 📄 Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

### 🎉 Status: Funcional e Pronto para Produção!

O sistema está **100% funcional** com autenticação OAuth, dashboard completo e controle de combustível operacional.

**Última atualização:** 03 de Agosto de 2025
