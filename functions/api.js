/**
 * MinerPrices Cloudflare Worker
 * Handles image uploads, API routes, and static file serving
 */

import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://huzfnrgfcxlwvmrkoyge.supabase.co'
const SUPABASE_KEY = 'sb_publishable_s5ocl3sDwpefFYuw3V-JEQ_FQzXGTHZ'

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

/**
 * Main Worker fetch handler
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)
    const path = url.pathname

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    }

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response('OK', { headers: corsHeaders })
    }

    try {
      // Only handle API Routes - static files are served by Pages
      if (path.startsWith('/api/')) {
        return handleAPI(request, path, corsHeaders)
      }

      // Any non-API route should fall back to Cloudflare Pages static file serving
      // Return 404 only if explicitly needed
      return new Response('Not Found', { status: 404, headers: corsHeaders })
    } catch (error) {
      console.error('Worker error:', error)
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
  }
}

/**
 * Handle API routes
 */
async function handleAPI(request, path, corsHeaders) {
  const method = request.method
  const url = new URL(request.url)

  // GET /api/miner-images/:minerId
  if (path.match(/^\/api\/miner-images\/\d+$/) && method === 'GET') {
    const minerId = path.split('/').pop()
    return getMinerImages(minerId, corsHeaders)
  }

  // POST /api/miner-images - Add image via database
  if (path === '/api/miner-images' && method === 'POST') {
    const data = await request.json()
    return addMinerImage(data, corsHeaders)
  }

  // DELETE /api/miner-images/:imageId
  if (path.match(/^\/api\/miner-images\/\d+$/) && method === 'DELETE') {
    const imageId = path.split('/').pop()
    return deleteMinerImage(imageId, corsHeaders)
  }

  // Health check
  if (path === '/api/health' && method === 'GET') {
    return new Response(
      JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  return new Response(
    JSON.stringify({ error: 'Route not found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

/**
 * Get images for a specific miner
 */
async function getMinerImages(minerId, corsHeaders) {
  try {
    const { data, error } = await supabase
      .from('miner_images')
      .select('*')
      .eq('miner_id', parseInt(minerId))
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: false })

    if (error) throw error

    return new Response(
      JSON.stringify({
        success: true,
        minerId: parseInt(minerId),
        images: data || [],
        count: (data || []).length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error fetching images:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

/**
 * Add a new image to the database
 */
async function addMinerImage(data, corsHeaders) {
  try {
    const { minerId, imageUrl, caption, isPrimary } = data

    if (!minerId || !imageUrl) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: minerId, imageUrl' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify miner exists
    const { data: miner, error: minerError } = await supabase
      .from('miners')
      .select('id')
      .eq('id', parseInt(minerId))
      .single()

    if (minerError || !miner) {
      return new Response(
        JSON.stringify({ error: 'Miner not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
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

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Image added successfully',
        image: newImage[0]
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error adding image:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

/**
 * Delete an image
 */
async function deleteMinerImage(imageId, corsHeaders) {
  try {
    const { error } = await supabase
      .from('miner_images')
      .delete()
      .eq('id', parseInt(imageId))

    if (error) throw error

    return new Response(
      JSON.stringify({ success: true, message: 'Image deleted successfully' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error deleting image:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}
