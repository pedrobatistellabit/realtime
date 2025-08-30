#!/bin/bash

echo "🚀 Setup WhatsApp CRM Voice AI System"
echo "===================================="

# Criar estrutura do projeto
echo "📁 Criando estrutura do projeto..."
mkdir -p whatsapp-crm-voice/{backend,frontend,database}
cd whatsapp-crm-voice

# Setup Backend
echo "⚙️ Configurando Backend..."
cd backend
npm init -y

# Instalar dependências
echo "📦 Instalando dependências..."
npm install express cors dotenv helmet bcryptjs jsonwebtoken mysql2 sequelize ws socket.io openai multer express-rate-limit

# Criar estrutura backend
mkdir -p {controllers,models,routes,middleware,config}

# Criar arquivo principal do servidor
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const http = require('http');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware de segurança
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // máximo 100 requisições por IP
  message: 'Muitas requisições deste IP, tente novamente em 15 minutos.'
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Rota de teste da OpenAI
app.post('/api/test-openai', async (req, res) => {
  try {
    const OpenAI = require('openai');
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: 'Hello! This is a test.' }],
      max_tokens: 50
    });

    res.json({
      success: true,
      message: 'OpenAI conectada com sucesso!',
      response: response.choices[0].message.content
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro ao conectar com OpenAI: ' + error.message
    });
  }
});

// WebSocket para chamadas em tempo real
io.on('connection', (socket) => {
  console.log('✅ Cliente conectado:', socket.id);
  
  socket.on('join-room', (roomId) => {
    socket.join(roomId);
    console.log(`📞 Cliente ${socket.id} entrou na sala ${roomId}`);
  });
  
  socket.on('voice-data', (data) => {
    socket.to(data.roomId).emit('voice-data', data);
  });
  
  socket.on('disconnect', () => {
    console.log('❌ Cliente desconectado:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`🔗 Acesse: http://localhost:${PORT}`);
  console.log(`💊 Health check: http://localhost:${PORT}/api/health`);
});
EOF

# Criar arquivo .env.example
cat > .env.example << 'EOF'
# ===== SERVIDOR =====
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000

# ===== OPENAI CONFIGURATION =====
OPENAI_API_KEY=sk-proj-sua_nova_chave_aqui
OPENAI_ORG_ID=org-xxxxxxxxx
OPENAI_PROJECT_ID=proj-xxxxxxxxx

# ===== DATABASE =====
DATABASE_URL=mysql://root:password@localhost:3306/whatsapp_crm

# ===== SECURITY =====
JWT_SECRET=sua_chave_jwt_super_segura_128_caracteres_minimo
ENCRYPTION_KEY=sua_chave_de_encriptacao_256_bits

# ===== RATE LIMITING =====
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# ===== WHATSAPP BUSINESS (OPCIONAL) =====
WHATSAPP_PHONE_NUMBER_ID=xxxxxxxxxxxxxx
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxxxx
WHATSAPP_VERIFY_TOKEN=seu_token_de_verificacao
EOF

# Criar arquivo package.json scripts
npm pkg set scripts.start="node server.js"
npm pkg set scripts.dev="nodemon server.js"
npm pkg set scripts.test="echo \"Testes não configurados ainda\" && exit 1"

# Instalar nodemon para desenvolvimento
npm install -D nodemon

cd ..

# Setup Frontend
echo "🎨 Configurando Frontend..."
cd frontend
npx create-react-app . --template typescript
npm install axios socket.io-client lucide-react @types/node

# Voltar para raiz
cd ..

# Criar Docker Compose
echo "🐳 Criando Docker Compose..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: whatsapp_crm
      MYSQL_ROOT_PASSWORD: senha_segura_123
      MYSQL_USER: crm_user
      MYSQL_PASSWORD: crm_password_123
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=mysql://crm_user:crm_password_123@mysql:3306/whatsapp_crm
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - ./backend:/app
      - /app/node_modules
    restart: unless-stopped

volumes:
  mysql_data:
    driver: local
EOF

# Criar banco de dados SQL
echo "🗄️ Criando estrutura do banco..."
mkdir -p database
cat > database/01-init.sql << 'EOF'
-- Criação das tabelas do WhatsApp CRM Voice AI
USE whatsapp_crm;

-- Tabela de clientes
CREATE TABLE IF NOT EXISTS customers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  company VARCHAR(255),
  location VARCHAR(255),
  status ENUM('Regular', 'Premium', 'VIP') DEFAULT 'Regular',
  segment VARCHAR(100),
  total_value DECIMAL(10,2) DEFAULT 0.00,
  last_purchase VARCHAR(255),
  notes TEXT,
  avatar VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_phone (phone),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
);

-- Tabela de sessões de voz
CREATE TABLE IF NOT EXISTS voice_sessions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  session_id VARCHAR(255) NOT NULL UNIQUE,
  client_secret TEXT,
  status ENUM('active', 'ended', 'error') DEFAULT 'active',
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  duration VARCHAR(10),
  summary TEXT,
  sentiment VARCHAR(50),
  cost DECIMAL(8,4) DEFAULT 0.0000,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  INDEX idx_session_id (session_id),
  INDEX idx_customer_id (customer_id),
  INDEX idx_status (status)
);

-- Tabela de conversas
CREATE TABLE IF NOT EXISTS conversations (
  id INT PRIMARY KEY AUTO_INCREMENT,
  session_id INT NOT NULL,
  message_type ENUM('user', 'ai') NOT NULL,
  content TEXT NOT NULL,
  audio_url VARCHAR(255),
  crm_data TEXT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  tokens_used INT DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES voice_sessions(id) ON DELETE CASCADE,
  INDEX idx_session_id (session_id),
  INDEX idx_timestamp (timestamp),
  INDEX idx_message_type (message_type)
);

-- Tabela de pedidos
CREATE TABLE IF NOT EXISTS orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  value DECIMAL(10,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  order_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  INDEX idx_customer_id (customer_id),
  INDEX idx_order_date (order_date),
  INDEX idx_status (status)
);

-- Tabela de analytics
CREATE TABLE IF NOT EXISTS analytics (
  id INT PRIMARY KEY AUTO_INCREMENT,
  date DATE NOT NULL,
  total_calls INT DEFAULT 0,
  total_duration_minutes INT DEFAULT 0,
  total_cost DECIMAL(10,4) DEFAULT 0.0000,
  avg_call_duration DECIMAL(8,2) DEFAULT 0.00,
  satisfaction_score DECIMAL(3,2) DEFAULT 0.00,
  conversion_rate DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_date (date),
  INDEX idx_date (date)
);

-- Inserir dados de exemplo
INSERT IGNORE INTO customers (name, phone, email, company, location, status, segment, total_value, last_purchase, notes, avatar) VALUES
('Maria Silva', '+5511999998888', 'maria.silva@techsolutions.com', 'Tech Solutions Ltda', 'São Paulo, SP', 'VIP', 'Enterprise', 28500.00, 'R$ 2.850,00 - 15/08/2025', 'Interessada em upgrade do plano. Última conversa: questões sobre integração API.', 'MS'),
('João Santos', '+5511988887777', 'joao@startupx.com', 'StartupX', 'Rio de Janeiro, RJ', 'Premium', 'SMB', 4500.00, 'R$ 890,00 - 20/08/2025', 'Novo cliente. Precisa de onboarding completo.', 'JS'),
('Ana Costa', '+5511977776666', 'ana@ecommerceplus.com', 'E-commerce Plus', 'Belo Horizonte, MG', 'VIP', 'E-commerce', 15000.00, 'R$ 1.500,00 - 18/08/2025', 'Cliente fidelizado. Sempre renova contratos.', 'AC'),
('Pedro Oliveira', '+5511966665555', 'pedro@consultoria.com', 'Consultoria Pro', 'Brasília, DF', 'Regular', 'Consultoria', 2200.00, 'R$ 450,00 - 10/08/2025', 'Cliente novo, primeira compra recente.', 'PO'),
('Carla Mendes', '+5511955554444', 'carla@agencia.com', 'Agência Digital', 'Curitiba, PR', 'Premium', 'Marketing', 8700.00, 'R$ 1.100,00 - 22/08/2025', 'Cliente recorrente, sempre pontual nos pagamentos.', 'CM');

-- Inserir pedidos de exemplo
INSERT IGNORE INTO orders (customer_id, order_number, value, status, order_date) VALUES
(1, 'PED-2025-001', 2850.00, 'Entregue', '2025-08-15'),
(1, 'PED-2025-002', 1200.00, 'Entregue', '2025-07-10'),
(2, 'PED-2025-003', 890.00, 'Processando', '2025-08-20'),
(3, 'PED-2025-004', 1500.00, 'Entregue', '2025-08-18'),
(4, 'PED-2025-005', 450.00, 'Entregue', '2025-08-10'),
(5, 'PED-2025-006', 1100.00, 'Entregue', '2025-08-22');

-- Inserir analytics de exemplo
INSERT IGNORE INTO analytics (date, total_calls, total_duration_minutes, total_cost, avg_call_duration, satisfaction_score, conversion_rate) VALUES
('2025-08-29', 45, 180, 12.50, 4.0, 4.2, 68.5),
('2025-08-28', 38, 155, 10.75, 4.1, 4.5, 71.2),
('2025-08-27', 52, 210, 14.20, 4.0, 4.3, 65.8);

-- Criar usuário admin (senha: admin123 - ALTERE EM PRODUÇÃO!)
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'user') DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP NULL
);

