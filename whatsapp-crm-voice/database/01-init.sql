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
