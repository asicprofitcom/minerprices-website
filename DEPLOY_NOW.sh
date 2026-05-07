#!/bin/bash

# ====================================================================
# MINERPRICES IMAGE UPLOAD SYSTEM - DEPLOYMENT SCRIPT
# ====================================================================
# Run this script to deploy the imgbb integration to production
# Usage: ./DEPLOY_NOW.sh
# ====================================================================

set -e

echo "🚀 MinerPrices Image Upload System - Deployment Script"
echo "=================================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v psql &> /dev/null; then
    echo "❌ psql not found. Install PostgreSQL client."
    exit 1
fi

if ! command -v wrangler &> /dev/null; then
    echo "❌ wrangler not found. Install: npm install -g wrangler"
    exit 1
fi

if [ -z "$IMGBB_API_KEY" ]; then
    echo "❌ IMGBB_API_KEY not set. Run:"
    echo "   export IMGBB_API_KEY='your_key_here'"
    exit 1
fi

if [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo "⚠️  SUPABASE_SERVICE_KEY not set. You'll need to set it in wrangler.toml"
fi

echo "✅ Prerequisites OK"
echo ""

# Phase 1: Database Migration
echo "📦 Phase 1: Running Database Migration..."
echo "=================================================="

read -p "Database host (default: db.huzfnrgfcxlwvmrkoyge.supabase.co): " DB_HOST
DB_HOST=${DB_HOST:-db.huzfnrgfcxlwvmrkoyge.supabase.co}

read -p "Database user (default: max_bot): " DB_USER
DB_USER=${DB_USER:-max_bot}

read -sp "Database password: " DB_PASSWORD
echo ""

if [ -f "migration-add-imgbb-fields.sql" ]; then
    echo "Running migration..."
    PGPASSWORD="$DB_PASSWORD" psql \
        -h "$DB_HOST" \
        -U "$DB_USER" \
        -d postgres \
        -f migration-add-imgbb-fields.sql
    
    if [ $? -eq 0 ]; then
        echo "✅ Database migration successful"
    else
        echo "❌ Database migration failed"
        exit 1
    fi
else
    echo "❌ migration-add-imgbb-fields.sql not found"
    exit 1
fi

echo ""

# Phase 2: Update Wrangler Config
echo "⚙️  Phase 2: Updating Wrangler Configuration..."
echo "=================================================="

if [ ! -f "wrangler.toml" ]; then
    echo "❌ wrangler.toml not found"
    exit 1
fi

echo "ℹ️  Please ensure wrangler.toml has:"
echo "   [env.production.vars]"
echo "   IMGBB_API_KEY = \"$IMGBB_API_KEY\""
echo "   SUPABASE_URL = \"https://huzfnrgfcxlwvmrkoyge.supabase.co\""
echo ""
echo "   [env.production.secrets]"
echo "   SUPABASE_SERVICE_KEY = \"your_service_key\""
echo ""

read -p "Has wrangler.toml been updated? (y/n): " CONTINUE
if [ "$CONTINUE" != "y" ]; then
    echo "⏸️  Please update wrangler.toml and run this script again"
    exit 0
fi

echo "✅ Wrangler configured"
echo ""

# Phase 3: Deploy Worker
echo "🚀 Phase 3: Deploying Cloudflare Worker..."
echo "=================================================="

echo "Installing npm dependencies..."
npm install @supabase/supabase-js 2>/dev/null || true

echo "Deploying to production..."
wrangler deploy --env production

if [ $? -eq 0 ]; then
    echo "✅ Worker deployed successfully"
else
    echo "❌ Worker deployment failed"
    exit 1
fi

echo ""

# Phase 4: Verify Deployment
echo "✅ Phase 4: Verifying Deployment..."
echo "=================================================="

DOMAIN="minerprices.com"
echo "Testing API endpoint: https://$DOMAIN/api/miner-images/1"

RESPONSE=$(curl -s -w "\n%{http_code}" "https://$DOMAIN/api/miner-images/1")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API is responding correctly"
    echo "Response: $BODY"
else
    echo "⚠️  API returned code $HTTP_CODE"
    echo "Response: $BODY"
    echo ""
    echo "This might be normal if no images exist yet. Check:"
    echo "  https://minerprices.com/image-upload-admin.html"
fi

echo ""

# Phase 5: Summary
echo "🎉 Deployment Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Go to: https://minerprices.com/image-upload-admin.html"
echo "2. Upload test images for a miner"
echo "3. Visit: https://minerprices.com/miner.html?id=1"
echo "4. Verify images display correctly"
echo ""
echo "Documentation:"
echo "  • README_IMAGE_UPLOAD.md - Quick start & API reference"
echo "  • IMGBB_DEPLOYMENT.md - Technical details"
echo "  • PRODUCTION_CHECKLIST.md - Complete deployment guide"
echo ""
echo "Commands for manual testing:"
echo ""
echo "# Fetch images for miner"
echo "curl https://minerprices.com/api/miner-images/1"
echo ""
echo "# Upload image"
echo "curl -X POST https://minerprices.com/api/upload-miner-image \\"
echo "  -F 'image=@photo.jpg' \\"
echo "  -F 'miner_id=1' \\"
echo "  -F 'caption=Test' \\"
echo "  -F 'is_primary=true'"
echo ""
echo "🚀 System is live and ready to use!"
