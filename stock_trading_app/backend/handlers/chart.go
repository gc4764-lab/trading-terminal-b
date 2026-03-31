package handlers

import (
    "net/http"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type ChartHandler struct {
    db *gorm.DB
}

func NewChartHandler(db *gorm.DB) *ChartHandler {
    return &ChartHandler{db: db}
}

func (h *ChartHandler) GetConfig(c *gin.Context) {
    var config models.ChartConfig
    if err := h.db.First(&config).Error; err != nil {
        // Return default config if not found
        defaultConfig := models.ChartConfig{
            ID:         "default",
            Layout:     "grid",
            Rows:       2,
            Columns:    2,
            Symbols:    []string{"AAPL", "GOOGL", "MSFT", "AMZN"},
            Timeframe:  "1D",
            Indicators: []string{"SMA", "EMA"},
            UpdatedAt:  time.Now(),
        }
        c.JSON(http.StatusOK, defaultConfig)
        return
    }
    c.JSON(http.StatusOK, config)
}

func (h *ChartHandler) UpdateConfig(c *gin.Context) {
    var config models.ChartConfig
    if err := c.ShouldBindJSON(&config); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    config.UpdatedAt = time.Now()
    h.db.Save(&config)
    c.JSON(http.StatusOK, config)
}