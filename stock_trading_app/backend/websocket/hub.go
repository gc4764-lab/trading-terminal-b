package websocket

import (
    "encoding/json"
    "log"
    "net/http"
    "sync"
    "github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        return true
    },
}

type Client struct {
    hub  *Hub
    conn *websocket.Conn
    send chan []byte
}

type Hub struct {
    clients    map[*Client]bool
    broadcast  chan []byte
    register   chan *Client
    unregister chan *Client
    mu         sync.RWMutex
}

func NewHub() *Hub {
    return &Hub{
        clients:    make(map[*Client]bool),
        broadcast:  make(chan []byte),
        register:   make(chan *Client),
        unregister: make(chan *Client),
    }
}

func (h *Hub) Run() {
    for {
        select {
        case client := <-h.register:
            h.mu.Lock()
            h.clients[client] = true
            h.mu.Unlock()
            log.Println("Client registered")
            
        case client := <-h.unregister:
            h.mu.Lock()
            if _, ok := h.clients[client]; ok {
                delete(h.clients, client)
                close(client.send)
            }
            h.mu.Unlock()
            log.Println("Client unregistered")
            
        case message := <-h.broadcast:
            h.mu.RLock()
            for client := range h.clients {
                select {
                case client.send <- message:
                default:
                    close(client.send)
                    delete(h.clients, client)
                }
            }
            h.mu.RUnlock()
        }
    }
}

func (h *Hub) SendToClient(clientID string, data interface{}) {
    message, err := json.Marshal(data)
    if err != nil {
        return
    }
    
    h.mu.RLock()
    for client := range h.clients {
        // Filter by client ID if needed
        select {
        case client.send <- message:
        default:
        }
    }
    h.mu.RUnlock()
}

func (h *Hub) BroadcastMarketData(symbol string, price float64, volume int64) {
    data := map[string]interface{}{
        "type":   "market_data",
        "symbol": symbol,
        "price":  price,
        "volume": volume,
        "time":   time.Now(),
    }
    message, _ := json.Marshal(data)
    h.broadcast <- message
}

func ServeWebSocket(hub *Hub, w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("Error upgrading connection:", err)
        return
    }
    
    client := &Client{
        hub:  hub,
        conn: conn,
        send: make(chan []byte, 256),
    }
    client.hub.register <- client
    
    go client.writePump()
    go client.readPump()
}

func (c *Client) writePump() {
    defer func() {
        c.conn.Close()
    }()
    
    for {
        select {
        case message, ok := <-c.send:
            if !ok {
                c.conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            
            c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
                return
            }
        }
    }
}

func (c *Client) readPump() {
    defer func() {
        c.hub.unregister <- c
        c.conn.Close()
    }()
    
    c.conn.SetReadLimit(512)
    c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
    c.conn.SetPongHandler(func(string) error {
        c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
        return nil
    })
    
    for {
        _, message, err := c.conn.ReadMessage()
        if err != nil {
            break
        }
        
        // Process incoming message
        var data map[string]interface{}
        if err := json.Unmarshal(message, &data); err != nil {
            continue
        }
        
        // Handle subscription requests
        if action, ok := data["action"].(string); ok {
            switch action {
            case "subscribe":
                if symbol, ok := data["symbol"].(string); ok {
                    // Subscribe to symbol updates
                    go subscribeToSymbol(symbol, c)
                }
            case "unsubscribe":
                if symbol, ok := data["symbol"].(string); ok {
                    // Unsubscribe from symbol updates
                    unsubscribeFromSymbol(symbol, c)
                }
            }
        }
    }
}

func subscribeToSymbol(symbol string, c *Client) {
    // Subscribe to market data for symbol
    ticker := time.NewTicker(1 * time.Second)
    defer ticker.Stop()
    
    for range ticker.C {
        // Check if client is still connected
        select {
        case <-c.send:
            // Send price updates
            price := getCurrentPrice(symbol)
            data := map[string]interface{}{
                "type":   "price_update",
                "symbol": symbol,
                "price":  price,
                "time":   time.Now(),
            }
            message, _ := json.Marshal(data)
            c.send <- message
        default:
            return
        }
    }
}

func unsubscribeFromSymbol(symbol string, c *Client) {
    // Stop sending updates for symbol
    // Implementation depends on subscription management
}