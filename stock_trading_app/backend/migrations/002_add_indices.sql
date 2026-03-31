-- Additional indices for performance optimization

-- Composite indices for common queries
CREATE INDEX idx_orders_user_status_created ON orders(user_id, status, created_at DESC);
CREATE INDEX idx_positions_user_pnl ON positions(user_id, pnl DESC);
CREATE INDEX idx_alerts_user_active ON alerts(user_id, is_active);

-- Partial indices for active records
CREATE INDEX idx_active_alerts ON alerts(is_active) WHERE is_active = true;
CREATE INDEX idx_pending_orders ON orders(status) WHERE status = 'pending';

-- Full-text search for symbols
CREATE INDEX idx_symbols ON watchlist_items(symbol) WHERE symbol IS NOT NULL;

-- JSONB indices for settings (if using PostgreSQL)
-- CREATE INDEX idx_settings_json ON settings USING gin(settings_json);