package handlers

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

type NewsHandler struct{}

func NewNewsHandler() *NewsHandler {
    return &NewsHandler{}
}

func (h *NewsHandler) GetLatestNews(c *gin.Context) {
    // Example using free API (replace with actual news API)
    url := "https://api.example.com/news?apikey=YOUR_API_KEY&category=markets"
    
    resp, err := http.Get(url)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    defer resp.Body.Close()
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    var newsData struct {
        Articles []struct {
            Title       string    `json:"title"`
            Description string    `json:"description"`
            URL         string    `json:"url"`
            URLToImage  string    `json:"urlToImage"`
            Source      struct {
                Name string `json:"name"`
            } `json:"source"`
            PublishedAt time.Time `json:"publishedAt"`
        } `json:"articles"`
    }
    
    if err := json.Unmarshal(body, &newsData); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    articles := make([]map[string]interface{}, 0)
    for _, article := range newsData.Articles {
        articles = append(articles, map[string]interface{}{
            "title":       article.Title,
            "description": article.Description,
            "url":         article.URL,
            "imageUrl":    article.URLToImage,
            "source":      article.Source.Name,
            "publishedAt": article.PublishedAt,
        })
    }
    
    c.JSON(http.StatusOK, articles)
}