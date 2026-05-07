# Production Deployment Checklist

## Image Upload System - imgbb Integration

### Prerequisites ✅
- [x] imgbb account created: minerprices.imgbb.com
- [ ] IMGBB_API_KEY obtained from https://api.imgbb.com
- [ ] Cloudflare Workers enabled on minerprices.com
- [ ] Supabase max_bot user with proper DB permissions
- [ ] Service key for server-side operations

### Phase 1: Database Preparation
- [ ] **Run migration SQL**
  ```bash
  psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres -f migration-add-imgbb-fields.sql
  ```
  Adds: `delete_url`, `image_source`, `imgbb_id`, `uploaded_by` columns to `miner_images` table

- [ ] **Verify schema**
  ```sql
  \d miner_images
  ```
  Should show all new columns with correct types

### Phase 2: Cloudflare Worker Deployment

- [ ] **Update wrangler.toml** with environment variables:
  ```toml
  [env.production]
  vars = { IMGBB_API_KEY = "YOUR_KEY" }
  secrets = { SUPABASE_SERVICE_KEY = "..." }
  ```

- [ ] **Install dependencies**
  ```bash
  npm install @supabase/supabase-js
  ```

- [ ] **Deploy Worker**
  ```bash
  wrangler deploy --env production
  ```

- [ ] **Test endpoints**
  ```bash
  # Test retrieval
  curl https://minerprices.com/api/miner-images/1
  
  # Should return 200 with images array (empty or populated)
  ```

### Phase 3: Frontend Updates

- [ ] **Verify miner.html changes**
  - Image loading function: `loadMinerImages(minerId)`
  - Falls back to placeholder if no images
  - Displays primary image in hero
  - Shows gallery if multiple images exist

- [ ] **Upload admin interface deployed**
  - Available at `/image-upload-admin.html`
  - Can be linked from admin dashboard
  - Test file upload

### Phase 4: Testing

#### Functional Tests
- [ ] Upload single image to miner
  ```bash
  curl -X POST https://minerprices.com/api/upload-miner-image \
    -F "image=@test.jpg" \
    -F "miner_id=1" \
    -F "caption=Test Image" \
    -F "is_primary=true"
  ```

- [ ] Verify image appears on `/miner.html?id=1`

- [ ] Upload second image, verify gallery shows both

- [ ] Set second image as primary, verify hero updates

- [ ] Delete image via admin panel

- [ ] Verify image deleted from both database and imgbb

#### Regression Tests
- [ ] Miner page loads without errors
- [ ] Fallback placeholder shows if no images
- [ ] Price data still displays correctly
- [ ] Seller cards still render
- [ ] Profitability chart still works
- [ ] Mobile view responsive

#### Performance Tests
- [ ] Image load time < 2s (imgbb CDN)
- [ ] API response time < 500ms
- [ ] No console errors in browser DevTools

### Phase 5: Documentation

- [ ] **Update .env.example** with IMGBB_API_KEY
  ```bash
  IMGBB_API_KEY=your_imgbb_api_key_here
  ```

- [ ] **Link admin panel in admin.html**
  ```html
  <a href="image-upload-admin.html">Upload Miner Images</a>
  ```

- [ ] **Update README.md** with image upload instructions

### Phase 6: Data Migration (Optional)

If you have existing images:

- [ ] Identify existing image URLs in miner_images table
- [ ] For each image, upload to imgbb and get delete_url
- [ ] Update database with imgbb URLs
- [ ] Verify all images load correctly

### Phase 7: Monitoring

- [ ] **Set up alerts**
  - Monitor `/api/miner-images` error rate
  - Alert if imgbb API returns errors
  - Track upload failures

- [ ] **Enable logging**
  - Cloudflare Worker logs
  - Supabase database logs
  - Browser console monitoring

### Phase 8: Backup & Rollback Plan

- [ ] **Backup database**
  ```bash
  pg_dump -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres > minerprices_backup.sql
  ```

- [ ] **Store imgbb delete URLs**
  - Already stored in `delete_url` column
  - Can delete images if needed

- [ ] **Keep fallback in place**
  - Original placeholder SVG system still works
  - If imgbb fails, users see placeholder

### Phase 9: Production Go-Live

- [ ] All tests passing
- [ ] Monitoring configured
- [ ] Team trained on image upload process
- [ ] Backup created
- [ ] Rollback plan documented

**GO LIVE** ✅

- [ ] Monitor error logs for first 24 hours
- [ ] Upload test images to ensure system works
- [ ] Gradually migrate existing images (if any)

### Post-Launch

- [ ] Weekly monitoring of imgbb API usage
- [ ] Check storage costs
- [ ] Optimize image sizes if needed
- [ ] Gather user feedback

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `miner.html` | Updated to load images from DB | ✅ Modified |
| `imgbb-upload-handler.js` | Upload/retrieve/delete logic | ✅ Created |
| `wrangler-routes.js` | Worker route definitions | ✅ Created |
| `image-upload-admin.html` | Admin upload interface | ✅ Created |
| `migration-add-imgbb-fields.sql` | DB schema update | ✅ Created |
| `IMGBB_DEPLOYMENT.md` | Detailed deployment guide | ✅ Created |

## Rollback Procedure

If critical issues occur:

1. **Revert miner.html** to previous version
   ```bash
   git checkout HEAD~1 -- miner.html
   ```
   (This reverts to placeholder images)

2. **Disable image upload endpoints**
   ```bash
   wrangler rollback --env production
   ```

3. **Keep database as-is**
   - Can repopulate URLs later
   - No data loss

## Cost Analysis

### Monthly Estimate
- **imgbb Free Tier**: 30 uploads/month
- **After 30 uploads**: $0.25 per 1000 images
- **Typical usage** (20 miners × 3 images): $0.015/month
- **Total**: ~$0 to $0.20/month

### Storage
- **1000 images @ 200KB avg**: ~200GB
- **imgbb 30-day deletion**: Automatic cleanup if unused
- **Cost at scale**: Still under $1/month

## Testing Commands

```bash
# Test database migration
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres -c "\d miner_images"

# Test upload
curl -X POST https://minerprices.com/api/upload-miner-image \
  -F "image=@/path/to/image.jpg" \
  -F "miner_id=1" \
  -F "caption=Test" \
  -F "is_primary=true"

# Test retrieval
curl https://minerprices.com/api/miner-images/1

# Test delete
curl -X DELETE https://minerprices.com/api/miner-images/[imageId]

# Browser test
# 1. Open https://minerprices.com/miner.html?id=1
# 2. Verify image loads in hero section
# 3. Check browser console for errors
# 4. Open DevTools > Network and check image load time
```

## Team Responsibilities

- **DevOps**: Database migration, Worker deployment
- **Frontend**: Test miner.html, verify image display
- **Admin**: Use image-upload-admin.html to populate images
- **QA**: Run regression tests, monitor performance

---

**Checklist Created**: 2026-05-07
**Status**: Ready for Deployment ✅

Next action: Run Phase 1 database migration
