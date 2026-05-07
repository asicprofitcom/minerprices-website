# 🎯 Image Gallery Manager - Complete Guide

**Live at**: https://minerprices.com/images.html

## How It Works

This is your admin panel for managing miner images. It stores images in Supabase and displays them on miner pages.

## Step-by-Step: Upload an Image

### Step 1: Go to Gallery Manager
```
https://minerprices.com/images.html
```

### Step 2: Get Image URL from imgbb
1. Open: https://imgbb.com
2. Click "Upload image"
3. Select your miner photo (JPG, PNG, etc.)
4. Right-click on image → "Copy image address"
5. You now have URL like: `https://ibb.co/abc123xyz`

### Step 3: Add to Gallery
1. In gallery manager, search for miner name (e.g., "Antminer S21")
2. Click on miner to select it
3. Paste the imgbb URL in the "Or paste imgbb URL directly" field
4. (Optional) Add caption like "Front view" or "Product photo"
5. Click "Upload & Save"

### Step 4: Done! ✅
Image appears on miner page instantly:
```
https://minerprices.com/miner/antminer-s21-pro-234t
```

## Features Explained

### Search & Select Miner
- Type miner name in search box
- Click to select from dropdown
- Selected miner name shows below search

### Image URL Input
Two ways to add images:

**Option 1: Upload file directly**
- Click "Image File" input
- Select photo from computer
- (Future feature: uploads to imgbb automatically)

**Option 2: Paste URL**
- Get URL from imgbb.com
- Paste in "Or paste imgbb URL directly" field
- Click "Upload & Save"

### Image Caption (Optional)
- Add description like "Front view", "Mining setup", etc.
- Helps identify images in gallery
- Shows in admin gallery

### Gallery View
- Shows all images you've uploaded
- Displays:
  - Preview thumbnail
  - Miner name it belongs to
  - Image URL
  - Copy URL button (for sharing)
  - Delete button

### Copy URL Button
- Click to copy image URL
- Paste into other systems if needed
- Useful for sharing

### Delete Button
- Remove image from database
- Image disappears from miner page
- Can't be undone - be careful!

## Workflow Example

**Task: Add photo of Antminer S21 Pro**

```
1. Open https://minerprices.com/images.html
2. Search: type "Antminer S21"
3. Click "Antminer S21 Pro" from list
4. Open https://imgbb.com in new tab
5. Upload your S21 photo
6. Copy image URL from imgbb
7. Back to gallery manager
8. Paste URL in text field
9. Type caption: "Antminer S21 Pro - Product Photo"
10. Click "Upload & Save"
11. ✅ Done! Photo now on: https://minerprices.com/miner/antminer-s21-pro-234t
```

**Time required**: ~2-3 minutes per image

## Troubleshooting

### Image not showing on miner page
1. Check image URL is valid (can you see it in browser?)
2. Wait 10 seconds and refresh miner page
3. Check in gallery that image was added

### imgbb URL invalid
- Make sure you copied from imgbb.com
- Don't use shortened URLs
- URL should start with `https://ibb.co/`

### Can't find miner
- Gallery manager only searches from database
- Miner must exist in system first
- Try different search terms

### Delete was accidental
- Image deleted from database
- Can't undo - you'd need to re-upload
- Be careful with delete button!

## Image Best Practices

### File Size
- Smaller = faster loading
- Recommended: 100-500 KB
- imgbb compresses automatically

### Image Format
- JPG: Best for photos
- PNG: Best for transparency
- Use JPG for product photos

### Image Orientation
- Landscape (wider than tall) works best
- Will be displayed at 200x200px in gallery
- Will fill miner hero section

### Image Quality
- Clear, well-lit photos work best
- Professional product photos recommended
- Avoid blurry or poorly lit images

## API Reference (For Developers)

### Database Table: miner_images

| Column | Type | Notes |
|--------|------|-------|
| id | BIGINT | Primary key |
| miner_id | BIGINT | Foreign key to miners table |
| image_url | TEXT | imgbb URL |
| caption | VARCHAR(255) | Optional description |
| is_primary | BOOLEAN | Primary image flag |
| created_at | TIMESTAMP | Auto-set |

### Insert Image (SQL)
```sql
INSERT INTO miner_images (miner_id, image_url, caption, is_primary)
VALUES (42, 'https://ibb.co/abc123xyz', 'Product photo', true);
```

### View Images
```sql
SELECT m.name, mi.image_url, mi.caption
FROM miner_images mi
JOIN miners m ON mi.miner_id = m.id
ORDER BY m.name;
```

### Delete Image
```sql
DELETE FROM miner_images WHERE id = 123;
```

## Batch Upload (For Multiple Images)

If you have many images:

1. Upload all to imgbb.com at once (free account allows this)
2. Open Excel/Google Sheets
3. Create columns: Miner Name | Image URL | Caption
4. Fill in all your images
5. For each row, follow the steps above
6. Takes ~1 minute per image with practice

## Contact & Support

All features should work as expected.

If something doesn't work:
1. Check troubleshooting section above
2. Verify imgbb URL is correct
3. Try refreshing the page
4. Check browser console (F12) for errors

---

**Gallery Manager**: https://minerprices.com/images.html

**Ready to add images!** 🎉
