-- ============================================================================
-- MINERPRICES ENHANCED DATABASE SCHEMA V2
-- Professional Mining Marketplace with Vendors, Hosters, Advanced Features
-- ============================================================================

-- ============================================================================
-- 1. CORE REFERENCE TABLES
-- ============================================================================

-- Algorithms (SHA256, Scrypt, Equihash, etc.)
CREATE TABLE IF NOT EXISTS algorithms (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    difficulty_unit VARCHAR(50),
    block_time_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cryptocurrencies/Coins
CREATE TABLE IF NOT EXISTS coins (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    algorithm_id BIGINT REFERENCES algorithms(id),
    description TEXT,
    logo_url TEXT,
    logo_auto_update BOOLEAN DEFAULT TRUE,
    current_price DECIMAL(20,8),
    price_change_24h DECIMAL(10,4),
    market_cap BIGINT,
    volume_24h BIGINT,
    difficulty DECIMAL(20,8),
    network_hashrate BIGINT,
    block_reward DECIMAL(20,8),
    halving_date DATE,
    priority INTEGER DEFAULT 0,
    visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_coins_algorithm ON coins(algorithm_id);
CREATE INDEX idx_coins_symbol ON coins(symbol);
CREATE INDEX idx_coins_visible ON coins(visible);

-- ============================================================================
-- 2. MINERS (PRODUCTS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS miners (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,
    algorithm_id BIGINT REFERENCES algorithms(id),
    primary_coin_id BIGINT REFERENCES coins(id),
    
    -- Specifications
    hashrate BIGINT,
    hashrate_unit VARCHAR(20),
    power_consumption INTEGER,
    efficiency DECIMAL(10,4),
    noise_level INTEGER,
    weight DECIMAL(10,2),
    dimensions JSONB,
    
    -- Pricing & Availability
    average_price DECIMAL(15,4),
    min_price DECIMAL(15,4),
    max_price DECIMAL(15,4),
    last_price_update TIMESTAMP WITH TIME ZONE,
    
    -- Links & Resources
    tutorial_video_url TEXT,
    firmware_url TEXT,
    documentation_url TEXT,
    support_app_1_url TEXT,
    support_app_2_url TEXT,
    funny_video_url TEXT,
    
    -- Images
    featured_image_url TEXT,
    
    -- Admin Notes
    admin_notes TEXT,
    
    -- Status
    featured BOOLEAN DEFAULT FALSE,
    active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_miners_algorithm ON miners(algorithm_id);
CREATE INDEX idx_miners_slug ON miners(slug);
CREATE INDEX idx_miners_featured ON miners(featured);

-- Miner Images (multiple per miner)
CREATE TABLE IF NOT EXISTS miner_images (
    id BIGSERIAL PRIMARY KEY,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(miner_id, image_url)
);

CREATE INDEX idx_miner_images_miner ON miner_images(miner_id);

-- Miner to Coin Mapping (many-to-many)
CREATE TABLE IF NOT EXISTS miner_coins (
    id BIGSERIAL PRIMARY KEY,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    coin_id BIGINT NOT NULL REFERENCES coins(id) ON DELETE CASCADE,
    primary_coin BOOLEAN DEFAULT FALSE,
    hashrate_for_coin BIGINT,
    power_consumption_for_coin INTEGER,
    coins_per_day DECIMAL(20,8),
    daily_profit_estimate DECIMAL(15,4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(miner_id, coin_id)
);

CREATE INDEX idx_miner_coins_miner ON miner_coins(miner_id);
CREATE INDEX idx_miner_coins_coin ON miner_coins(coin_id);

-- Price History (daily snapshots)
CREATE TABLE IF NOT EXISTS miner_price_history (
    id BIGSERIAL PRIMARY KEY,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    average_price DECIMAL(15,4),
    min_price DECIMAL(15,4),
    max_price DECIMAL(15,4),
    price_count INTEGER,
    source VARCHAR(50),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(miner_id, date)
);

CREATE INDEX idx_price_history_miner_date ON miner_price_history(miner_id, date DESC);

-- Difficulty History (daily snapshots)
CREATE TABLE IF NOT EXISTS coin_difficulty_history (
    id BIGSERIAL PRIMARY KEY,
    coin_id BIGINT NOT NULL REFERENCES coins(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    difficulty DECIMAL(20,8),
    network_hashrate BIGINT,
    block_time_seconds INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(coin_id, date)
);

CREATE INDEX idx_difficulty_history_coin_date ON coin_difficulty_history(coin_id, date DESC);

-- ============================================================================
-- 3. VENDORS (SELLERS)
-- ============================================================================

CREATE TYPE vendor_status AS ENUM (
    'pending_approval',
    'approved',
    'silver',
    'gold',
    'suspended',
    'banned'
);

CREATE TABLE IF NOT EXISTS vendors (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    slug VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    country VARCHAR(100),
    website_url TEXT,
    logo_url TEXT,
    description TEXT,
    landing_page_html TEXT,
    
    -- Status & Level
    status vendor_status DEFAULT 'pending_approval',
    priority INTEGER DEFAULT 0,
    featured BOOLEAN DEFAULT FALSE,
    
    -- Contact
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    
    -- Metadata
    total_listings INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vendors_slug ON vendors(slug);
CREATE INDEX idx_vendors_status ON vendors(status);
CREATE INDEX idx_vendors_country ON vendors(country);
CREATE INDEX idx_vendors_featured ON vendors(featured);

-- Vendor Photos (gallery)
CREATE TABLE IF NOT EXISTS vendor_photos (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    caption VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vendor_photos_vendor ON vendor_photos(vendor_id);

-- Vendor Warehouses (up to 3)
CREATE TABLE IF NOT EXISTS vendor_warehouses (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    name VARCHAR(255),
    address TEXT NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    capacity_units INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, address)
);

CREATE INDEX idx_vendor_warehouses_vendor ON vendor_warehouses(vendor_id);

-- Vendor Listings (price per miner per vendor)
CREATE TABLE IF NOT EXISTS vendor_listings (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    
    -- Pricing
    purchase_price DECIMAL(15,4) NOT NULL,
    shipping_cost DECIMAL(15,4) DEFAULT 0,
    total_price DECIMAL(15,4) GENERATED ALWAYS AS (purchase_price + shipping_cost) STORED,
    
    -- Stock
    quantity_available INTEGER DEFAULT 0,
    quantity_reserved INTEGER DEFAULT 0,
    quantity_sold INTEGER DEFAULT 0,
    
    -- Shipping
    ships_to JSONB DEFAULT '[]'::jsonb,
    shipping_time_days INTEGER,
    warranty_months INTEGER DEFAULT 0,
    
    -- Links
    shop_url TEXT,
    affiliate_url TEXT,
    
    -- Status
    in_stock BOOLEAN DEFAULT FALSE,
    pre_order BOOLEAN DEFAULT FALSE,
    pre_order_date DATE,
    active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, miner_id)
);

CREATE INDEX idx_vendor_listings_vendor ON vendor_listings(vendor_id);
CREATE INDEX idx_vendor_listings_miner ON vendor_listings(miner_id);
CREATE INDEX idx_vendor_listings_active ON vendor_listings(active);
CREATE INDEX idx_vendor_listings_price ON vendor_listings(total_price);

-- ============================================================================
-- 4. HOSTING CENTERS
-- ============================================================================

CREATE TYPE hoster_status AS ENUM (
    'pending_approval',
    'approved',
    'silver',
    'gold',
    'suspended',
    'banned'
);

CREATE TYPE cooling_type AS ENUM (
    'air',
    'hydro',
    'immersion',
    'other'
);

CREATE TABLE IF NOT EXISTS hosters (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    slug VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    website_url TEXT,
    logo_url TEXT,
    description TEXT,
    
    status hoster_status DEFAULT 'pending_approval',
    priority INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_hosters_slug ON hosters(slug);
CREATE INDEX idx_hosters_status ON hosters(status);
CREATE INDEX idx_hosters_verified ON hosters(verified);

-- Hosting Centers (actual facilities)
CREATE TABLE IF NOT EXISTS hosting_centers (
    id BIGSERIAL PRIMARY KEY,
    hoster_id BIGINT NOT NULL REFERENCES hosters(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Location
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    address TEXT,
    
    -- Technical Specs
    cooling_type cooling_type,
    electricity_source VARCHAR(100),
    uptime_percentage DECIMAL(5,2),
    guaranteed_uptime DECIMAL(5,2),
    
    -- Capacity
    capacity_kw DECIMAL(12,2),
    miner_slots INTEGER,
    
    -- Pricing
    price_per_kw_monthly DECIMAL(12,4),
    installation_per_kw DECIMAL(12,4),
    installation_per_miner DECIMAL(12,4),
    pool_fee_percentage DECIMAL(5,2),
    extra_fees JSONB DEFAULT '{}'::jsonb,
    
    -- Features
    supported_coins JSONB DEFAULT '[]'::jsonb,
    preferred_brands JSONB DEFAULT '[]'::jsonb,
    ownership_structure VARCHAR(100),
    warranty_months INTEGER,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    featured BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_hosting_centers_hoster ON hosting_centers(hoster_id);
CREATE INDEX idx_hosting_centers_country ON hosting_centers(country);
CREATE INDEX idx_hosting_centers_active ON hosting_centers(active);
CREATE INDEX idx_hosting_centers_coords ON hosting_centers(latitude, longitude);

-- ============================================================================
-- 5. ADMIN & MODERATION
-- ============================================================================

CREATE TYPE admin_action AS ENUM (
    'vendor_approved',
    'vendor_suspended',
    'vendor_banned',
    'vendor_level_changed',
    'miner_edited',
    'miner_deleted',
    'coin_added',
    'coin_visibility_changed',
    'hosting_center_approved',
    'message_sent',
    'price_deleted',
    'other'
);

CREATE TABLE IF NOT EXISTS admin_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id VARCHAR(255),
    action admin_action,
    target_type VARCHAR(50),
    target_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_admin_logs_target ON admin_logs(target_type, target_id);
CREATE INDEX idx_admin_logs_action ON admin_logs(action);
CREATE INDEX idx_admin_logs_date ON admin_logs(created_at DESC);

-- Messages from Admin to Vendor
CREATE TABLE IF NOT EXISTS vendor_messages (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    admin_id VARCHAR(255),
    subject VARCHAR(255),
    message TEXT NOT NULL,
    email_sent BOOLEAN DEFAULT FALSE,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_vendor_messages_vendor ON vendor_messages(vendor_id);
CREATE INDEX idx_vendor_messages_read ON vendor_messages(read);

-- ============================================================================
-- 6. USER FEATURES
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_portfolios (
    id BIGSERIAL PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    hosting_center_id BIGINT REFERENCES hosting_centers(id),
    purchase_price DECIMAL(15,4),
    purchase_date DATE,
    expected_daily_profit DECIMAL(15,4),
    last_calculated TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_email, miner_id)
);

CREATE INDEX idx_user_portfolios_email ON user_portfolios(user_email);

-- ============================================================================
-- 7. REVIEWS & RATINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS vendor_reviews (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    reviewer_email VARCHAR(255),
    reviewer_name VARCHAR(255),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    content TEXT,
    verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    unhelpful_count INTEGER DEFAULT 0,
    approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vendor_reviews_vendor ON vendor_reviews(vendor_id);
CREATE INDEX idx_vendor_reviews_approved ON vendor_reviews(approved);

CREATE TABLE IF NOT EXISTS hosting_center_reviews (
    id BIGSERIAL PRIMARY KEY,
    hosting_center_id BIGINT NOT NULL REFERENCES hosting_centers(id) ON DELETE CASCADE,
    reviewer_email VARCHAR(255),
    reviewer_name VARCHAR(255),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    content TEXT,
    helpful_count INTEGER DEFAULT 0,
    unhelpful_count INTEGER DEFAULT 0,
    approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_hosting_reviews_center ON hosting_center_reviews(hosting_center_id);

-- ============================================================================
-- 8. PROFITABILITY CALCULATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS profitability_snapshots (
    id BIGSERIAL PRIMARY KEY,
    miner_id BIGINT NOT NULL REFERENCES miners(id) ON DELETE CASCADE,
    coin_id BIGINT NOT NULL REFERENCES coins(id) ON DELETE CASCADE,
    
    daily_profit DECIMAL(15,4),
    weekly_profit DECIMAL(15,4),
    monthly_profit DECIMAL(15,4),
    yearly_profit DECIMAL(15,4),
    roi_percentage DECIMAL(10,2),
    
    difficulty DECIMAL(20,8),
    network_hashrate BIGINT,
    coin_price DECIMAL(20,8),
    miner_price DECIMAL(15,4),
    
    date DATE NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(miner_id, coin_id, date)
);

CREATE INDEX idx_profitability_miner_date ON profitability_snapshots(miner_id, date DESC);

-- ============================================================================
-- 9. SYSTEM TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS update_logs (
    id BIGSERIAL PRIMARY KEY,
    update_type VARCHAR(50),
    status VARCHAR(50),
    miners_updated INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    errors_count INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER
);

CREATE INDEX idx_update_logs_type ON update_logs(update_type);
CREATE INDEX idx_update_logs_date ON update_logs(started_at DESC);

-- ============================================================================
-- 10. FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update modified timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update vendor rating
CREATE OR REPLACE FUNCTION update_vendor_rating(vendor_id BIGINT)
RETURNS void AS $$
BEGIN
    UPDATE vendors
    SET average_rating = COALESCE((
        SELECT AVG(rating) FROM vendor_reviews 
        WHERE vendor_reviews.vendor_id = vendor_id AND approved = TRUE
    ), 0),
    total_reviews = (
        SELECT COUNT(*) FROM vendor_reviews 
        WHERE vendor_reviews.vendor_id = vendor_id AND approved = TRUE
    )
    WHERE vendors.id = vendor_id;
END;
$$ LANGUAGE plpgsql;

-- Calculate efficiency
CREATE OR REPLACE FUNCTION calculate_efficiency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.power_consumption > 0 THEN
        NEW.efficiency = ROUND((NEW.power_consumption::DECIMAL / NEW.hashrate::DECIMAL) * 1000000, 4);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER update_miners_modified BEFORE UPDATE ON miners
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_vendors_modified BEFORE UPDATE ON vendors
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_vendors_listings_modified BEFORE UPDATE ON vendor_listings
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER calculate_miner_efficiency BEFORE INSERT OR UPDATE ON miners
    FOR EACH ROW EXECUTE FUNCTION calculate_efficiency();

-- ============================================================================
-- DATABASE SCHEMA COMPLETE
-- Ready for deployment to Supabase
-- ============================================================================
