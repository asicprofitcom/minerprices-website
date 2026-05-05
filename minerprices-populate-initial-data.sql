-- ============================================================================
-- MINERPRICES - INITIAL DATA POPULATION
-- Add sample algorithms, coins, miners, and vendors
-- ============================================================================

-- ============================================================================
-- 1. INSERT ALGORITHMS
-- ============================================================================

INSERT INTO algorithms (name, description, difficulty_unit, block_time_seconds) VALUES
('SHA256', 'Bitcoin mining algorithm', 'difficulty', 600),
('Scrypt', 'Litecoin mining algorithm', 'difficulty', 150),
('Equihash', 'Zcash mining algorithm', 'difficulty', 150),
('X11', 'Dash mining algorithm', 'difficulty', 150),
('Ethash', 'Ethereum mining algorithm (deprecated after Merge)', 'difficulty', 12),
('RandomX', 'Monero ASIC-resistant algorithm', 'difficulty', 60),
('KawPow', 'Ravencoin mining algorithm', 'difficulty', 60),
('Cuckaroo29', 'Grin mining algorithm', 'difficulty', 60)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. INSERT COINS
-- ============================================================================

INSERT INTO coins (name, symbol, algorithm_id, description, logo_url, priority, visible) VALUES
('Bitcoin', 'BTC', 1, 'The first and most valuable cryptocurrency', 'https://cryptologos.cc/logos/bitcoin-btc-logo.png', 100, true),
('Litecoin', 'LTC', 2, 'Silver to Bitcoin''s gold', 'https://cryptologos.cc/logos/litecoin-ltc-logo.png', 90, true),
('Zcash', 'ZEC', 3, 'Privacy-focused cryptocurrency', 'https://cryptologos.cc/logos/zcash-zec-logo.png', 70, true),
('Dash', 'DASH', 4, 'Digital cash for instant transactions', 'https://cryptologos.cc/logos/dash-dash-logo.png', 60, true),
('Dogecoin', 'DOGE', 2, 'The people''s coin, based on Scrypt', 'https://cryptologos.cc/logos/dogecoin-doge-logo.png', 80, true),
('Monero', 'XMR', 6, 'Private, secure, untraceable cryptocurrency', 'https://cryptologos.cc/logos/monero-xmr-logo.png', 75, true),
('Ravencoin', 'RVN', 7, 'Asset creation and transfer platform', 'https://cryptologos.cc/logos/ravencoin-rvn-logo.png', 65, true),
('Grin', 'GRIN', 8, 'Confidential transactions cryptocurrency', 'https://cryptologos.cc/logos/grin-grin-logo.png', 55, true),
('Bitcoin Cash', 'BCH', 1, 'Bitcoin fork with larger blocks', 'https://cryptologos.cc/logos/bitcoin-cash-bch-logo.png', 85, true),
('Vertcoin', 'VTC', 1, 'GPU-friendly, ASIC-resistant Bitcoin alternative', 'https://cryptologos.cc/logos/vertcoin-vtc-logo.png', 50, true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. INSERT MINERS (Popular ASIC Miners)
-- ============================================================================

INSERT INTO miners (name, slug, description, algorithm_id, primary_coin_id, 
                   hashrate, hashrate_unit, power_consumption, average_price, featured, active) VALUES
('Antminer S23', 'antminer-s23', 'Latest SHA256 ASIC from Bitmain, 150 TH/s', 1, 1, 150000000000, 'TH/s', 3360, 15000, true, true),
('Antminer L7', 'antminer-l7', 'Scrypt ASIC for Litecoin and Dogecoin mining, 9.5 Gh/s', 2, 2, 9500000000, 'GH/s', 3425, 4500, true, true),
('Antminer Z15 Pro', 'antminer-z15-pro', 'Equihash ASIC for Zcash, 420 Sol/s', 3, 3, 420, 'Sol/s', 1800, 3800, true, true),
('Antminer X11', 'antminer-x11', 'X11 ASIC for Dash mining, 280 GH/s', 4, 4, 280000000000, 'GH/s', 1650, 2800, false, true),
('Innosilicon A11 Pro', 'innosilicon-a11-pro', 'Equihash 144,5 ASIC, 62 Sol/s', 3, 3, 62, 'Sol/s', 2400, 4200, true, true),
('Whatsminer M56S', 'whatsminer-m56s', 'SHA256 ASIC, 108 TH/s', 1, 1, 108000000000, 'TH/s', 3094, 12000, false, true),
('Antminer S19k Pro', 'antminer-s19k-pro', 'Older but reliable SHA256, 110 TH/s', 1, 1, 110000000000, 'TH/s', 2975, 9500, false, true),
('Antminer D7', 'antminer-d7', 'X11 ASIC for Dash, 1.286 TH/s', 4, 4, 1286000000000, 'H/s', 2520, 3200, false, true),
('Whatsminer M30S++', 'whatsminer-m30s-plus-plus', 'SHA256 ASIC, 112 TH/s', 1, 1, 112000000000, 'TH/s', 3472, 10500, false, true),
('Antminer S21', 'antminer-s21', 'Next gen SHA256, 200 TH/s (expected)', 1, 1, 200000000000, 'TH/s', 3510, 18000, true, true),
('Antminer S19 Pro', 'antminer-s19-pro', 'Professional SHA256 ASIC, 110 TH/s', 1, 1, 110000000000, 'TH/s', 2700, 8900, false, true),
('AvalonMiner A1246', 'avalon-a1246', 'SHA256 ASIC, 90 TH/s', 1, 1, 90000000000, 'TH/s', 2200, 8000, false, true),
('Innosilicon T4 Ultra', 'innosilicon-t4-ultra', 'SHA256 ASIC, 67 TH/s', 1, 1, 67000000000, 'TH/s', 2400, 6500, false, true),
('Canaan Avalon A1166', 'canaan-avalon-a1166', 'SHA256 ASIC, 81 TH/s', 1, 1, 81000000000, 'TH/s', 2520, 7200, false, true),
('StrongU STU-U6', 'strongu-stu-u6', 'SHA256 ASIC, 96 TH/s', 1, 1, 96000000000, 'TH/s', 3276, 9000, false, true),
('MicroBT Whatsminer M50S', 'whatsminer-m50s', 'SHA256 ASIC, 130 TH/s', 1, 1, 130000000000, 'TH/s', 3472, 13500, false, true),
('Antminer L9', 'antminer-l9', 'Next gen Scrypt, 13 Gh/s (expected)', 2, 2, 13000000000, 'GH/s', 3600, 5200, true, true),
('Antminer Z13 Pro', 'antminer-z13-pro', 'Equihash ASIC, 180 Sol/s', 3, 3, 180, 'Sol/s', 1350, 3500, false, true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. MAP MINERS TO COINS (which coins each miner can mine)
-- ============================================================================

INSERT INTO miner_coins (miner_id, coin_id, primary_coin, hashrate_for_coin) VALUES
-- Antminer S23 (SHA256) - Bitcoin, Bitcoin Cash, Vertcoin
((SELECT id FROM miners WHERE slug = 'antminer-s23'), (SELECT id FROM coins WHERE symbol = 'BTC'), true, 150000000000),
((SELECT id FROM miners WHERE slug = 'antminer-s23'), (SELECT id FROM coins WHERE symbol = 'BCH'), false, 150000000000),
((SELECT id FROM miners WHERE slug = 'antminer-s23'), (SELECT id FROM coins WHERE symbol = 'VTC'), false, 150000000000),

-- Antminer L7 (Scrypt) - Litecoin, Dogecoin
((SELECT id FROM miners WHERE slug = 'antminer-l7'), (SELECT id FROM coins WHERE symbol = 'LTC'), true, 9500000000),
((SELECT id FROM miners WHERE slug = 'antminer-l7'), (SELECT id FROM coins WHERE symbol = 'DOGE'), false, 9500000000),

-- Antminer Z15 Pro (Equihash) - Zcash
((SELECT id FROM miners WHERE slug = 'antminer-z15-pro'), (SELECT id FROM coins WHERE symbol = 'ZEC'), true, 420),

-- Antminer X11 - Dash
((SELECT id FROM miners WHERE slug = 'antminer-x11'), (SELECT id FROM coins WHERE symbol = 'DASH'), true, 280000000000),

-- Innosilicon A11 Pro (Equihash) - Zcash
((SELECT id FROM miners WHERE slug = 'innosilicon-a11-pro'), (SELECT id FROM coins WHERE symbol = 'ZEC'), false, 62),

-- Whatsminer M56S (SHA256) - Bitcoin
((SELECT id FROM miners WHERE slug = 'whatsminer-m56s'), (SELECT id FROM coins WHERE symbol = 'BTC'), true, 108000000000),

-- Antminer S19k Pro (SHA256) - Bitcoin
((SELECT id FROM miners WHERE slug = 'antminer-s19k-pro'), (SELECT id FROM coins WHERE symbol = 'BTC'), true, 110000000000),

-- Antminer S21 (SHA256) - Bitcoin
((SELECT id FROM miners WHERE slug = 'antminer-s21'), (SELECT id FROM coins WHERE symbol = 'BTC'), true, 200000000000)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. INSERT SAMPLE VENDORS
-- ============================================================================

INSERT INTO vendors (name, slug, email, phone, country, website_url, logo_url, description, status, featured, verified) VALUES
('OBE Miners', 'obe-miners', 'contact@obeminers.com', '+1-555-0101', 'United States', 'https://obeminers.com', 'https://obeminers.com/logo.png', 'Leading ASIC miner supplier with competitive pricing and fast shipping', 'approved', true, true),
('Mining Paradise', 'mining-paradise', 'sales@miningparadise.com', '+1-555-0102', 'Canada', 'https://miningparadise.com', 'https://miningparadise.com/logo.png', 'Official Bitmain and Whatsminer distributor in North America', 'approved', true, true),
('Crypto Hardware Hub', 'crypto-hardware-hub', 'support@cryptohw.com', '+44-20-7946-0958', 'United Kingdom', 'https://cryptohw.com', 'https://cryptohw.com/logo.png', 'Premium mining hardware supplier with EU-wide shipping', 'approved', false, true),
('Dragon Miners', 'dragon-miners', 'sales@dragonminers.cn', '+86-10-8000-0000', 'China', 'https://dragonminers.cn', 'https://dragonminers.cn/logo.png', 'Direct from manufacturer - best prices on ASIC miners', 'gold', true, true),
('Miner Direct', 'miner-direct', 'hello@minerdirect.com', '+61-2-9999-9999', 'Australia', 'https://minerdirect.com', 'https://minerdirect.com/logo.png', 'Authorized distributor for major mining hardware brands', 'approved', false, true),
('HashRate Hub', 'hashrate-hub', 'info@hashratehub.com', '+34-91-123-4567', 'Spain', 'https://hashratehub.com', 'https://hashratehub.com/logo.png', 'European mining equipment specialist', 'silver', false, true),
('Startup Vendor', 'startup-vendor', 'new@startupvendor.com', '+1-555-0200', 'United States', 'https://startupvendor.com', NULL, 'New vendor - pending approval', 'pending_approval', false, false)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. INSERT VENDOR LISTINGS (Prices per miner per vendor)
-- ============================================================================

INSERT INTO vendor_listings (vendor_id, miner_id, purchase_price, shipping_cost, quantity_available, in_stock, active) VALUES
-- OBE Miners listings
((SELECT id FROM vendors WHERE slug = 'obe-miners'), (SELECT id FROM miners WHERE slug = 'antminer-s23'), 15000, 200, 5, true, true),
((SELECT id FROM vendors WHERE slug = 'obe-miners'), (SELECT id FROM miners WHERE slug = 'antminer-l7'), 4500, 150, 8, true, true),
((SELECT id FROM vendors WHERE slug = 'obe-miners'), (SELECT id FROM miners WHERE slug = 'antminer-z15-pro'), 3800, 100, 3, true, true),

-- Mining Paradise listings
((SELECT id FROM vendors WHERE slug = 'mining-paradise'), (SELECT id FROM miners WHERE slug = 'antminer-s23'), 14800, 250, 12, true, true),
((SELECT id FROM vendors WHERE slug = 'mining-paradise'), (SELECT id FROM miners WHERE slug = 'whatsminer-m56s'), 11500, 200, 6, true, true),
((SELECT id FROM vendors WHERE slug = 'mining-paradise'), (SELECT id FROM miners WHERE slug = 'antminer-s21'), 18500, 300, 2, true, true),

-- Crypto Hardware Hub listings
((SELECT id FROM vendors WHERE slug = 'crypto-hardware-hub'), (SELECT id FROM miners WHERE slug = 'antminer-s19-pro'), 9200, 180, 4, true, true),
((SELECT id FROM vendors WHERE slug = 'crypto-hardware-hub'), (SELECT id FROM miners WHERE slug = 'antminer-l9'), 5100, 160, 5, true, true),

-- Dragon Miners listings (lowest prices as manufacturer)
((SELECT id FROM vendors WHERE slug = 'dragon-miners'), (SELECT id FROM miners WHERE slug = 'antminer-s23'), 14200, 500, 50, true, true),
((SELECT id FROM vendors WHERE slug = 'dragon-miners'), (SELECT id FROM miners WHERE slug = 'whatsminer-m30s-plus-plus'), 10000, 500, 30, true, true),
((SELECT id FROM vendors WHERE slug = 'dragon-miners'), (SELECT id FROM miners WHERE slug = 'innosilicon-a11-pro'), 4000, 400, 15, true, true),

-- Miner Direct listings
((SELECT id FROM vendors WHERE slug = 'miner-direct'), (SELECT id FROM miners WHERE slug = 'antminer-s19k-pro'), 9800, 250, 3, true, true),
((SELECT id FROM vendors WHERE slug = 'miner-direct'), (SELECT id FROM miners WHERE slug = 'antminer-l7'), 4600, 180, 4, true, true),

-- HashRate Hub listings
((SELECT id FROM vendors WHERE slug = 'hashrate-hub'), (SELECT id FROM miners WHERE slug = 'whatsminer-m56s'), 11800, 220, 2, true, true),
((SELECT id FROM vendors WHERE slug = 'hashrate-hub'), (SELECT id FROM miners WHERE slug = 'antminer-d7'), 3300, 150, 1, false, true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. INSERT SAMPLE HOSTERS (Hosting Centers)
-- ============================================================================

INSERT INTO hosters (name, slug, email, website_url, logo_url, description, status, verified) VALUES
('Genesis Mining', 'genesis-mining', 'support@genesismining.com', 'https://www.genesismining.com', 'https://genesismining.com/logo.png', 'Leading cloud mining provider', 'gold', true),
('Compass', 'compass', 'support@compassmining.com', 'https://www.compassmining.com', 'https://compassmining.com/logo.png', 'Bitcoin mining hosting and management', 'gold', true),
('Riot Blockchain', 'riot-blockchain', 'hosting@riotblockchain.com', 'https://www.riotblockchain.com', 'https://riotblockchain.com/logo.png', 'Large scale mining operation with hosting services', 'gold', true),
('Crypto Facility', 'crypto-facility', 'info@cryptofacility.ch', 'https://cryptofacility.ch', 'https://cryptofacility.ch/logo.png', 'Swiss hosting with renewable energy', 'silver', true),
('Greenidge Generation', 'greenidge-generation', 'hosting@greenidge.com', 'https://greenidge.com', 'https://greenidge.com/logo.png', 'US-based mining with natural gas power', 'approved', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. INSERT HOSTING CENTERS (Actual Facilities)
-- ============================================================================

INSERT INTO hosting_centers (hoster_id, name, description, country, city, cooling_type, electricity_source, uptime_percentage, guaranteed_uptime, capacity_kw, price_per_kw_monthly) VALUES
((SELECT id FROM hosters WHERE slug = 'genesis-mining'), 'Genesis Mining Iceland', 'Premium facility in Iceland with geothermal power', 'Iceland', 'Reykjavik', 'air', 'geothermal', 99.9, 99.5, 5000, 0.05),
((SELECT id FROM hosters WHERE slug = 'compass'), 'Compass Montana', 'Hydro-powered facility in Montana', 'United States', 'Montana', 'hydro', 'hydroelectric', 99.8, 99.0, 10000, 0.04),
((SELECT id FROM hosters WHERE slug = 'riot-blockchain'), 'Riot Texas', 'Large facility in Texas', 'United States', 'Texas', 'air', 'grid', 99.7, 98.5, 8000, 0.055),
((SELECT id FROM hosters WHERE slug = 'crypto-facility'), 'CryptoFacility Zurich', 'State-of-the-art Swiss facility', 'Switzerland', 'Zurich', 'immersion', 'renewable', 99.95, 99.8, 3000, 0.045),
((SELECT id FROM hosters WHERE slug = 'greenidge-generation'), 'Greenidge New York', 'Natural gas powered facility', 'United States', 'New York', 'air', 'natural gas', 99.6, 98.0, 6500, 0.038)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- DONE! Initial data populated
-- ============================================================================

-- Verify data was inserted
SELECT 'Algorithms' as table_name, COUNT(*) as count FROM algorithms
UNION ALL
SELECT 'Coins', COUNT(*) FROM coins
UNION ALL
SELECT 'Miners', COUNT(*) FROM miners
UNION ALL
SELECT 'Miner Coins', COUNT(*) FROM miner_coins
UNION ALL
SELECT 'Vendors', COUNT(*) FROM vendors
UNION ALL
SELECT 'Vendor Listings', COUNT(*) FROM vendor_listings
UNION ALL
SELECT 'Hosters', COUNT(*) FROM hosters
UNION ALL
SELECT 'Hosting Centers', COUNT(*) FROM hosting_centers
ORDER BY table_name;
