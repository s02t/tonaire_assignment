const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { getPool, sql } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// Multer storage config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads/images');
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const productCode = req.body.product_code || Date.now().toString();
    const ext = path.extname(file.originalname);
    cb(null, `${productCode}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp/;
    if (allowed.test(path.extname(file.originalname).toLowerCase())) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

// GET /products
router.get('/', authenticateToken, async (req, res) => {
  try {
    const {
      search = '',
      category_id = '',
      sort_by = 'name',
      sort_order = 'ASC',
      page = 1,
      limit = 20,
      min_price = '',
      max_price = '',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const validSortBy = ['name', 'price', 'created_at'].includes(sort_by) ? sort_by : 'name';
    const validOrder = ['ASC', 'DESC'].includes(sort_order.toUpperCase()) ? sort_order.toUpperCase() : 'ASC';

    const pool = await getPool();
    const request = pool.request();

    let whereClause = 'WHERE 1=1';

    if (search) {
      whereClause += ` AND (p.name COLLATE Latin1_General_CI_AI LIKE @search
                          OR p.description COLLATE Latin1_General_CI_AI LIKE @search
                          OR c.name COLLATE Latin1_General_CI_AI LIKE @search)`;
      request.input('search', sql.NVarChar, `%${search}%`);
    }

    if (category_id) {
      whereClause += ' AND p.category_id = @category_id';
      request.input('category_id', sql.Int, parseInt(category_id));
    }

    if (min_price) {
      whereClause += ' AND p.price >= @min_price';
      request.input('min_price', sql.Decimal(10, 2), parseFloat(min_price));
    }

    if (max_price) {
      whereClause += ' AND p.price <= @max_price';
      request.input('max_price', sql.Decimal(10, 2), parseFloat(max_price));
    }

    request.input('limit', sql.Int, parseInt(limit));
    request.input('offset', sql.Int, offset);

    const countResult = await pool.request()
      .input('search', sql.NVarChar, search ? `%${search}%` : '%')
      .query(`
        SELECT COUNT(*) as total
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        ${whereClause.replace('@category_id', category_id || '0').replace('@min_price', min_price || '0').replace('@max_price', max_price || '999999999')}
      `);

    // Re-add inputs for main query
    const mainRequest = pool.request();
    if (search) mainRequest.input('search', sql.NVarChar, `%${search}%`);
    if (category_id) mainRequest.input('category_id', sql.Int, parseInt(category_id));
    if (min_price) mainRequest.input('min_price', sql.Decimal(10, 2), parseFloat(min_price));
    if (max_price) mainRequest.input('max_price', sql.Decimal(10, 2), parseFloat(max_price));
    mainRequest.input('limit', sql.Int, parseInt(limit));
    mainRequest.input('offset', sql.Int, offset);

    const result = await mainRequest.query(`
      SELECT p.id, p.product_code, p.name, p.description, p.price, p.image_url,
             p.category_id, c.name as category_name,
             p.created_at, p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ${whereClause}
      ORDER BY p.${validSortBy} COLLATE Latin1_General_CI_AI ${validOrder}
      OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `);

    const total = countResult.recordset[0]?.total || 0;

    res.json({
      data: result.recordset,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        total_pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /products
router.post('/', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    const { name, description, category_id, price, product_code } = req.body;

    if (!name || !category_id || price === undefined) {
      return res.status(400).json({ error: 'Name, category_id, and price are required' });
    }

    const pool = await getPool();

    // Validate category exists
    const cat = await pool.request()
      .input('id', sql.Int, category_id)
      .query('SELECT id FROM categories WHERE id = @id');

    if (cat.recordset.length === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    const code = product_code || `PRD-${Date.now()}`;
    let image_url = null;

    if (req.file) {
      image_url = `/uploads/images/${req.file.filename}`;
    }

    const result = await pool.request()
      .input('product_code', sql.NVarChar, code)
      .input('name', sql.NVarChar, name)
      .input('description', sql.NVarChar, description || null)
      .input('category_id', sql.Int, parseInt(category_id))
      .input('price', sql.Decimal(10, 2), parseFloat(price))
      .input('image_url', sql.NVarChar, image_url)
      .query(`
        INSERT INTO products (product_code, name, description, category_id, price, image_url, created_at, updated_at)
        OUTPUT INSERTED.*
        VALUES (@product_code, @name, @description, @category_id, @price, @image_url, GETDATE(), GETDATE())
      `);

    res.status(201).json({ data: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /products/:id
router.put('/:id', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, category_id, price } = req.body;

    if (!name || price === undefined) {
      return res.status(400).json({ error: 'Name and price are required' });
    }

    const pool = await getPool();

    const existing = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM products WHERE id = @id');

    if (existing.recordset.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    let image_url = existing.recordset[0].image_url;
    if (req.file) {
      image_url = `/uploads/images/${req.file.filename}`;
    }

    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('description', sql.NVarChar, description || null)
      .input('category_id', sql.Int, parseInt(category_id))
      .input('price', sql.Decimal(10, 2), parseFloat(price))
      .input('image_url', sql.NVarChar, image_url)
      .query(`
        UPDATE products
        SET name = @name, description = @description, category_id = @category_id,
            price = @price, image_url = @image_url, updated_at = GETDATE()
        OUTPUT INSERTED.*
        WHERE id = @id
      `);

    res.json({ data: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /products/:id
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await getPool();

    const existing = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM products WHERE id = @id');

    if (existing.recordset.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM products WHERE id = @id');

    res.json({ message: 'Product deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
