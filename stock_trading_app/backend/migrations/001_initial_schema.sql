-- Initial Schema for Stock Trading Application

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Watchlist table
CREATE TABLE IF NOT EXISTS watchlist_items (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    symbol VARCHAR(10) NOT NULL,
    name VARCHAR(255),
    exchange VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, symbol)
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    symbol VARCHAR(10) NOT NULL,
    type VARCHAR(20) NOT NULL,
    condition VARCHAR(20) NOT NULL,
    value DECIMAL(20, 8) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_symbol (user_id, symbol),
    INDEX idx_active (is_active)
);

-- Broker configurations table
CREATE TABLE IF NOT EXISTS broker_configs (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    access_token TEXT,
    is_connected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, type)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    broker_id VARCHAR(36) REFERENCES broker_configs(id),
    symbol VARCHAR(10) NOT NULL,
    side VARCHAR(10) NOT NULL,
    type VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(20, 8),
    status VARCHAR(20) DEFAULT 'pending',
    filled_price DECIMAL(20, 8),
    filled_quantity INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_status (user_id, status),
    INDEX idx_symbol (symbol)
);

-- Positions table
CREATE TABLE IF NOT EXISTS positions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    broker_id VARCHAR(36) REFERENCES broker_configs(id),
    symbol VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    avg_price DECIMAL(20, 8) NOT NULL,
    current_price DECIMAL(20, 8),
    pnl DECIMAL(20, 8),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, broker_id, symbol),
    INDEX idx_user_symbol (user_id, symbol)
);

-- Holdings table
CREATE TABLE IF NOT EXISTS holdings (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    broker_id VARCHAR(36) REFERENCES broker_configs(id),
    symbol VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    purchase_price DECIMAL(20, 8) NOT NULL,
    current_price DECIMAL(20, 8),
    total_value DECIMAL(20, 8),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, broker_id, symbol)
);

-- Chart configurations table
CREATE TABLE IF NOT EXISTS chart_configs (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    layout VARCHAR(20) DEFAULT 'grid',
    rows INT DEFAULT 2,
    columns INT DEFAULT 2,
    symbols TEXT,
    timeframe VARCHAR(10) DEFAULT '1D',
    indicators TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Settings table
CREATE TABLE IF NOT EXISTS settings (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'system',
    font_size INT DEFAULT 14,
    notifications BOOLEAN DEFAULT TRUE,
    auto_refresh BOOLEAN DEFAULT TRUE,
    refresh_rate INT DEFAULT 5,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Risk limits table
CREATE TABLE IF NOT EXISTS risk_limits (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    max_position_size DECIMAL(5, 2) DEFAULT 10.0,
    max_daily_loss DECIMAL(5, 2) DEFAULT 2.0,
    stop_loss DECIMAL(5, 2) DEFAULT 5.0,
    max_leverage INT DEFAULT 3,
    max_concentration DECIMAL(5, 2) DEFAULT 25.0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Performance metrics table (for analytics)
CREATE TABLE IF NOT EXISTS performance_metrics (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_pnl DECIMAL(20, 8),
    win_rate DECIMAL(5, 2),
    sharpe_ratio DECIMAL(10, 4),
    max_drawdown DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date),
    INDEX idx_date (date)
);

-- Create indexes for better performance
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_alerts_triggered_at ON alerts(triggered_at);
CREATE INDEX idx_positions_pnl ON positions(pnl);