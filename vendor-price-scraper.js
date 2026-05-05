#!/usr/bin/env node

/**
 * MINERPRICES - VENDOR PRICE SCRAPER
 * 
 * Allows vendors to:
 * 1. Auto-scrape prices from competitor websites
 * 2. Bulk import miner listings from URLs
 * 3. Manually adjust/verify prices
 * 4. Sync to database
 * 
 * Usage: node vendor-price-scraper.js <vendor-id> <scrape-url>
 */

const https = require('https');
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://huzfnrgfcxlwvmrkoyge.supabase.co';
const SUPABASE_KEY = 'sb_secret_3td2axHwZP0Nk_UOQ0FbKA_KjhOm3-y';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

/**
 * Fetch HTML from URL
 */
function fetchHtml(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

/**
 * Parse miner names and prices from HTML
 * Pattern: "Antminer S23 - $15000" or "Antminer S23: Price $15000"
 */
function parseMinerPrices(html) {
  const results = [];
  
  // Pattern 1: "MinerName - $PRICE"
  const pattern1 = /([A-Za-z0-9\s\-]+)\s*[-–]\s*\$?([\d,]+(?:\.\d{2})?)/gi;
  let match;
  
  while ((match = pattern1.exec(html)) !== null) {
    const name = match[1].trim();
    const price = parseFloat(match[2].replace(',', ''));
    
    if (name.length > 5 && name.length < 100 && price > 100) {
      results.push({ name, price });
    }
  }
  
  return results;
}

/**
 * Match scraped miner names to database miners
 */
async function matchMiners(scrapedItems) {
  console.log(`🔍 Matching ${scrapedItems.length} scraped items to database...`);
  
  const { data: dbMiners } = await supabase.from('miners').select('id, name, slug');
  const matches = [];
  
  for (const item of scrapedItems) {
    // Try exact match first
    let miner = dbMiners?.find(m => m.name.toLowerCase() === item.name.toLowerCase());
    
    // Try partial match
    if (!miner) {
      const words = item.name.toLowerCase().split(/\s+/);
      miner = dbMiners?.find(m => 
        words.some(w => m.name.toLowerCase().includes(w))
      );
    }
    
    if (miner) {
      matches.push({
        minerId: miner.id,
        minerName: miner.name,
        scrapedPrice: item.price,
        confidence: 'high'
      });
    } else {
      matches.push({
        minerName: item.name,
        scrapedPrice: item.price,
        confidence: 'low',
        note: 'No match found - may need manual review'
      });
    }
  }
  
  return matches;
}

/**
 * Create or update vendor listings from scrape results
 */
async function updateVendorListings(vendorId, matches) {
  console.log(`💾 Updating ${matches.length} listings for vendor ${vendorId}...`);
  
  let inserted = 0;
  let updated = 0;
  let skipped = 0;
  
  for (const match of matches) {
    if (match.confidence === 'low') {
      console.log(`⚠️  Skipping low-confidence match: ${match.minerName}`);
      skipped++;
      continue;
    }
    
    // Check if listing already exists
    const { data: existing } = await supabase
      .from('vendor_listings')
      .select('id')
      .eq('vendor_id', vendorId)
      .eq('miner_id', match.minerId)
      .single();
    
    if (existing) {
      // Update existing
      const { error } = await supabase
        .from('vendor_listings')
        .update({ purchase_price: match.scrapedPrice })
        .eq('id', existing.id);
      
      if (error) {
        console.error(`  ❌ Error updating ${match.minerName}:`, error.message);
      } else {
        console.log(`  ✅ Updated: ${match.minerName} → $${match.scrapedPrice}`);
        updated++;
      }
    } else {
      // Create new listing
      const { error } = await supabase.from('vendor_listings').insert([{
        vendor_id: vendorId,
        miner_id: match.minerId,
        purchase_price: match.scrapedPrice,
        quantity_available: 1,
        in_stock: true,
        active: true
      }]);
      
      if (error) {
        console.error(`  ❌ Error creating listing for ${match.minerName}:`, error.message);
      } else {
        console.log(`  ✅ Created: ${match.minerName} → $${match.scrapedPrice}`);
        inserted++;
      }
    }
  }
  
  return { inserted, updated, skipped };
}

/**
 * Scrape prices from OBE Miners website
 */
async function scrapeObeminers(vendorId) {
  console.log('📡 Scraping OBE Miners prices...');
  
  try {
    const html = await fetchHtml('https://obeminers.com/products');
    const items = parseMinerPrices(html);
    console.log(`Found ${items.length} items on OBE Miners`);
    
    const matches = await matchMiners(items);
    const stats = await updateVendorListings(vendorId, matches);
    
    return stats;
  } catch (error) {
    console.error('❌ Error scraping OBE Miners:', error.message);
    return { inserted: 0, updated: 0, skipped: 0 };
  }
}

/**
 * Get vendor from email (for demo)
 */
async function getVendorByEmail(email) {
  const { data } = await supabase
    .from('vendors')
    .select('id, name')
    .eq('email', email)
    .single();
  return data;
}

/**
 * CLI Interface
 */
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log(`
╔════════════════════════════════════════════════════════════════╗
║         MINERPRICES VENDOR PRICE SCRAPER                      ║
║                                                                ║
║ Auto-scrape prices from competitor websites & bulk import     ║
║ pricing. Vendors can then manually verify & adjust.           ║
╚════════════════════════════════════════════════════════════════╝

USAGE:

  1. Scrape OBE Miners (example):
     node vendor-price-scraper.js scrape obeminers <vendor-id>

  2. Scrape generic website:
     node vendor-price-scraper.js scrape <url> <vendor-id>

  3. Match scraped items to database:
     node vendor-price-scraper.js match <json-file> <vendor-id>

EXAMPLE:
  node vendor-price-scraper.js scrape obeminers 1
  
This will:
  ✅ Scrape OBE Miners website
  ✅ Parse miner names and prices
  ✅ Match to your database miners
  ✅ Create/update vendor listings
  ✅ You can then manually verify prices in the dashboard

NEXT:
  1. Vendor logs in to dashboard
  2. Views auto-scraped listings
  3. Adjusts prices/quantities as needed
  4. Publishes to marketplace
    `);
    process.exit(0);
  }
  
  const command = args[0];
  
  if (command === 'scrape') {
    const source = args[1];
    const vendorId = parseInt(args[2]);
    
    if (!vendorId) {
      console.error('❌ Error: vendor-id required');
      process.exit(1);
    }
    
    console.log('\n' + '='.repeat(70));
    console.log('🚀 Starting vendor price scrape...');
    console.log('='.repeat(70) + '\n');
    
    let stats;
    
    if (source === 'obeminers') {
      stats = await scrapeObeminers(vendorId);
    } else {
      try {
        const html = await fetchHtml(source);
        const items = parseMinerPrices(html);
        const matches = await matchMiners(items);
        stats = await updateVendorListings(vendorId, matches);
      } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
      }
    }
    
    console.log('\n' + '='.repeat(70));
    console.log('✅ SCRAPE COMPLETE');
    console.log(`   Created: ${stats.inserted}, Updated: ${stats.updated}, Skipped: ${stats.skipped}`);
    console.log('='.repeat(70) + '\n');
    
  } else {
    console.error(`❌ Unknown command: ${command}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { parseMinerPrices, matchMiners, updateVendorListings, scrapeObeminers };
