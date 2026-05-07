# ⚡ Quick Reference Card - Image Upload System

## URLs

| Purpose | URL |
|---------|-----|
| Upload Images | `https://minerprices.com/image-upload-admin.html` |
| View Miner | `https://minerprices.com/miner.html?id=1` |
| API Docs | `README_IMAGE_UPLOAD.md` |

## API Endpoints

### Upload Image
```bash
curl -X POST https://minerprices.com/api/upload-miner-image \
  -F "image=@photo.jpg" \
  -F "miner_id=1" \
  -F "caption=Optional caption" \
  -F "is_primary=true"
```

### Get Images
```bash
curl https://minerprices.com/api/miner-images/1
```

### Delete Image
```bash
curl -X DELETE https://minerprices.com/api/miner-images/{imageId}
```

### Update Metadata
```bash
curl -X PATCH https://minerprices.com/api/miner-images/{imageId} \
  -H "Content-Type: application/json" \
  -d '{"is_primary": true, "caption": "New"}'
```

## Database Commands

### Check Migration
```bash
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres \
  -c "\d miner_images"
```

### View Images
```bash
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres \
  -c "SELECT * FROM miner_images WHERE miner_id = 1;"
```

### Clear Images (if needed)
```bash
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres \
  -c "DELETE FROM miner_images WHERE miner_id = 1;"
```

## Deployment

### One-Command Deploy
```bash
./DEPLOY_NOW.sh
```

### Manual Steps
```bash
# 1. Migration
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres \
  -f migration-add-imgbb-fields.sql

# 2. Update wrangler.toml:
# Add: IMGBB_API_KEY, SUPABASE_SERVICE_KEY

# 3. Deploy
wrangler deploy --env production

# 4. Test
curl https://minerprices.com/api/miner-images/1
```

## Environment Variables

```bash
# Required
export IMGBB_API_KEY="your_imgbb_api_key"
export SUPABASE_SERVICE_KEY="your_service_key"
export SUPABASE_URL="https://huzfnrgfcxlwvmrkoyge.supabase.co"
```

## File Locations

```
minerprices-website/
├── miner.html                    (modified)
├── image-upload-admin.html       (upload UI)
├── imgbb-upload-handler.js       (API logic)
├── wrangler-routes.js            (routes)
├── migration-add-imgbb-fields.sql (DB)
├── DEPLOY_NOW.sh                 (deploy script)
├── README_IMAGE_UPLOAD.md        (docs)
├── IMGBB_DEPLOYMENT.md           (technical)
├── PRODUCTION_CHECKLIST.md       (checklist)
└── QUICK_REFERENCE.md            (this file)
```

## Troubleshooting

### Images not appearing
```bash
# Check API
curl https://minerprices.com/api/miner-images/1

# Check DB
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co -U max_bot -d postgres \
  -c "SELECT COUNT(*) FROM miner_images;"

# Check browser console (F12)
```

### Upload fails
```bash
# Verify API key
echo $IMGBB_API_KEY

# Test imgbb directly
curl -X POST https://api.imgbb.com/1/upload \
  -F "image=@test.jpg" \
  -F "key=$IMGBB_API_KEY"
```

### Worker not responding
```bash
# Check deployment status
wrangler status --env production

# Redeploy
wrangler deploy --env production

# Check logs
wrangler tail --env production
```

## Key Features

✅ Images → imgbb
✅ URLs → Supabase
✅ Display → miner.html
✅ Admin → image-upload-admin.html
✅ Fallback → placeholder SVG
✅ CDN → imgbb global

## Cost

| Item | Cost |
|------|------|
| Free tier | 30 uploads/month |
| Typical | ~$0-0.20/month |
| Scaling | $0.25 per 1000 |

## Commits

```bash
# View commits
cd minerprices-website && git log --oneline | head -5

# View changes
git show 9c339f1  # Latest commit
```

## Support

| Question | File |
|----------|------|
| How do I upload? | README_IMAGE_UPLOAD.md |
| How do I deploy? | IMGBB_DEPLOYMENT.md |
| How do I go live? | PRODUCTION_CHECKLIST.md |
| Quick help? | QUICK_REFERENCE.md |

---

**Version**: 1.0
**Status**: Production Ready ✅
**Created**: 2026-05-07
