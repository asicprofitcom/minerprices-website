# imgbb Image Integration - Deployment Guide

## Overview
This guide covers deploying the imgbb image upload system for minerprices.com. All images are hosted on imgbb.com (minerprices.imgbb.com) and URLs are stored in the Supabase database.

## Prerequisites

1. **imgbb Account Setup**
   - Sign up at https://imgbb.com
   - Get API key from https://api.imgbb.com
   - Note: You can use the custom domain minerprices.imgbb.com

2. **Supabase Database**
   - Database: postgres (hosted on Supabase)
   - User: max_bot (with appropriate permissions)
   - Service key for server-side operations

3. **Cloudflare Workers**
   - Account with Workers enabled
   - Zone ID for minerprices.com domain
   - Account ID

## Step 1: Update Environment Variables

Add to your `.env` file (or Wrangler secrets):

```bash
IMGBB_API_KEY=your_imgbb_api_key
SUPABASE_URL=https://huzfnrgfcxlwvmrkoyge.supabase.co
SUPABASE_SERVICE_KEY=your_service_key_here
```

## Step 2: Run Database Migration

Execute the migration SQL to add imgbb fields to miner_images table:

```bash
# Via psql
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co \
     -U max_bot \
     -d postgres \
     -f migration-add-imgbb-fields.sql

# Or via Supabase SQL editor
# Copy contents of migration-add-imgbb-fields.sql and paste into Supabase SQL editor
```

## Step 3: Deploy Cloudflare Worker

Update `wrangler.toml`:

```toml
[env.production]
name = "minerprices-website"
route = "minerprices.com/*"
zone_id = "YOUR_ZONE_ID"

[env.production.vars]
IMGBB_API_KEY = "your_imgbb_api_key"
SUPABASE_URL = "https://huzfnrgfcxlwvmrkoyge.supabase.co"
SUPABASE_SERVICE_KEY = "your_service_key"
```

Deploy:

```bash
npm install @supabase/supabase-js
wrangler deploy --env production
```

## Step 4: Verify API Endpoints

Test the endpoints:

```bash
# Test miner images retrieval
curl https://minerprices.com/api/miner-images/1

# Expected response:
{
  "success": true,
  "images": [
    {
      "id": 1,
      "miner_id": 1,
      "image_url": "https://ibb.co/...",
      "delete_url": "...",
      "is_primary": true,
      "caption": "..."
    }
  ]
}
```

## Step 5: Upload Images

### Via Web UI (Admin Panel)
1. Go to `/admin.html`
2. Find miner
3. Upload images (they'll automatically go to imgbb)
4. Mark one as primary

### Via API
```bash
curl -X POST https://minerprices.com/api/upload-miner-image \
  -F "image=@miner-photo.jpg" \
  -F "miner_id=1" \
  -F "caption=Antminer S19 Pro" \
  -F "is_primary=true"
```

### Via Database Direct
```sql
INSERT INTO miner_images (miner_id, image_url, delete_url, caption, is_primary)
VALUES (
  1,
  'https://ibb.co/abc123',
  'https://ibb.co/delete/abc123',
  'Miner Photo',
  true
);
```

## Step 6: Update Miner Display

The miner.html page now:
- Fetches images from database via `/api/miner-images/:minerId`
- Displays primary image in hero section
- Shows image gallery if multiple images exist
- Falls back to placeholder SVG if no images

## Database Schema

### miner_images Table
```sql
id                BIGSERIAL PRIMARY KEY
miner_id          BIGINT (FK -> miners)
image_url         TEXT (imgbb URL)
delete_url        TEXT (imgbb delete endpoint)
caption           VARCHAR(255)
is_primary        BOOLEAN (default: false)
display_order     INTEGER (for sorting)
image_source      VARCHAR(50) (default: 'imgbb')
imgbb_id          VARCHAR(100) (for reference)
uploaded_by       VARCHAR(255)
created_at        TIMESTAMP WITH TIME ZONE
```

## File Structure

```
minerprices-website/
├── miner.html                      # Updated with image loading
├── imgbb-upload-handler.js         # Upload/retrieve/delete handlers
├── wrangler-routes.js              # Worker route definitions
├── wrangler.toml                   # Cloudflare config
├── migration-add-imgbb-fields.sql  # DB schema update
└── IMGBB_DEPLOYMENT.md             # This file
```

## API Reference

### GET /api/miner-images/:minerId
Fetch all images for a miner
```javascript
const response = await fetch(`/api/miner-images/1`);
const { images } = await response.json();
```

### POST /api/upload-miner-image
Upload a new image
```javascript
const formData = new FormData();
formData.append('image', fileInput.files[0]);
formData.append('miner_id', '1');
formData.append('caption', 'Optional caption');
formData.append('is_primary', 'true');

const response = await fetch('/api/upload-miner-image', {
  method: 'POST',
  body: formData
});
const { image, imgbb_url } = await response.json();
```

### DELETE /api/miner-images/:imageId
Delete an image
```javascript
await fetch(`/api/miner-images/123`, { method: 'DELETE' });
```

### PATCH /api/miner-images/:imageId
Update image metadata
```javascript
await fetch(`/api/miner-images/123`, {
  method: 'PATCH',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    caption: 'New caption',
    is_primary: true,
    display_order: 1
  })
});
```

## Troubleshooting

### Images not appearing
1. Check `/api/miner-images/:minerId` returns data
2. Verify imgbb URLs are accessible
3. Check browser console for CORS errors
4. Verify Supabase connection

### Upload fails
1. Verify IMGBB_API_KEY is set
2. Check file size (imgbb max is ~32MB)
3. Verify miner_id exists in database
4. Check imgbb API status

### CORS issues
- All API endpoints have CORS headers set to allow cross-origin requests
- If issues persist, check Cloudflare Worker CORS configuration

## Performance Notes

- Images are served from imgbb's CDN (fast, global)
- Metadata is cached in Supabase (very fast)
- Primary image is fetched first for hero section
- Gallery loads on demand
- Consider caching image responses with Cloudflare Cache API

## Rollback Plan

If issues occur:
1. Keep backup of original database
2. Keep delete URLs from imgbb responses
3. Can revert to placeholder images by reverting miner.html
4. Images in imgbb can be deleted via delete_url if needed

## Cost Analysis

- **imgbb**: Free tier for up to 30 uploads/month, then $0.25/1000 images
- **Supabase**: Included in hosting plan
- **Cloudflare Workers**: Included in zone (up to 100k requests/day free)
- **CDN**: Free imgbb CDN for served images

Total monthly cost: Minimal to none for typical usage

## Next Steps

1. Deploy migration to Supabase
2. Deploy Cloudflare Worker
3. Upload test images
4. Verify miner.html displays images
5. Test on production domain

---

**Last Updated:** 2026-05-07