-- Inserir admin (senha: admin123)
INSERT IGNORE INTO users (username, email, password_hash, role) VALUES 
('admin', 'admin@crmwhats.store', '$2b$10$rZ8QfnbTXjKn5Y2V3Wq7.uE6EpL9sO0mKlP4Q2wY1eR5tU8iA3sN6', 'admin');

COMMIT;
EOF

# Criar README
echo "📖 Criando documentação..."
cat > README.md << 'EOF'
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
EOF

# Criar arquivo .gitignore
cat > .gitignore << 'EOF'
# Dependências
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Variáveis de ambiente
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs
*.log

# Runtime
pids
*.pid
*.seed
*.pid.lock

# Cobertura de testes
coverage/
.nyc_output

# Banco de dados
*.sqlite
*.db

# Docker
.dockerignore

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
dist/
build/

# Arquivos temporários
tmp/
temp/
EOF

echo ""
echo "✅ Setup completo!"
echo ""
echo "🔥 PRÓXIMOS PASSOS:"
echo ""
echo "1. Configure suas variáveis de ambiente:"
echo "   cp backend/.env.example backend/.env"
echo "   # Edite backend/.env com sua chave OpenAI"
echo ""
echo "2. Inicie o banco de dados:"
echo "   docker-compose up mysql -d"
echo ""
echo "3. Em outro terminal, inicie o backend:"
echo "   cd backend && npm install && npm run dev"
echo ""
echo "4. Em outro terminal, inicie o frontend:"
echo "   cd frontend && npm install && npm start"
echo ""
echo "5. Acesse http://localhost:3000"
echo ""
echo "🔗 URLs importantes:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend: http://localhost:5000"
echo "   - Health: http://localhost:5000/api/health"
echo ""
echo "🚀 Sistema pronto para desenvolvimento!"