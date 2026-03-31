package handlers

import (
    "net/http"
    "time"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type AlertHandler struct {
    db *gorm.DB
}

func NewAlertHandler(db *gorm.DB) *AlertHandler {
    return &AlertHandler{db: db}
}

func (h *AlertHandler) GetAll(c *gin.Context) {
    var alerts []models.Alert
    isActive := c.Query("isActive")
    
    query := h.db
    if isActive != "" {
        query = query.Where("is_active = ?", isActive == "true")
    }
    
    if err := query.Order("created_at DESC").Find(&alerts).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, alerts)
}

func (h *AlertHandler) Create(c *gin.Context) {
    var alert models.Alert
    if err := c.ShouldBindJSON(&alert); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    alert.IsActive = true
    alert.CreatedAt = time.Now()
    alert.UpdatedAt = time.Now()
    
    if err := h.db.Create(&alert).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    // Start monitoring the alert
    go h.monitorAlert(alert)
    
    c.JSON(http.StatusCreated, alert)
}

func (h *AlertHandler) Update(c *gin.Context) {
    id := c.Param("id")
    var alert models.Alert
    
    if err := h.db.First(&alert, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
        return
    }
    
    var updateData models.Alert
    if err := c.ShouldBindJSON(&updateData); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // Update fields
    if updateData.Symbol != "" {
        alert.Symbol = updateData.Symbol
    }
    if updateData.Type != "" {
        alert.Type = updateData.Type
    }
    if updateData.Condition != "" {
        alert.Condition = updateData.Condition
    }
    if updateData.Value != 0 {
        alert.Value = updateData.Value
    }
    alert.IsActive = updateData.IsActive
    alert.UpdatedAt = time.Now()
    
    h.db.Save(&alert)
    
    // Restart monitoring if active
    if alert.IsActive {
        go h.monitorAlert(alert)
    }
    
    c.JSON(http.StatusOK, alert)
}

func (h *AlertHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    h.db.Delete(&models.Alert{}, "id = ?", id)
    c.JSON(http.StatusOK, gin.H{"message": "Alert deleted successfully"})
}

func (h *AlertHandler) TriggerAlert(c *gin.Context) {
    id := c.Param("id")
    var alert models.Alert
    
    if err := h.db.First(&alert, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
        return
    }
    
    now := time.Now()
    alert.TriggeredAt = &now
    alert.IsActive = false
    
    h.db.Save(&alert)
    
    // Send notification
    go h.sendAlertNotification(alert)
    
    c.JSON(http.StatusOK, gin.H{"message": "Alert triggered successfully"})
}

func (h *AlertHandler) monitorAlert(alert models.Alert) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()
    
    for range ticker.C {
        // Check if alert is still active
        var currentAlert models.Alert
        if err := h.db.First(&currentAlert, "id = ?", alert.ID).Error; err != nil {
            return
        }
        
        if !currentAlert.IsActive {
            return
        }
        
        // Fetch current price for symbol
        currentPrice := h.getCurrentPrice(alert.Symbol)
        
        // Check condition
        triggered := false
        switch alert.Condition {
        case "above":
            if currentPrice >= alert.Value {
                triggered = true
            }
        case "below":
            if currentPrice <= alert.Value {
                triggered = true
            }
        case "crosses":
            previousPrice := h.getPreviousPrice(alert.Symbol)
            if (previousPrice < alert.Value && currentPrice >= alert.Value) ||
                (previousPrice > alert.Value && currentPrice <= alert.Value) {
                triggered = true
            }
        }
        
        if triggered {
            h.TriggerAlertByID(alert.ID)
            return
        }
    }
}

func (h *AlertHandler) getCurrentPrice(symbol string) float64 {
    // Fetch from market data service
    return 0.0
}

func (h *AlertHandler) getPreviousPrice(symbol string) float64 {
    // Fetch from market data service
    return 0.0
}

func (h *AlertHandler) TriggerAlertByID(id string) {
    var alert models.Alert
    if err := h.db.First(&alert, "id = ?", id).Error; err != nil {
        return
    }
    
    now := time.Now()
    alert.TriggeredAt = &now
    alert.IsActive = false
    h.db.Save(&alert)
    
    h.sendAlertNotification(alert)
}

func (h *AlertHandler) sendAlertNotification(alert models.Alert) {
    // Send notification via WebSocket to connected clients
    // This would be implemented with a WebSocket hub
}