#backend go
cd backend
go mod download
go mod tidy
go run main.go



#frontend flutter
cd frontend
flutter pub get
flutter run -d windows  # For Windows
# or
flutter run -d macos    # For macOS
# or
flutter run -d linux    # For Linux



#build for production
# Build Windows executable
flutter build windows --release

# Build macOS app
flutter build macos --release

# Build Linux app
flutter build linux --release


