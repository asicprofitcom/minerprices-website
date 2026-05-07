# ⚡ SIMPLE Way to Add Images - Direct Database Method

## The Problem
The gallery UI needs API endpoints that require Cloudflare Workers deployment.
That's too complex. Let's do it the simple way.

## The Simple Solution

### Step 1: Upload Photo to imgbb.com
1. Go to: https://imgbb.com
2. Click "Upload image"
3. Select your miner photo
4. Get the image URL (e.g., `https://ibb.co/abc123xyz`)

### Step 2: Add to Database Directly
Run this SQL in Supabase:

```sql
-- Find your miner ID
SELECT id, name FROM miners WHERE name LIKE '%Antminer S21%';

-- Add image to that miner
INSERT INTO miner_images (miner_id, image_url, caption, is_primary)
VALUES (
  1,                                    -- Replace with actual miner ID
  'https://ibb.co/your-image-url',     -- Replace with your imgbb URL
  'Antminer S21 Pro',                  -- Optional caption
  true                                 -- Make it the primary image
);
```

### Step 3: Image appears on miner page
Go to: `https://minerprices.com/miner/antminer-s21-pro-234t`
The image now displays! ✅

## How to Find Miner ID

```bash
psql -h db.huzfnrgfcxlwvmrkoyge.supabase.co \
  -U max_bot -d postgres \
  -c "SELECT id, name FROM miners LIMIT 10;"
```

## How to Upload to imgbb

1. Visit: https://imgbb.com
2. Click upload button
3. Select image file
4. Copy the image URL
5. Use in SQL command above

## Complete Example

```sql
-- 1. Find miner
SELECT id, name FROM miners WHERE name = 'Antminer S21 Pro';
-- Result: id = 42

-- 2. Insert image
INSERT INTO miner_images (miner_id, image_url, is_primary)
VALUES (42, 'https://ibb.co/abc123xyz', true);

-- 3. Verify
SELECT * FROM miner_images WHERE miner_id = 42;
```

## Delete an Image

```sql
DELETE FROM miner_images WHERE id = 123;
```

## Update Image URL

```sql
UPDATE miner_images 
SET image_url = 'https://ibb.co/new-url'
WHERE miner_id = 42;
```

## Check What's Already There

```sql
SELECT m.name, mi.image_url, mi.is_primary 
FROM miners m
LEFT JOIN miner_images mi ON m.id = mi.miner_id
ORDER BY m.name;
```

---

## That's It!

No complex APIs, no deployment scripts, just:
1. Upload to imgbb
2. Copy URL
3. Paste in SQL
4. Done ✅

Simple and works immediately!
