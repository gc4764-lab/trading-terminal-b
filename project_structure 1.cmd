stock-trading-app/
├── backend/
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   ├── Dockerfile
│   ├── handlers/
│   │   ├── auth.go
│   │   ├── watchlist.go
│   │   ├── alert.go
│   │   ├── order.go
│   │   ├── position.go
│   │   ├── broker.go
│   │   ├── chart.go
│   │   ├── settings.go
│   │   └── news.go
│   ├── models/
│   │   └── models.go
│   ├── websocket/
│   │   └── hub.go
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   └── 002_add_indices.sql
│   └── config/
│       └── config.go
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   ├── watchlist.dart
│   │   │   ├── alert.dart
│   │   │   ├── order.dart
│   │   │   ├── position.dart
│   │   │   ├── settings.dart
│   │   │   ├── chart_config.dart
│   │   │   ├── broker_config.dart
│   │   │   └── news.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── watchlist_screen.dart
│   │   │   ├── chart_grid_screen.dart
│   │   │   ├── risk_management_screen.dart
│   │   │   ├── orders_screen.dart
│   │   │   ├── positions_screen.dart
│   │   │   ├── alerts_screen.dart
│   │   │   ├── news_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── multi_monitor_screen.dart
│   │   ├── widgets/
│   │   │   ├── watchlist_item.dart
│   │   │   ├── alert_item.dart
│   │   │   ├── order_item.dart
│   │   │   ├── position_item.dart
│   │   │   ├── chart_config_panel.dart
│   │   │   ├── detachable_chart.dart
│   │   │   ├── risk_gauge.dart
│   │   │   └── customizable_dashboard.dart
│   │   ├── providers/
│   │   │   ├── watchlist_provider.dart
│   │   │   ├── alerts_provider.dart
│   │   │   ├── orders_provider.dart
│   │   │   ├── positions_provider.dart
│   │   │   ├── risk_provider.dart
│   │   │   ├── chart_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   ├── news_provider.dart
│   │   │   └── broker_provider.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── market_data_service.dart
│   │   │   ├── indicator_service.dart
│   │   │   ├── ai_service.dart
│   │   │   ├── order_service.dart
│   │   │   ├── export_service.dart
│   │   │   └── analytics_service.dart
│   │   ├── security/
│   │   │   ├── encryption_service.dart
│   │   │   └── biometric_auth.dart
│   │   ├── brokers/
│   │   │   ├── broker_interface.dart
│   │   │   ├── zerodha_broker.dart
│   │   │   ├── upstox_broker.dart
│   │   │   ├── angel_broker.dart
│   │   │   └── broker_factory.dart
│   │   └── utils/
│   │       ├── theme.dart
│   │       ├── logger.dart
│   │       ├── formatters.dart
│   │       ├── validators.dart
│   │       ├── cache_manager.dart
│   │       ├── performance_monitor.dart
│   │       ├── error_handler.dart
│   │       ├── error_boundary.dart
│   │       └── memory_optimizer.dart
│   ├── assets/
│   │   ├── icons/
│   │   ├── fonts/
│   │   └── models/
│   ├── test/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── widget_test.dart
│   ├── pubspec.yaml
│   └── Dockerfile
├── scripts/
│   ├── deploy.sh
│   ├── monitoring.sh
│   └── verify_deployment.sh
├── docs/
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── USER_GUIDE.md
├── .env.example
├── .gitignore
├── docker-compose.yml
├── docker-compose.prod.yml
├── nginx.conf
├── prometheus.yml
├── README.md
└── 