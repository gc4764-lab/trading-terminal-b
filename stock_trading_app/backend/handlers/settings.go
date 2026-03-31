package handlers

import (
    "net/http"
    "stock_trading_backend/models"
    "time"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type SettingsHandler struct {
    db *gorm.DB
}

func NewSettingsHandler(db *gorm.DB) *SettingsHandler {
    return &SettingsHandler{db: db}
}

func (h *SettingsHandler) GetAll(c *gin.Context) {
    var settings models.Settings
    if err := h.db.First(&settings).Error; err != nil {
        // Return default settings
        defaultSettings := models.Settings{
            ID:            "default",
            Theme:         "system",
            FontSize:      14,
            Notifications: true,
            AutoRefresh:   true,
            RefreshRate:   5,
            UpdatedAt:     time.Now(),
        }
        c.JSON(http.StatusOK, defaultSettings)
        return
    }
    c.JSON(http.StatusOK, settings)
}

func (h *SettingsHandler) Update(c *gin.Context) {
    var settings models.Settings
    if err := c.ShouldBindJSON(&settings); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    settings.UpdatedAt = time.Now()
    h.db.Save(&settings)
    c.JSON(http.StatusOK, settings)
}