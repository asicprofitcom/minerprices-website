/**
 * IMGBB Image Upload Handler
 * Cloudflare Worker that proxies image uploads to imgbb.com
 * Stores returned URLs in Supabase database
 */

import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabase = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_KEY
);

/**
 * Upload image to imgbb and store URL in database
 * POST /api/upload-miner-image
 * Body: FormData with 'image' file and 'miner_id' field
 */
export async function handleImageUpload(request, env) {
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  try {
    // Parse multipart form data
    const formData = await request.formData();
    const imageFile = formData.get('image');
    const minerId = formData.get('miner_id');
    const caption = formData.get('caption') || '';
    const isPrimary = formData.get('is_primary') === 'true';

    if (!imageFile || !minerId) {
      return new Response(
        JSON.stringify({ error: 'Missing image file or miner_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Convert file to base64
    const buffer = await imageFile.arrayBuffer();
    const base64 = btoa(String.fromCharCode(...new Uint8Array(buffer)));

    // Upload to imgbb
    const imgbbFormData = new FormData();
    imgbbFormData.append('image', base64);
    imgbbFormData.append('key', env.IMGBB_API_KEY);
    if (caption) imgbbFormData.append('name', caption);

    const imgbbResponse = await fetch('https://api.imgbb.com/1/upload', {
      method: 'POST',
      body: imgbbFormData
    });

    if (!imgbbResponse.ok) {
      throw new Error(`imgbb API error: ${imgbbResponse.statusText}`);
    }

    const imgbbData = await imgbbResponse.json();

    if (!imgbbData.success) {
      throw new Error(imgbbData.error?.message || 'imgbb upload failed');
    }

    const imageUrl = imgbbData.data.url;
    const deleteUrl = imgbbData.data.delete_url;

    // Store in Supabase
    const { data, error } = await supabase
      .from('miner_images')
      .insert({
        miner_id: parseInt(minerId),
        image_url: imageUrl,
        delete_url: deleteUrl,
        caption: caption || null,
        is_primary: isPrimary
      })
      .select();

    if (error) {
      console.error('Supabase insert error:', error);
      throw error;
    }

    return new Response(
      JSON.stringify({
        success: true,
        image: data[0],
        imgbb_url: imageUrl,
        delete_url: deleteUrl
      }),
      {
        status: 201,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  } catch (error) {
    console.error('Upload error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

/**
 * Fetch miner images from database
 * GET /api/miner-images/:minerId
 */
export async function getMinerImages(minerId, env) {
  try {
    const { data, error } = await supabase
      .from('miner_images')
      .select('*')
      .eq('miner_id', minerId)
      .order('is_primary', { ascending: false })
      .order('display_order');

    if (error) throw error;

    return new Response(JSON.stringify({ success: true, images: data }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Fetch error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Delete image from database and imgbb
 * DELETE /api/miner-images/:imageId
 */
export async function deleteImage(imageId, env) {
  try {
    // Get image record to retrieve delete_url
    const { data: imageData, error: fetchError } = await supabase
      .from('miner_images')
      .select('*')
      .eq('id', imageId)
      .single();

    if (fetchError || !imageData) {
      return new Response(
        JSON.stringify({ error: 'Image not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Delete from imgbb if delete_url exists
    if (imageData.delete_url) {
      try {
        await fetch(imageData.delete_url, { method: 'GET' });
      } catch (imgbbError) {
        console.warn('imgbb deletion failed:', imgbbError);
        // Continue anyway, image record will still be deleted from DB
      }
    }

    // Delete from database
    const { error: deleteError } = await supabase
      .from('miner_images')
      .delete()
      .eq('id', imageId);

    if (deleteError) throw deleteError;

    return new Response(
      JSON.stringify({ success: true, message: 'Image deleted' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Delete error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Update image metadata
 * PATCH /api/miner-images/:imageId
 */
export async function updateImage(imageId, request, env) {
  try {
    const body = await request.json();
    const { caption, is_primary, display_order } = body;

    const updateData = {};
    if (caption !== undefined) updateData.caption = caption;
    if (is_primary !== undefined) updateData.is_primary = is_primary;
    if (display_order !== undefined) updateData.display_order = display_order;

    const { data, error } = await supabase
      .from('miner_images')
      .update(updateData)
      .eq('id', imageId)
      .select();

    if (error) throw error;

    return new Response(JSON.stringify({ success: true, image: data[0] }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Update error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
