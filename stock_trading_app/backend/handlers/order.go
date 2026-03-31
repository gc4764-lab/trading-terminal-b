package handlers

import (
    "net/http"
    "time"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type OrderHandler struct {
    db *gorm.DB
}

func NewOrderHandler(db *gorm.DB) *OrderHandler {
    return &OrderHandler{db: db}
}

func (h *OrderHandler) GetAll(c *gin.Context) {
    var orders []models.Order
    brokerId := c.Query("brokerId")
    
    query := h.db
    if brokerId != "" {
        query = query.Where("broker_id = ?", brokerId)
    }
    
    if err := query.Order("created_at DESC").Find(&orders).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, orders)
}

func (h *OrderHandler) GetByID(c *gin.Context) {
    id := c.Param("id")
    var order models.Order
    
    if err := h.db.First(&order, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
        return
    }
    
    c.JSON(http.StatusOK, order)
}

func (h *OrderHandler) Create(c *gin.Context) {
    var order models.Order
    if err := c.ShouldBindJSON(&order); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    order.Status = "pending"
    order.CreatedAt = time.Now()
    order.UpdatedAt = time.Now()
    
    // Validate order
    if err := validateOrder(order); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // Place order with broker
    go func() {
        // Async order placement
        if err := placeOrderWithBroker(&order); err != nil {
            order.Status = "failed"
            h.db.Save(&order)
        }
    }()
    
    if err := h.db.Create(&order).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusCreated, order)
}

func (h *OrderHandler) Update(c *gin.Context) {
    id := c.Param("id")
    var order models.Order
    
    if err := h.db.First(&order, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
        return
    }
    
    var updateData models.Order
    if err := c.ShouldBindJSON(&updateData); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // Only allow updating certain fields
    if updateData.Status != "" {
        order.Status = updateData.Status
    }
    if updateData.FilledPrice != nil {
        order.FilledPrice = updateData.FilledPrice
    }
    if updateData.FilledQuantity != nil {
        order.FilledQuantity = updateData.FilledQuantity
    }
    
    order.UpdatedAt = time.Now()
    
    h.db.Save(&order)
    c.JSON(http.StatusOK, order)
}

func (h *OrderHandler) Cancel(c *gin.Context) {
    id := c.Param("id")
    var order models.Order
    
    if err := h.db.First(&order, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
        return
    }
    
    if order.Status != "pending" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel order in status: " + order.Status})
        return
    }
    
    order.Status = "cancelled"
    order.UpdatedAt = time.Now()
    
    h.db.Save(&order)
    c.JSON(http.StatusOK, gin.H{"message": "Order cancelled successfully"})
}

func validateOrder(order models.Order) error {
    if order.Symbol == "" {
        return fmt.Errorf("symbol is required")
    }
    if order.Quantity <= 0 {
        return fmt.Errorf("quantity must be greater than 0")
    }
    if order.Type == "limit" && order.Price <= 0 {
        return fmt.Errorf("price is required for limit orders")
    }
    return nil
}

func placeOrderWithBroker(order *models.Order) error {
    // Implement broker-specific order placement
    // This would call the appropriate broker API
    return nil
}