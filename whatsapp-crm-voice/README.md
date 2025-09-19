# WhatsApp CRM Voice AI System 🚀

Sistema completo de CRM para WhatsApp com inteligência artificial por voz, usando OpenAI Realtime API.

## 🌟 Funcionalidades

- ✅ Chamadas de voz em tempo real com IA
- ✅ CRM completo integrado ao WhatsApp  
- ✅ Dashboard com analytics avançados
- ✅ Gestão de clientes e histórico
- ✅ Segurança e autenticação
- ✅ API RESTful completa

## 🚀 Quick Start

### 1. Configuração Inicial
```bash
# Clonar e configurar
git clone seu-repositorio
cd whatsapp-crm-voice

# Configurar variáveis de ambiente
cp backend/.env.example backend/.env
# Editar backend/.env com suas configurações
```

### 2. Executar com Docker (Recomendado)
```bash
# Subir banco de dados
docker-compose up mysql -d

# Aguardar banco inicializar (30-60 segundos)
docker-compose logs -f mysql

# Subir backend
cd backend
npm install
npm run dev
```

### 3. Frontend
```bash
# Em outro terminal
cd frontend
npm install
npm start
```

### 4. Testes
- Backend: http://localhost:5000/api/health
- Frontend: http://localhost:3000
- OpenAI Test: POST http://localhost:5000/api/test-openai

## 🔧 Configuração da OpenAI

1. Acesse: https://platform.openai.com/api-keys
2. Crie uma nova chave
3. Adicione no backend/.env:
```
OPENAI_API_KEY=sk-proj-sua_chave_aqui
```

## 📊 Banco de Dados

O sistema usa MySQL com tabelas:
- `customers` - Dados dos clientes
- `voice_sessions` - Sessões de chamadas
- `conversations` - Histórico de conversas
- `orders` - Pedidos dos clientes
- `analytics` - Métricas do sistema

## 🔐 Segurança

- Rate limiting configurado
- Chaves de API protegidas
- Senhas hasheadas
- CORS configurado
- Headers de segurança

## 📈 Monitoramento

Acesse `/api/health` para verificar status do sistema.

## 🚀 Deploy

Ver arquivo `DEPLOY.md` para instruções de produção.

## 📞 Suporte

Para suporte, entre em contato via: suporte@crmwhats.store
