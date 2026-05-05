-- ============================================================================
-- VENDOR REGISTRATION & ADMIN APPROVAL SYSTEM
-- Complete workflow for vendor signup, admin approval, and notifications
-- ============================================================================

-- ============================================================================
-- 1. CREATE ADMIN USER TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'admin', -- admin, moderator, support
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, suspended
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_admin_users_username ON admin_users(username);
CREATE INDEX idx_admin_users_email ON admin_users(email);
CREATE INDEX idx_admin_users_status ON admin_users(status);

-- ============================================================================
-- 2. CREATE EMAIL QUEUE TABLE (for email sending system)
-- ============================================================================

CREATE TABLE IF NOT EXISTS email_queue (
    id BIGSERIAL PRIMARY KEY,
    recipient_email VARCHAR(255) NOT NULL,
    recipient_name VARCHAR(255),
    subject VARCHAR(255) NOT NULL,
    email_type VARCHAR(50) NOT NULL, -- vendor_registration, vendor_approved, vendor_rejected, admin_alert
    template_data JSONB, -- {vendor_name, approval_link, admin_name, reason, etc}
    status VARCHAR(50) DEFAULT 'pending', -- pending, sent, failed, retrying
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_email_queue_status ON email_queue(status);
CREATE INDEX idx_email_queue_type ON email_queue(email_type);
CREATE INDEX idx_email_queue_created ON email_queue(created_at DESC);
CREATE INDEX idx_email_queue_recipient ON email_queue(recipient_email);

-- ============================================================================
-- 3. ENHANCE VENDORS TABLE WITH WORKFLOW FIELDS
-- ============================================================================

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS registration_token VARCHAR(255) UNIQUE;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS approved_by BIGINT REFERENCES admin_users(id) ON DELETE SET NULL;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS approval_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS rejected_date TIMESTAMP WITH TIME ZONE;

-- ============================================================================
-- 4. CREATE VENDOR REGISTRATION REQUESTS TABLE (for pending vendors)
-- ============================================================================

CREATE TABLE IF NOT EXISTS vendor_registration_requests (
    id BIGSERIAL PRIMARY KEY,
    
    -- Basic Info
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    contact_phone VARCHAR(20),
    website_url TEXT,
    
    -- Company Details
    country VARCHAR(100) NOT NULL,
    company_description TEXT,
    years_in_business INTEGER,
    num_employees INTEGER,
    
    -- Business Info
    business_type VARCHAR(100), -- distributor, reseller, manufacturer, etc
    main_product_categories JSONB DEFAULT '[]'::jsonb, -- miners, accessories, etc
    
    -- Verification
    company_registration_number VARCHAR(255),
    tax_id VARCHAR(255),
    
    -- Documents
    logo_url TEXT,
    company_photo_url TEXT,
    
    -- Status
    status VARCHAR(50) DEFAULT 'submitted', -- submitted, under_review, approved, rejected, needs_info
    review_notes TEXT,
    reviewed_by BIGINT REFERENCES admin_users(id) ON DELETE SET NULL,
    review_date TIMESTAMP WITH TIME ZONE,
    
    -- Token for email verification
    verification_token VARCHAR(255) UNIQUE,
    email_verified BOOLEAN DEFAULT FALSE,
    verification_sent_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_reg_requests_email ON vendor_registration_requests(contact_email);
CREATE INDEX idx_reg_requests_status ON vendor_registration_requests(status);
CREATE INDEX idx_reg_requests_created ON vendor_registration_requests(created_at DESC);
CREATE INDEX idx_reg_requests_token ON vendor_registration_requests(verification_token);

-- ============================================================================
-- 5. CREATE VENDOR COMMUNICATION LOG (track all messages)
-- ============================================================================

CREATE TABLE IF NOT EXISTS vendor_communication (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    from_vendor BOOLEAN DEFAULT FALSE, -- true if from vendor, false if from admin
    sender_id BIGINT REFERENCES admin_users(id) ON DELETE SET NULL,
    sender_name VARCHAR(255),
    subject VARCHAR(255),
    message TEXT NOT NULL,
    message_type VARCHAR(50), -- email, in_app, notification
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_vendor_comm_vendor ON vendor_communication(vendor_id);
CREATE INDEX idx_vendor_comm_read ON vendor_communication(read);
CREATE INDEX idx_vendor_comm_created ON vendor_communication(created_at DESC);

-- ============================================================================
-- 6. CREATE EMAIL TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS email_templates (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL, -- vendor_registration_confirmation, vendor_approved, etc
    description TEXT,
    subject VARCHAR(255) NOT NULL,
    html_body TEXT NOT NULL,
    plain_text_body TEXT,
    variables JSONB DEFAULT '[]'::jsonb, -- list of variables like {vendor_name}, {approval_link}
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default templates
INSERT INTO email_templates (name, subject, html_body, plain_text_body, variables) VALUES
(
    'vendor_registration_confirmation',
    'Welcome to MinerPrices - Confirm Your Email',
    '<html><body><h2>Welcome to MinerPrices!</h2><p>Thank you for registering as a vendor.</p><p>Click here to verify your email: <a href="{verification_link}">{verification_link}</a></p><p>Or paste this code: {verification_token}</p></body></html>',
    'Welcome to MinerPrices! Click here to verify: {verification_link}',
    '["vendor_name", "verification_link", "verification_token"]'
),
(
    'vendor_approved',
    'Your MinerPrices Vendor Account Has Been Approved!',
    '<html><body><h2>Great News!</h2><p>Your vendor account for {vendor_name} has been approved by our admin team.</p><p>You can now start listing miners:</p><p><a href="{dashboard_link}">Go to Vendor Dashboard</a></p><p>Questions? Contact us at {admin_email}</p></body></html>',
    'Your vendor account has been approved! Go to: {dashboard_link}',
    '["vendor_name", "dashboard_link", "admin_email"]'
),
(
    'vendor_rejected',
    'MinerPrices Vendor Application - Information Needed',
    '<html><body><h2>Your Vendor Application</h2><p>Thank you for applying to MinerPrices.</p><p>We need more information before approval:</p><p>{rejection_reason}</p><p>Please contact us to provide additional details.</p></body></html>',
    'Your vendor application needs more info: {rejection_reason}',
    '["rejection_reason", "admin_email"]'
),
(
    'admin_new_vendor_alert',
    'New Vendor Registration - Approval Needed',
    '<html><body><h2>New Vendor Registration</h2><p>A new vendor has registered: {vendor_name}</p><p>Company: {company_name}</p><p>Email: {contact_email}</p><p><a href="{admin_dashboard_link}">Review Application</a></p></body></html>',
    'New vendor: {vendor_name} - Review: {admin_dashboard_link}',
    '["vendor_name", "company_name", "contact_email", "admin_dashboard_link"]'
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. CREATE FUNCTIONS FOR VENDOR WORKFLOW
-- ============================================================================

-- Generate verification token
CREATE OR REPLACE FUNCTION generate_token()
RETURNS VARCHAR AS $$
SELECT substring(md5(random()::text || clock_timestamp()::text), 1, 32);
$$ LANGUAGE SQL;

-- Create vendor registration request
CREATE OR REPLACE FUNCTION create_vendor_registration(
    p_company_name VARCHAR,
    p_contact_name VARCHAR,
    p_contact_email VARCHAR,
    p_contact_phone VARCHAR,
    p_website_url TEXT,
    p_country VARCHAR,
    p_company_description TEXT
)
RETURNS TABLE (
    registration_id BIGINT,
    verification_token VARCHAR,
    status VARCHAR
) AS $$
DECLARE
    v_token VARCHAR;
    v_id BIGINT;
BEGIN
    v_token := generate_token();
    
    INSERT INTO vendor_registration_requests (
        company_name, contact_name, contact_email, contact_phone,
        website_url, country, company_description, verification_token
    ) VALUES (
        p_company_name, p_contact_name, p_contact_email, p_contact_phone,
        p_website_url, p_country, p_company_description, v_token
    )
    RETURNING id INTO v_id;
    
    -- Queue welcome email
    INSERT INTO email_queue (
        recipient_email, recipient_name, subject, email_type,
        template_data
    ) VALUES (
        p_contact_email,
        p_contact_name,
        'Welcome to MinerPrices - Confirm Your Email',
        'vendor_registration_confirmation',
        jsonb_build_object(
            'vendor_name', p_company_name,
            'verification_link', 'https://minerprices.com/verify?token=' || v_token,
            'verification_token', v_token
        )
    );
    
    -- Alert admin
    INSERT INTO email_queue (
        recipient_email, subject, email_type, template_data
    ) VALUES (
        'admin@minerprices.com',
        'New Vendor Registration - Approval Needed',
        'admin_new_vendor_alert',
        jsonb_build_object(
            'vendor_name', p_company_name,
            'company_name', p_company_name,
            'contact_email', p_contact_email,
            'admin_dashboard_link', 'https://minerprices.com/admin/vendors'
        )
    );
    
    RETURN QUERY SELECT v_id, v_token, 'submitted'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Approve vendor registration
CREATE OR REPLACE FUNCTION approve_vendor_registration(
    p_reg_id BIGINT,
    p_admin_id BIGINT,
    p_initial_status vendor_status DEFAULT 'approved'
)
RETURNS TABLE (vendor_id BIGINT, status VARCHAR) AS $$
DECLARE
    v_vendor_id BIGINT;
    v_contact_email VARCHAR;
    v_company_name VARCHAR;
BEGIN
    -- Get registration details
    SELECT contact_email, company_name INTO v_contact_email, v_company_name
    FROM vendor_registration_requests
    WHERE id = p_reg_id;
    
    -- Create vendor in vendors table
    INSERT INTO vendors (
        name, slug, email, status, verified, registration_token,
        approved_by, approval_date
    ) SELECT
        company_name,
        lower(regexp_replace(company_name, '[^a-z0-9]+', '-', 'g')),
        contact_email,
        p_initial_status,
        true,
        verification_token,
        p_admin_id,
        NOW()
    FROM vendor_registration_requests
    WHERE id = p_reg_id
    RETURNING vendors.id INTO v_vendor_id;
    
    -- Mark registration as approved
    UPDATE vendor_registration_requests
    SET status = 'approved', reviewed_by = p_admin_id, review_date = NOW()
    WHERE id = p_reg_id;
    
    -- Queue approval email
    INSERT INTO email_queue (
        recipient_email, recipient_name, subject, email_type, template_data
    ) VALUES (
        v_contact_email,
        v_company_name,
        'Your MinerPrices Vendor Account Has Been Approved!',
        'vendor_approved',
        jsonb_build_object(
            'vendor_name', v_company_name,
            'dashboard_link', 'https://minerprices.com/vendor/dashboard',
            'admin_email', 'admin@minerprices.com'
        )
    );
    
    RETURN QUERY SELECT v_vendor_id, p_initial_status::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- Reject vendor registration
CREATE OR REPLACE FUNCTION reject_vendor_registration(
    p_reg_id BIGINT,
    p_admin_id BIGINT,
    p_reason TEXT
)
RETURNS TABLE (status VARCHAR, message TEXT) AS $$
DECLARE
    v_contact_email VARCHAR;
    v_company_name VARCHAR;
BEGIN
    -- Get registration details
    SELECT contact_email, company_name INTO v_contact_email, v_company_name
    FROM vendor_registration_requests
    WHERE id = p_reg_id;
    
    -- Update registration
    UPDATE vendor_registration_requests
    SET status = 'rejected',
        review_notes = p_reason,
        reviewed_by = p_admin_id,
        review_date = NOW()
    WHERE id = p_reg_id;
    
    -- Queue rejection email
    INSERT INTO email_queue (
        recipient_email, recipient_name, subject, email_type, template_data
    ) VALUES (
        v_contact_email,
        v_company_name,
        'MinerPrices Vendor Application - Information Needed',
        'vendor_rejected',
        jsonb_build_object(
            'rejection_reason', p_reason,
            'admin_email', 'admin@minerprices.com'
        )
    );
    
    RETURN QUERY SELECT 'rejected'::VARCHAR, 'Rejection email queued'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. INSERT DEFAULT ADMIN USER
-- ============================================================================

-- Default admin credentials (CHANGE THESE IN PRODUCTION!)
INSERT INTO admin_users (username, email, password_hash, full_name, role, status)
VALUES (
    'admin',
    'admin@minerprices.com',
    -- Password: admin123 (DO NOT USE IN PRODUCTION!)
    -- This is bcrypt hash: $2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36gZvWFm
    '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36gZvWFm',
    'System Administrator',
    'admin',
    'active'
)
ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- 9. CREATE VENDOR DASHBOARD VIEW
-- ============================================================================

CREATE OR REPLACE VIEW vendor_dashboard_summary AS
SELECT
    v.id,
    v.name,
    v.email,
    v.status,
    v.verified,
    COUNT(vl.id) as total_listings,
    COUNT(DISTINCT vl.miner_id) as unique_miners,
    COALESCE(AVG(vr.rating), 0) as average_rating,
    COUNT(DISTINCT vr.id) as total_reviews,
    (SELECT COUNT(*) FROM vendor_messages WHERE vendor_id = v.id AND read = false) as unread_messages,
    MAX(vl.updated_at) as last_listing_update,
    v.created_at as registered_date
FROM vendors v
LEFT JOIN vendor_listings vl ON v.id = vl.vendor_id
LEFT JOIN vendor_reviews vr ON v.id = vr.vendor_id
GROUP BY v.id, v.name, v.email, v.status, v.verified, v.created_at;

-- ============================================================================
-- DONE!
-- ============================================================================

-- Verify tables created
SELECT 'Admin Users' as table_name, COUNT(*) as count FROM admin_users
UNION ALL
SELECT 'Email Queue', COUNT(*) FROM email_queue
UNION ALL
SELECT 'Vendor Registration Requests', COUNT(*) FROM vendor_registration_requests
UNION ALL
SELECT 'Vendor Communication', COUNT(*) FROM vendor_communication
UNION ALL
SELECT 'Email Templates', COUNT(*) FROM email_templates
ORDER BY table_name;
