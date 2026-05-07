/**
 * Cloudflare Worker Routes Configuration
 * Handles API endpoints for image uploads and retrieval
 */

import { handleImageUpload, getMinerImages, deleteImage, updateImage } from './imgbb-upload-handler.js';

/**
 * Main Worker request handler
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Image upload: POST /api/upload-miner-image
    if (path.startsWith('/api/upload-miner-image') && request.method === 'POST') {
      const response = await handleImageUpload(request, env);
      response.headers.set('Access-Control-Allow-Origin', '*');
      return response;
    }

    // Get miner images: GET /api/miner-images/:minerId
    if (path.match(/^\/api\/miner-images\/\d+$/) && request.method === 'GET') {
      const minerId = path.split('/').pop();
      const response = await getMinerImages(minerId, env);
      response.headers.set('Access-Control-Allow-Origin', '*');
      return response;
    }

    // Delete image: DELETE /api/miner-images/:imageId
    if (path.match(/^\/api\/miner-images\/\d+$/) && request.method === 'DELETE') {
      const imageId = path.split('/').pop();
      const response = await deleteImage(imageId, env);
      response.headers.set('Access-Control-Allow-Origin', '*');
      return response;
    }

    // Update image: PATCH /api/miner-images/:imageId
    if (path.match(/^\/api\/miner-images\/\d+$/) && request.method === 'PATCH') {
      const imageId = path.split('/').pop();
      const response = await updateImage(imageId, request, env);
      response.headers.set('Access-Control-Allow-Origin', '*');
      return response;
    }

    // Serve static files from the public directory
    return env.ASSETS.fetch(request);
  },
};
