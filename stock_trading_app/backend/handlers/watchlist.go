package handlers

import (
    "net/http"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
)

type WatchlistHandler struct {
    db *gorm.DB
}

func NewWatchlistHandler(db *gorm.DB) *WatchlistHandler {
    return &WatchlistHandler{db: db}
}

func (h *WatchlistHandler) GetAll(c *gin.Context) {
    var items []models.WatchlistItem
    h.db.Find(&items)
    c.JSON(http.StatusOK, items)
}

func (h *WatchlistHandler) Create(c *gin.Context) {
    var item models.WatchlistItem
    if err := c.ShouldBindJSON(&item); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    if err := h.db.Create(&item).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusCreated, item)
}

func (h *WatchlistHandler) Update(c *gin.Context) {
    id := c.Param("id")
    var item models.WatchlistItem
    
    if err := h.db.First(&item, "id = ?", id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
        return
    }
    
    if err := c.ShouldBindJSON(&item); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    h.db.Save(&item)
    c.JSON(http.StatusOK, item)
}

func (h *WatchlistHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    h.db.Delete(&models.WatchlistItem{}, "id = ?", id)
    c.JSON(http.StatusOK, gin.H{"message": "Deleted successfully"})
}