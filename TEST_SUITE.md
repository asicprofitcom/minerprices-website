# 🧪 Complete Test Suite - Image Upload System

**Date:** May 10, 2026  
**Status:** All tests must pass before production

---

## Pre-Test Setup

### Requirements
- Supabase credentials working
- minerprices.com domain accessible
- Browser with console access (F12)
- Test imgbb images (pre-uploaded)

### Test Images (Use These)
1. https://ibb.co/test-s21 (Mock S21)
2. https://ibb.co/test-m60 (Mock M60)
3. https://ibb.co/test-t21 (Mock T21)

---

## Test Suite 1: Frontend Validation

### Test 1.1: Page Load
**Steps:**
1. Open: https://minerprices.com/images.html
2. Wait 3 seconds for page to load
3. Open browser console (F12 > Console tab)

**Expected Results:**
- ✅ Page loads without errors
- ✅ Console shows: "✅ Database connected"
- ✅ Miner search field is visible
- ✅ Upload form fields are visible
- ✅ Gallery section shows existing images

**Fail If:**
- ❌ Page takes >5 seconds to load
- ❌ Console shows red errors
- ❌ Form fields are missing
- ❌ Database connection error shown

---

### Test 1.2: Miner Search & Selection
**Steps:**
1. Click miner search field
2. Type "S21" (or first 3 letters of any miner)
3. Wait for dropdown to appear
4. Click on a miner in the list

**Expected Results:**
- ✅ Dropdown appears with matching miners
- ✅ Selected text shows: "✅ Selected: Antminer S21" (or selected miner name)
- ✅ Miner ID is stored (backend will use this)
- ✅ Search field is cleared

**Fail If:**
- ❌ Dropdown never appears
- ❌ Selection doesn't register
- ❌ Wrong miner name shows
- ❌ Error in console about miners not loading

---

### Test 1.3: URL Validation - Valid Inputs
**Steps:**
1. Select a miner (from Test 1.2)
2. Paste this imgbb URL: `https://ibb.co/test-s21`
3. Click "Upload & Save"
4. Watch for response

**Expected Results:**
- ✅ "⏳ Processing..." message appears
- ✅ Within 2 seconds: "✅ Image added to..." success message
- ✅ Gallery refreshes with loading state
- ✅ New image appears in gallery below

**Fail If:**
- ❌ Error message appears
- ❌ Upload takes >5 seconds
- ❌ Success shown but image doesn't appear
- ❌ Gallery shows "All Images (0)" after upload

---

### Test 1.4: URL Validation - Invalid Inputs
**Steps:** Repeat for each invalid input below

**Invalid Input: No Miner Selected**
1. Don't select miner
2. Paste URL
3. Click Upload
- ✅ Shows: "❌ Please select a miner first"

**Invalid Input: Invalid URL**
1. Select a miner
2. Paste: `not-a-url`
3. Click Upload
- ✅ Shows: "❌ Invalid image URL..."

**Invalid Input: No URL Provided**
1. Select a miner
2. Leave URL empty
3. Click Upload
- ✅ Shows: "❌ Please provide either an image URL..."

**Invalid Input: Duplicate URL (for same miner)**
1. Select same miner as Test 1.3
2. Paste same URL: `https://ibb.co/test-s21`
3. Click Upload
- ✅ Shows: "⚠️ This image URL is already in database for this miner"

---

### Test 1.5: Reset Button
**Steps:**
1. Upload an image (Test 1.3)
2. Click "Reset" button
3. Verify form is cleared

**Expected Results:**
- ✅ All fields cleared (miner selection, URL, caption)
- ✅ "No miner selected" text shows
- ✅ Form ready for new upload

---

## Test Suite 2: Database Operations

### Test 2.1: Image Insertion
**Steps:**
1. Open Supabase dashboard
2. Go to: SQL Editor
3. Run this query:
```sql
SELECT * FROM miner_images WHERE created_at > NOW() - INTERVAL '5 minutes' ORDER BY created_at DESC LIMIT 5;
```

**Expected Results:**
- ✅ New images from Test 1.3 appear in results
- ✅ Fields are populated: miner_id, image_url, caption, is_primary, created_at
- ✅ No null image_urls
- ✅ Miner IDs match miners table

**Fail If:**
- ❌ New images don't appear
- ❌ Miner IDs are null or invalid
- ❌ Image URLs are truncated or corrupted

---

### Test 2.2: Foreign Key Constraint (Safety)
**Steps:**
1. Open browser console (F12)
2. Try this JavaScript (paste in console):
```javascript
// Try to upload with invalid miner ID
const { data, error } = await supabase
  .from('miner_images')
  .insert({
    miner_id: 99999,
    image_url: 'https://ibb.co/test-99999',
    caption: 'Should fail',
    is_primary: false
  })
  .select();

if (error) console.log('Foreign key protection works:', error.message);
```

**Expected Results:**
- ✅ Error appears: foreign key violation or similar
- ✅ No image is inserted
- ✅ Database prevents invalid miner references

**Fail If:**
- ❌ No error thrown
- ❌ Image is inserted with invalid miner_id
- ❌ Database allows orphaned records

---

### Test 2.3: Duplicate Prevention
**Steps:**
1. Manually insert same image twice (via console or direct insert)
2. Check results

**Expected Results:**
- ✅ Second insert fails with unique constraint error
- ✅ Message indicates: "UNIQUE constraint violation"

---

## Test Suite 3: API Endpoints

### Test 3.1: GET /api/miner-images/:minerId
**Steps:**
1. Open new browser tab
2. Go to: https://minerprices.com/api/miner-images/1
3. View page source

