package main

import (
    "log"
    "stock_trading_backend/handlers"
    "stock_trading_backend/models"
    "github.com/gin-gonic/gin"
    "github.com/gin-contrib/cors"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
)

func main() {
    // Initialize database
    db, err := gorm.Open(sqlite.Open("trading.db"), &gorm.Config{})
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }

    // Auto migrate models
    db.AutoMigrate(
        &models.WatchlistItem{},
        &models.Alert{},
        &models.Order{},
        &models.Position{},
        &models.Holding{},
        &models.BrokerConfig{},
        &models.ChartConfig{},
        &models.Settings{},
    )

    // Initialize handlers
    watchlistHandler := handlers.NewWatchlistHandler(db)
    alertHandler := handlers.NewAlertHandler(db)
    orderHandler := handlers.NewOrderHandler(db)
    positionHandler := handlers.NewPositionHandler(db)
    brokerHandler := handlers.NewBrokerHandler(db)
    chartHandler := handlers.NewChartHandler(db)
    settingsHandler := handlers.NewSettingsHandler(db)
    newsHandler := handlers.NewNewsHandler()

    // Setup router
    router := gin.Default()
    
    // Configure CORS
    router.Use(cors.New(cors.Config{
        AllowOrigins:     []string{"http://localhost:3000", "http://localhost:5000"},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
    }))

    // API routes
    api := router.Group("/api")
    {
        // Watchlist routes
        api.GET("/watchlist", watchlistHandler.GetAll)
        api.POST("/watchlist", watchlistHandler.Create)
        api.PUT("/watchlist/:id", watchlistHandler.Update)
        api.DELETE("/watchlist/:id", watchlistHandler.Delete)

        // Alert routes
        api.GET("/alerts", alertHandler.GetAll)
        api.POST("/alerts", alertHandler.Create)
        api.PUT("/alerts/:id", alertHandler.Update)
        api.DELETE("/alerts/:id", alertHandler.Delete)

        // Order routes
        api.GET("/orders", orderHandler.GetAll)
        api.POST("/orders", orderHandler.Create)
        
        // Position routes
        api.GET("/positions", positionHandler.GetAll)
        api.GET("/holdings", positionHandler.GetHoldings)

        // Broker routes
        api.GET("/brokers", brokerHandler.GetAll)
        api.POST("/brokers", brokerHandler.Connect)
        api.DELETE("/brokers/:id", brokerHandler.Disconnect)
        api.POST("/brokers/:id/sync", brokerHandler.Sync)

        // Chart routes
        api.GET("/charts/config", chartHandler.GetConfig)
        api.PUT("/charts/config", chartHandler.UpdateConfig)

        // Settings routes
        api.GET("/settings", settingsHandler.GetAll)
        api.PUT("/settings", settingsHandler.Update)

        // News routes
        api.GET("/news", newsHandler.GetLatestNews)
    }

    log.Println("Server starting on :8080")
    router.Run(":8080")
}