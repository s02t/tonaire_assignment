-- =============================================
-- Database Schema for Product & Category Management
-- SQL Server
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'product_db')
BEGIN
    CREATE DATABASE product_db;
END
GO

USE product_db;
GO

-- =============================================
-- Users Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE users (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        username    NVARCHAR(100) NOT NULL,
        email       NVARCHAR(255) NOT NULL UNIQUE,
        password    NVARCHAR(255) NOT NULL,
        created_at  DATETIME DEFAULT GETDATE(),
        updated_at  DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- Categories Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'categories')
BEGIN
    CREATE TABLE categories (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        name        NVARCHAR(255) NOT NULL,
        description NVARCHAR(MAX),
        created_at  DATETIME DEFAULT GETDATE(),
        updated_at  DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- Products Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'products')
BEGIN
    CREATE TABLE products (
        id           INT IDENTITY(1,1) PRIMARY KEY,
        product_code NVARCHAR(50) NOT NULL UNIQUE,
        name         NVARCHAR(255) NOT NULL,
        description  NVARCHAR(MAX),
        category_id  INT REFERENCES categories(id),
        price        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
        image_url    NVARCHAR(500),
        created_at   DATETIME DEFAULT GETDATE(),
        updated_at   DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- Indexes for search performance
-- =============================================
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
GO

-- =============================================
-- Sample Data: Categories (English + Khmer)
-- =============================================
INSERT INTO categories (name, description) VALUES
(N'Electronics / អេឡិចត្រូនិក', N'Electronic devices and gadgets'),
(N'Clothing / សម្លៀកបំពាក់', N'Clothes and fashion items'),
(N'Food & Beverage / អាហារ និង ភេសជ្ជៈ', N'Food and drink products'),
(N'Books / សៀវភៅ', N'Books and educational materials'),
(N'Sports / កីឡា', N'Sports equipment and accessories');
GO

-- =============================================
-- Sample Data: Products (English + Khmer)
-- =============================================
INSERT INTO products (product_code, name, description, category_id, price, image_url) VALUES
(N'PRD-001', N'Smartphone / ស្មាតហ្វូន Samsung', N'Latest Android smartphone', 1, 699.99, N'/uploads/images/PRD-001.jpg'),
(N'PRD-002', N'Laptop / កុំព្យូទ័រយួរដៃ', N'High performance laptop', 1, 999.99, N'/uploads/images/PRD-002.jpg'),
(N'PRD-003', N'T-Shirt / អាវយឺត', N'Cotton casual t-shirt', 2, 19.99, N'/uploads/images/PRD-003.jpg'),
(N'PRD-004', N'Khmer Rice / បាយខ្មែរ', N'Premium jasmine rice from Cambodia', 3, 5.99, N'/uploads/images/PRD-004.jpg'),
(N'PRD-005', N'Khmer History Book / សៀវភៅប្រវត្តិសាស្ត្រខ្មែរ', N'Cambodian history textbook', 4, 24.99, N'/uploads/images/PRD-005.jpg'),
(N'PRD-006', N'Football / បាល់ទាត់', N'Professional football', 5, 39.99, N'/uploads/images/PRD-006.jpg'),
(N'PRD-007', N'Headphones / កាស', N'Wireless noise-cancelling headphones', 1, 299.99, N'/uploads/images/PRD-007.jpg'),
(N'PRD-008', N'Jeans / ខោចិន', N'Classic blue denim jeans', 2, 49.99, N'/uploads/images/PRD-008.jpg'),
(N'PRD-009', N'Coffee / កាហ្វេ', N'Cambodian dark roast coffee', 3, 12.99, N'/uploads/images/PRD-009.jpg'),
(N'PRD-010', N'Programming Book / សៀវភៅសរសេរកម្មវិធី', N'Learn Flutter and Node.js', 4, 34.99, N'/uploads/images/PRD-010.jpg');
GO

-- =============================================
-- Sample admin user (password: Admin@1234)
-- =============================================
INSERT INTO users (username, email, password) VALUES
(N'admin', N'admin@example.com', N'$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PJ/V.e');
GO
