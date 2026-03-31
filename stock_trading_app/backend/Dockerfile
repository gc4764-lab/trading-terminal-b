# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o stock-trading-backend main.go

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates sqlite

WORKDIR /root/

COPY --from=builder /app/stock-trading-backend .
COPY --from=builder /app/trading.db* ./

EXPOSE 8080

CMD ["./stock-trading-backend"]