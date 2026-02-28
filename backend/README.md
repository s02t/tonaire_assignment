# Backend — Node.js + SQL Server API

## Stack
- Node.js
- SQL Server (mssql)
- JWT Authentication
- bcryptjs (password hashing)
- Nodemailer (OTP emails)
- Multer (image uploads)

## Setup

### 1. Install dependencies
```bash
cd backend
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your SQL Server credentials and email config
```

### 3. Create database and run schema
```bash
# Open SSMS or sqlcmd and run:
sqlcmd -S localhost -U sa -P YourPassword -i ../sql/schema.sql
```

### 4. Start the server
```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

Server runs at: `http://localhost:3000`

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/signup` | Register new user |
| POST | `/auth/login` | Login, returns JWT |
| POST | `/auth/forgot-password` | Send OTP to email |
| POST | `/auth/verify-otp` | Verify OTP + reset password |

### Categories (requires JWT)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/categories` | Get all categories (supports `?search=`) |
| POST | `/categories` | Create category |
| PUT | `/categories/:id` | Update category |
| DELETE | `/categories/:id` | Delete category |

### Products (requires JWT)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | Get products with pagination/sort/filter |
| POST | `/products` | Create product |
| PUT | `/products/:id` | Update product |
| DELETE | `/products/:id` | Delete product |

#### Product Query Parameters
- `search` — full-text search (English + Khmer)
- `category_id` — filter by category
- `sort_by` — `name` or `price`
- `sort_order` — `ASC` or `DESC`
- `page` — page number (default: 1)
- `limit` — items per page (default: 20)
- `min_price`, `max_price` — price range filter

## Authentication
All `/categories` and `/products` endpoints require:
```
Authorization: Bearer <JWT_TOKEN>
```

## Image Upload
- POST/PUT to `/products` supports `multipart/form-data`
- Images stored in `uploads/images/`
- Served at `http://localhost:3000/uploads/images/<filename>`

## Sample Credentials (from schema.sql)
- Email: `admin@example.com`
- Password: `Admin@1234`