**Expected Results:**
- ✅ Returns JSON response (not HTML)
- ✅ Status code: 200
- ✅ Response includes: success, minerId, images (array), count
- ✅ Images array contains uploaded images

**Example Response:**
```json
{
  "success": true,
  "minerId": 1,
  "images": [
    {
      "id": 1,
      "miner_id": 1,
      "image_url": "https://ibb.co/test-s21",
      "caption": null,
      "is_primary": false,
      "created_at": "2026-05-10T19:42:00+00:00"
    }
  ],
  "count": 1
}
```

**Fail If:**
- ❌ Returns HTML instead of JSON
- ❌ Status code 404 or 500
- ❌ No images in response

---

### Test 3.2: Invalid Miner ID
**Steps:**
1. Go to: https://minerprices.com/api/miner-images/99999
2. View response

**Expected Results:**
- ✅ Status: 200 (not 404)
- ✅ Response: `{"success": true, "minerId": 99999, "images": [], "count": 0}`
- ✅ Empty array (no images for nonexistent miner)

**Fail If:**
- ❌ Returns 404 error
- ❌ Returns error instead of empty result

---

## Test Suite 4: Gallery Display

### Test 4.1: Gallery Rendering
**Steps:**
1. Open images.html
2. Verify gallery shows images from Tests 1.3+
3. Check each image card displays:
   - Image thumbnail
   - Miner name
   - Partial URL
   - Caption (if added)
   - Copy & Delete buttons

**Expected Results:**
- ✅ All images display correctly
- ✅ Images sorted by creation date (newest first)
- ✅ Primary images show "PRIMARY" badge
- ✅ Broken image URLs show error placeholder

---

### Test 4.2: Copy URL Function
**Steps:**
1. Click "Copy" button on any image
2. Paste in notepad (Ctrl+V or Cmd+V)

**Expected Results:**
- ✅ Full URL is copied
- ✅ Success message appears
- ✅ Pasted URL is valid (https://ibb.co/...)

**Fail If:**
- ❌ Copy doesn't work
- ❌ Copied text is truncated
- ❌ Wrong URL copied

---

### Test 4.3: Delete Function
**Steps:**
1. Click "Delete" button on any image
2. Confirm in popup
3. Wait for reload

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ After confirm: "✅ Image deleted successfully!" message
- ✅ Image disappears from gallery
- ✅ Image count decreases
- ✅ Image removed from database

---

## Test Suite 5: Error Scenarios

### Test 5.1: Network Error Handling
**Steps:**
1. Open images.html
2. Open DevTools (F12 > Network)
3. Check "Offline" checkbox to simulate offline
4. Try to upload an image
5. Uncheck offline

**Expected Results:**
- ✅ Error message shown: database connection issue
- ✅ User knows something is wrong
- ✅ System recovers when network returns

---

### Test 5.2: Broken Image URL
**Steps:**
1. Manually insert bad URL in database (via Supabase)
   ```sql
   INSERT INTO miner_images (miner_id, image_url) 
   VALUES (1, 'https://broken.link/404.jpg');
   ```
2. Reload gallery page
3. Look for broken image

**Expected Results:**
- ✅ Broken image shows placeholder (gray box with "❌ Not Found")
- ✅ Rest of gallery still displays
- ✅ No console errors

---

### Test 5.3: Missing Miner
**Steps:**
1. Manually delete a miner from database
2. Reload gallery
3. Check images that belonged to that miner

**Expected Results:**
- ✅ Images show "Unknown Miner" name
- ✅ Images remain in gallery (no crash)
- ✅ Can still delete orphaned images

---

## Test Suite 6: Performance

### Test 6.1: Page Load Time
**Steps:**
1. Open DevTools (F12 > Performance)
2. Record page load
3. Go to: images.html
4. Stop recording
5. Check "First Contentful Paint" (FCP)

**Expected Results:**
- ✅ FCP < 2 seconds
- ✅ Fully interactive < 3 seconds
- ✅ Gallery loads < 4 seconds

---

### Test 6.2: Gallery with Many Images
**Steps:**
1. Insert 100+ test images:
   ```sql
   INSERT INTO miner_images (miner_id, image_url) 
   SELECT 1, 'https://ibb.co/test-' || i FROM generate_series(1,100) i;
   ```
2. Reload gallery
3. Scroll through all images

**Expected Results:**
- ✅ Page loads in <5 seconds
- ✅ No lag when scrolling
- ✅ All 100 images display

---

## Test Execution

### Run All Tests
```bash
# Manual test execution in browser
# Test Suite 1: Frontend Validation - ~5 minutes
# Test Suite 2: Database Operations - ~3 minutes  
# Test Suite 3: API Endpoints - ~2 minutes
# Test Suite 4: Gallery Display - ~3 minutes
# Test Suite 5: Error Scenarios - ~5 minutes
# Test Suite 6: Performance - ~3 minutes

# Total time: ~21 minutes
```

### Pass/Fail Criteria

**✅ PASS:** All tests pass without failures  
**⚠️ PARTIAL:** Some tests fail but core functionality works  
**❌ FAIL:** Critical tests fail (can't upload, database broken, etc.)

---

## Results

**Test Date:** [Run tests and fill in]  
**Tester:** [Your name]  
**Overall Status:** ☐ PASS ☐ PARTIAL ☐ FAIL

**Tests Passed:** ___/23  
**Tests Failed:** ___/23  
**Issues Found:** [List any]

---

## Sign-Off

- ✅ All critical tests passed
- ✅ System ready for production
- ✅ No known bugs

**Approved By:** ________________  
**Date:** ________________
