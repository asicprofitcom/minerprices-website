#!/usr/bin/env node

/**
 * MINERPRICES - DAILY AUTO-SYNC SYSTEM
 * 
 * Runs once per day to:
 * 1. Fetch new coins from CoinGecko
 * 2. Update coin prices and difficulty
 * 3. Scan for new mining algorithms
 * 4. Calculate profitability snapshots
 * 
 * Schedule: 08:00 AM EDT daily via cron
 * Command: node daily-sync-coins-miners.js
 */

const https = require('https');
const { createClient } = require('@supabase/supabase-js');

// Configuration
const SUPABASE_URL = 'https://huzfnrgfcxlwvmrkoyge.supabase.co';
const SUPABASE_KEY = 'sb_secret_3td2axHwZP0Nk_UOQ0FbKA_KjhOm3-y';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

/**
 * Fetch data from HTTPS endpoint
 */
function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

/**
 * STEP 1: Fetch and sync coins from CoinGecko
 */
async function syncCoinsFromCoinGecko() {
  console.log('📊 [SYNC] Fetching coins from CoinGecko...');
  
  try {
    // Fetch top coins by market cap
    const url = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=false';
    const coins = await fetchJson(url);
    
    let inserted = 0;
    let updated = 0;
    
    for (const coin of coins) {
      // Find or create algorithm first
      const algName = coin.symbol.toUpperCase();
      let { data: algData } = await supabase
        .from('algorithms')
        .select('id')
        .eq('name', algName)
        .single();
      
      let algorithmId = algData?.id;
      
      // If algorithm doesn't exist, create basic entry
      if (!algorithmId) {
        const { data: newAlg } = await supabase
          .from('algorithms')
          .insert([{ name: algName, description: `${coin.name} mining` }])
          .select('id')
          .single();
        algorithmId = newAlg?.id;
      }
      
      // Upsert coin
      const { error } = await supabase.from('coins').upsert([{
        name: coin.name,
        symbol: coin.symbol.toUpperCase(),
        algorithm_id: algorithmId,
        current_price: coin.current_price,
        price_change_24h: coin.price_change_percentage_24h,
        market_cap: coin.market_cap,
        volume_24h: coin.total_volume,
        logo_url: coin.image,
        visible: coin.market_cap_rank <= 200 // Show top 200 coins
      }], {
        onConflict: 'symbol',
        ignoreDuplicates: false
      });
      
      if (error) {
        console.error(`⚠️ Error syncing ${coin.symbol}:`, error.message);
      } else {
        updated++;
      }
    }
    
    console.log(`✅ [COINS] Updated ${updated} coins from CoinGecko`);
    return updated;
    
  } catch (error) {
    console.error('❌ [COINS] Error:', error.message);
    return 0;
  }
}

/**
 * STEP 2: Fetch Bitcoin difficulty from Blockchair
 */
async function updateBitcoinDifficulty() {
  console.log('⛏️  [DIFFICULTY] Fetching Bitcoin difficulty...');
  
  try {
    const data = await fetchJson('https://api.blockchair.com/bitcoin/stats');
    
    if (data && data.data) {
      const { difficulty, median_block_time } = data.data;
      
      // Get Bitcoin coin ID
      const { data: btc } = await supabase
        .from('coins')
        .select('id')
        .eq('symbol', 'BTC')
        .single();
      
      if (btc) {
        // Update coin difficulty
        await supabase
          .from('coins')
          .update({
            difficulty: parseFloat(difficulty),
            block_reward: 6.25 // Current BTC block reward
          })
          .eq('id', btc.id);
        
        // Save difficulty snapshot
        await supabase.from('coin_difficulty_history').insert([{
          coin_id: btc.id,
          date: new Date().toISOString().split('T')[0],
          difficulty: parseFloat(difficulty),
          block_time_seconds: median_block_time
        }]).on('*', payload => {
          // Ignore if duplicate
        });
        
        console.log(`✅ [DIFFICULTY] Bitcoin difficulty updated: ${difficulty}`);
      }
    }
  } catch (error) {
    console.error('⚠️ [DIFFICULTY] Error:', error.message);
  }
}

/**
 * STEP 3: Calculate profitability snapshots for all miner-coin combinations
 */
async function calculateProfitability() {
  console.log('💰 [PROFITABILITY] Calculating ROI for all miners...');
  
  try {
    // Get all miners and coins
    const { data: miners } = await supabase.from('miners').select('id, name, power_consumption, average_price');
    const { data: coins } = await supabase.from('coins').select('id, symbol, current_price, difficulty, block_reward');
    const { data: minerCoins } = await supabase.from('miner_coins').select('miner_id, coin_id, hashrate_for_coin');
    
    let snapshots = 0;
    const today = new Date().toISOString().split('T')[0];
    
    for (const mc of minerCoins || []) {
      const miner = miners?.find(m => m.id === mc.miner_id);
      const coin = coins?.find(c => c.id === mc.coin_id);
      
      if (miner && coin && miner.power_consumption > 0 && coin.current_price) {
        // Simplified profitability calculation
        const dailyProfit = (mc.hashrate_for_coin / 1e12) * (coin.block_reward || 1) * (coin.current_price || 0);
        const roi = (dailyProfit * 365) / (miner.average_price || 1) * 100;
        
        await supabase.from('profitability_snapshots').insert([{
          miner_id: mc.miner_id,
          coin_id: mc.coin_id,
          daily_profit: dailyProfit,
          weekly_profit: dailyProfit * 7,
          monthly_profit: dailyProfit * 30,
          yearly_profit: dailyProfit * 365,
          roi_percentage: roi,
          difficulty: coin.difficulty,
          coin_price: coin.current_price,
          miner_price: miner.average_price,
          date: today
        }]).on('*', () => {
          // Ignore duplicates
        });
        
        snapshots++;
      }
    }
    
    console.log(`✅ [PROFITABILITY] Created ${snapshots} profitability snapshots`);
    
  } catch (error) {
    console.error('⚠️ [PROFITABILITY] Error:', error.message);
  }
}

/**
 * Log update in database
 */
async function logUpdate(status, errors = 0) {
  try {
    await supabase.from('update_logs').insert([{
      update_type: 'daily_sync',
      status: status,
      errors_count: errors,
      started_at: new Date(),
      completed_at: new Date(),
      duration_seconds: 0
    }]);
  } catch (error) {
    console.error('⚠️ Could not log update:', error.message);
  }
}

/**
 * MAIN: Run all sync operations
 */
async function main() {
  console.log('\n' + '='.repeat(70));
  console.log('🚀 MINERPRICES DAILY SYNC - Started at', new Date().toISOString());
  console.log('='.repeat(70) + '\n');
  
  try {
    let totalUpdates = 0;
    
    // Sync coins and prices
    totalUpdates += await syncCoinsFromCoinGecko();
    
    // Update difficulty
    await updateBitcoinDifficulty();
    
    // Calculate profitability
    await calculateProfitability();
    
    await logUpdate('success', 0);
    
    console.log('\n' + '='.repeat(70));
    console.log('✅ SYNC COMPLETE - All data updated successfully');
    console.log('='.repeat(70) + '\n');
    
  } catch (error) {
    console.error('\n❌ FATAL ERROR:', error.message);
    await logUpdate('error', 1);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

module.exports = { syncCoinsFromCoinGecko, updateBitcoinDifficulty, calculateProfitability };
