const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// GET /categories
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { search = '' } = req.query;
    const pool = await getPool();

    let query = `
      SELECT id, name, description, created_at, updated_at
      FROM categories
    `;

    if (search) {
      query += `
        WHERE name COLLATE Latin1_General_CI_AI LIKE @search
           OR description COLLATE Latin1_General_CI_AI LIKE @search
      `;
    }

    query += ' ORDER BY name COLLATE Latin1_General_CI_AI';

    const request = pool.request();
    if (search) {
      request.input('search', sql.NVarChar, `%${search}%`);
    }

    const result = await request.query(query);
    res.json({ data: result.recordset, total: result.recordset.length });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /categories
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, description } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Category name is required' });
    }

    const pool = await getPool();

    // Check duplicate
    const existing = await pool.request()
      .input('name', sql.NVarChar, name)
      .query('SELECT id FROM categories WHERE name = @name');

    if (existing.recordset.length > 0) {
      return res.status(409).json({ error: 'Category name already exists' });
    }

    const result = await pool.request()
      .input('name', sql.NVarChar, name)
      .input('description', sql.NVarChar, description || null)
      .query(`
        INSERT INTO categories (name, description, created_at, updated_at)
        OUTPUT INSERTED.*
        VALUES (@name, @description, GETDATE(), GETDATE())
      `);

    res.status(201).json({ data: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /categories/:id
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Category name is required' });
    }

    const pool = await getPool();

    // Check exists
    const existing = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT id FROM categories WHERE id = @id');

    if (existing.recordset.length === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('description', sql.NVarChar, description || null)
      .query(`
        UPDATE categories
        SET name = @name, description = @description, updated_at = GETDATE()
        OUTPUT INSERTED.*
        WHERE id = @id
      `);

    res.json({ data: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /categories/:id
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await getPool();

    const existing = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT id FROM categories WHERE id = @id');

    if (existing.recordset.length === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    // Check if used by products
    const products = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT COUNT(*) as count FROM products WHERE category_id = @id');

    if (products.recordset[0].count > 0) {
      return res.status(409).json({ error: 'Cannot delete category with existing products' });
    }

    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM categories WHERE id = @id');

    res.json({ message: 'Category deleted successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
