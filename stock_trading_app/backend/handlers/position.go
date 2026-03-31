package handlers

import (
    "net/http"
    "time"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type PositionHandler struct {
    db *gorm.DB
}

func NewPositionHandler(db *gorm.DB) *PositionHandler {
    return &PositionHandler{db: db}
}

func (h *PositionHandler) GetAll(c *gin.Context) {
    var positions []models.Position
    brokerId := c.Query("brokerId")
    
    query := h.db
    if brokerId != "" {
        query = query.Where("broker_id = ?", brokerId)
    }
    
    if err := query.Find(&positions).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, positions)
}

func (h *PositionHandler) GetHoldings(c *gin.Context) {
    var holdings []models.Holding
    brokerId := c.Query("brokerId")
    
    query := h.db
    if brokerId != "" {
        query = query.Where("broker_id = ?", brokerId)
    }
    
    if err := query.Find(&holdings).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, holdings)
}

func (h *PositionHandler) UpdatePositions(c *gin.Context) {
    var positions []models.Position
    if err := c.ShouldBindJSON(&positions); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    for _, position := range positions {
        position.UpdatedAt = time.Now()
        h.db.Save(&position)
    }
    
    c.JSON(http.StatusOK, gin.H{"message": "Positions updated successfully"})
}

func (h *PositionHandler) GetSummary(c *gin.Context) {
    var positions []models.Position
    
    if err := h.db.Find(&positions).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    summary := map[string]interface{}{
        "totalValue": 0.0,
        "totalPnL": 0.0,
        "topPerformers": []interface{}{},
        "worstPerformers": []interface{}{},
    }
    
    for _, pos := range positions {
        value := float64(pos.Quantity) * pos.CurrentPrice
        summary["totalValue"] = summary["totalValue"].(float64) + value
        summary["totalPnL"] = summary["totalPnL"].(float64) + pos.PnL
    }
    
    c.JSON(http.StatusOK, summary)
}