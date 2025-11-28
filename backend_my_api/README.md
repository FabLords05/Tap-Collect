# backend_my_api

Grove Rewards API built with Dart Shelf + MongoDB.

## Quick Start

### With Docker Compose (Recommended)

```powershell
cd backend_my_api
docker compose up --build
```

Server will run on `http://localhost:8080` and MongoDB on port `27017`.

### Local Development

1. **Install Dart SDK** (if not already installed)
2. **Install dependencies**:
   ```powershell
   dart pub get
   ```
3. **Ensure MongoDB is running** locally (or adjust `MONGO_URI` in `.env` or env vars)
4. **Run the server**:
   ```powershell
   dart run bin/server.dart
   ```

## Endpoints

### Health Check
```powershell
curl http://localhost:8080/health
```

### Authentication
**Register:**
```powershell
curl -X POST http://localhost:8080/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "email": "user@example.com",
    "name": "John Doe",
    "avatar": "https://example.com/avatar.jpg"
  }'
```

**Login:**
```powershell
curl -X POST http://localhost:8080/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email": "user@example.com"}'
```

### Businesses
**List:**
```powershell
curl http://localhost:8080/businesses
```

**Create:**
```powershell
curl -X POST http://localhost:8080/businesses `
  -H "Content-Type: application/json" `
  -d '{
    "name": "Coffee Shop",
    "description": "Best coffee in town",
    "address": "123 Main St",
    "phone": "555-1234",
    "email": "coffee@example.com",
    "points_per_dollar": 10
  }'
```

**Get:**
```powershell
curl http://localhost:8080/businesses/{business_id}
```

### Merchants
**Create:**
```powershell
curl -X POST http://localhost:8080/merchants `
  -H "Content-Type: application/json" `
  -d '{
    "email": "merchant@example.com",
    "name": "Manager Name",
    "business_id": "{business_id}"
  }'
```

**Get by Business:**
```powershell
curl http://localhost:8080/merchants/business/{business_id}
```

### Rewards
**List for Business:**
```powershell
curl http://localhost:8080/businesses/{business_id}/rewards
```

**Create:**
```powershell
curl -X POST http://localhost:8080/rewards `
  -H "Content-Type: application/json" `
  -d '{
    "business_id": "{business_id}",
    "title": "Free Coffee",
    "description": "Get a free coffee",
    "points_cost": 100,
    "image_url": "https://example.com/coffee.jpg",
    "is_active": true
  }'
```

### Vouchers
**List All:**
```powershell
curl http://localhost:8080/vouchers
```

**List by User:**
```powershell
curl http://localhost:8080/users/{user_id}/vouchers
```

**Create:**
```powershell
curl -X POST http://localhost:8080/vouchers `
  -H "Content-Type: application/json" `
  -d '{
    "user_id": "{user_id}",
    "reward_id": "{reward_id}",
    "code": "VOUCHER001",
    "status": "active",
    "expires_at": "2025-12-31T23:59:59Z"
  }'
```

**Redeem (Update Status):**
```powershell
curl -X PATCH http://localhost:8080/vouchers/{voucher_id} `
  -H "Content-Type: application/json" `
  -d '{
    "status": "redeemed",
    "redeemed_at": "2025-11-13T10:30:00Z"
  }'
```

**Delete:**
```powershell
curl -X DELETE http://localhost:8080/vouchers/{voucher_id}
```

### Transactions
**List by User:**
```powershell
curl http://localhost:8080/users/{user_id}/transactions
```

**Create:**
```powershell
curl -X POST http://localhost:8080/transactions `
  -H "Content-Type: application/json" `
  -d '{
    "user_id": "{user_id}",
    "business_id": "{business_id}",
    "type": "earn",
    "points": 50,
    "description": "Coffee purchase",
    "reward_id": "{reward_id}"
  }'
```

## Database Connection

### MongoDB Requirements
- **URI Format**: `mongodb://[user:password@]host:port/database`
- **Docker Compose**: Uses service hostname `mongodb`
- **Local**: Use `mongodb://127.0.0.1:27017/my_api_db` (default)
- **Atlas Cloud**: Include connection string with credentials and TLS options

### Environment Variables
Set via `.env` file or system environment:
```
MONGO_URI=mongodb://mongodb:27017/my_api_db
PORT=8080
```

## Next Steps

### Frontend Integration
1. **Update Flutter Services** - Connect to backend endpoints in:
   - `lib/services/auth_service.dart` → `/auth/register`, `/auth/login`
   - `lib/services/business_service.dart` → `/businesses`, `/businesses/<id>/rewards`
   - `lib/services/merchant_auth_service.dart` → `/auth/login` (merchant variant)
   - `lib/services/points_service.dart` → `/transactions`, `/users/<id>/transactions`
   - `lib/services/rewards_service.dart` → `/rewards`
   - `lib/services/transaction_service.dart` → `/transactions`
   - `lib/services/voucher_service.dart` → `/vouchers`, `/users/<id>/vouchers`

2. **Update Base URL** in each service to point to your API:
   ```dart
   const String baseUrl = 'http://localhost:8080'; // Local dev
   const String baseUrl = 'https://api.example.com'; // Production
   ```

3. **Replace Mock Data** - Remove any mock implementations and use real API calls

### Production Deployment
1. **MongoDB Atlas** - Provision a cloud database and update `MONGO_URI`
2. **Docker** - Push image to registry (Docker Hub, GCR, ECR)
3. **Hosting** - Deploy to Cloud Run, App Engine, ECS, or your preferred platform
4. **Authentication** - Add JWT tokens or OAuth for production security
5. **HTTPS** - Configure SSL/TLS certificates for secure connections

### Additional Features
- Add request validation and sanitization
- Implement rate limiting and authentication middleware
- Add comprehensive error logging and monitoring
- Add tests (unit and integration)
- Document API with OpenAPI/Swagger

