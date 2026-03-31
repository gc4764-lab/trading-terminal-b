package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

type WatchlistItem struct {
    ID        string    `gorm:"primaryKey" json:"id"`
    Symbol    string    `json:"symbol"`
    Name      string    `json:"name"`
    Exchange  string    `json:"exchange"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
}

func (w *WatchlistItem) BeforeCreate(tx *gorm.DB) error {
    w.ID = uuid.New().String()
    w.CreatedAt = time.Now()
    w.UpdatedAt = time.Now()
    return nil
}

type Alert struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    Symbol      string    `json:"symbol"`
    Type        string    `json:"type"` // price, volume, percentage
    Condition   string    `json:"condition"` // above, below, crosses
    Value       float64   `json:"value"`
    IsActive    bool      `json:"isActive"`
    TriggeredAt *time.Time `json:"triggeredAt,omitempty"`
    CreatedAt   time.Time `json:"createdAt"`
    UpdatedAt   time.Time `json:"updatedAt"`
}

type Order struct {
    ID            string    `gorm:"primaryKey" json:"id"`
    BrokerID      string    `json:"brokerId"`
    Symbol        string    `json:"symbol"`
    Side          string    `json:"side"` // buy, sell
    Type          string    `json:"type"` // market, limit, stop
    Quantity      int       `json:"quantity"`
    Price         float64   `json:"price"`
    Status        string    `json:"status"` // pending, filled, cancelled
    FilledPrice   float64   `json:"filledPrice,omitempty"`
    FilledQuantity int      `json:"filledQuantity,omitempty"`
    CreatedAt     time.Time `json:"createdAt"`
    UpdatedAt     time.Time `json:"updatedAt"`
}

type Position struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    BrokerID    string    `json:"brokerId"`
    Symbol      string    `json:"symbol"`
    Quantity    int       `json:"quantity"`
    AvgPrice    float64   `json:"avgPrice"`
    CurrentPrice float64  `json:"currentPrice"`
    PnL         float64   `json:"pnl"`
    UpdatedAt   time.Time `json:"updatedAt"`
}

type Holding struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    BrokerID    string    `json:"brokerId"`
    Symbol      string    `json:"symbol"`
    Quantity    int       `json:"quantity"`
    PurchasePrice float64 `json:"purchasePrice"`
    CurrentPrice float64  `json:"currentPrice"`
    TotalValue  float64   `json:"totalValue"`
    UpdatedAt   time.Time `json:"updatedAt"`
}

type BrokerConfig struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    Name        string    `json:"name"`
    Type        string    `json:"type"` // zerodha, upstox, angel, etc.
    APIKey      string    `json:"apiKey"`
    APISecret   string    `json:"apiSecret"`
    AccessToken string    `json:"accessToken"`
    IsConnected bool      `json:"isConnected"`
    CreatedAt   time.Time `json:"createdAt"`
    UpdatedAt   time.Time `json:"updatedAt"`
}

type ChartConfig struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    Layout      string    `json:"layout"` // grid, single
    Rows        int       `json:"rows"`
    Columns     int       `json:"columns"`
    Symbols     []string  `gorm:"type:text" json:"symbols"`
    Timeframe   string    `json:"timeframe"`
    Indicators  []string  `gorm:"type:text" json:"indicators"`
    UpdatedAt   time.Time `json:"updatedAt"`
}

type Settings struct {
    ID          string    `gorm:"primaryKey" json:"id"`
    Theme       string    `json:"theme"` // light, dark, system
    FontSize    int       `json:"fontSize"`
    Notifications bool    `json:"notifications"`
    AutoRefresh  bool     `json:"autoRefresh"`
    RefreshRate  int      `json:"refreshRate"` // seconds
    UpdatedAt   time.Time `json:"updatedAt"`
}