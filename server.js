/**
 * MinerPrices Server
 * Express server that serves static files and API routes
 */

const express = require('express')
const path = require('path')
const { createClient } = require('@supabase/supabase-js')

const app = express()
const PORT = process.env.PORT || 3000

// Supabase client
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://huzfnrgfcxlwvmrkoyge.supabase.co'
const SUPABASE_KEY = process.env.SUPABASE_KEY || 'sb_publishable_s5ocl3sDwpefFYuw3V-JEQ_FQzXGTHZ'

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

// Middleware
app.use(express.json())
app.use(express.static(path.join(__dirname, 'public')))

// CORS headers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200)
  }
  
  next()
})

/**
 * API Routes
 */

// GET /api/miner-images/:minerId
app.get('/api/miner-images/:minerId', async (req, res) => {
  try {
    const minerId = parseInt(req.params.minerId)
    
    const { data, error } = await supabase
      .from('miner_images')
      .select('*')
      .eq('miner_id', minerId)
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: false })

    if (error) throw error

    res.json({
      success: true,
      minerId,
      images: data || [],
      count: (data || []).length
    })
  } catch (error) {
    console.error('Error fetching images:', error)
    res.status(400).json({ error: error.message })
  }
})

// POST /api/miner-images
app.post('/api/miner-images', async (req, res) => {
  try {
    const { minerId, imageUrl, caption, isPrimary } = req.body

    if (!minerId || !imageUrl) {
      return res.status(400).json({ 
        error: 'Missing required fields: minerId, imageUrl' 
      })
    }

    // Verify miner exists
    const { data: miner, error: minerError } = await supabase
      .from('miners')
      .select('id')
      .eq('id', parseInt(minerId))
      .single()

    if (minerError || !miner) {
      return res.status(404).json({ error: 'Miner not found' })
    }

    // Insert image
    const { data: newImage, error: insertError } = await supabase
      .from('miner_images')
      .insert({
        miner_id: parseInt(minerId),
        image_url: imageUrl,
        caption: caption || null,
        is_primary: isPrimary === true
      })
      .select()

    if (insertError) throw insertError

    res.json({
      success: true,
      message: 'Image added successfully',
      image: newImage[0]
    })
  } catch (error) {
    console.error('Error adding image:', error)
    res.status(400).json({ error: error.message })
  }
})

// DELETE /api/miner-images/:imageId
app.delete('/api/miner-images/:imageId', async (req, res) => {
  try {
    const imageId = parseInt(req.params.imageId)

    const { error } = await supabase
      .from('miner_images')
      .delete()
      .eq('id', imageId)

    if (error) throw error

    res.json({ 
      success: true, 
      message: 'Image deleted successfully' 
    })
  } catch (error) {
    console.error('Error deleting image:', error)
    res.status(400).json({ error: error.message })
  }
})

// GET /api/health
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString() 
  })
})

// Serve HTML pages for routing
app.get('/images', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'images.html'))
})

app.get('/miner', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'miner.html'))
})

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'))
})

app.get('/seller-dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'seller-dashboard.html'))
})

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' })
})

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err)
  res.status(500).json({ error: err.message })
})

// Start server
app.listen(PORT, () => {
  console.log(`🚀 MinerPrices server running on port ${PORT}`)
})
