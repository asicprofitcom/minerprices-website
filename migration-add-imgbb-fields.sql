-- Migration: Add imgbb integration fields to miner_images table
-- This allows storing imgbb delete URLs and image sourcing info

ALTER TABLE miner_images 
ADD COLUMN IF NOT EXISTS delete_url TEXT,
ADD COLUMN IF NOT EXISTS image_source VARCHAR(50) DEFAULT 'imgbb',
ADD COLUMN IF NOT EXISTS imgbb_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS uploaded_by VARCHAR(255);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_miner_images_imgbb_id ON miner_images(imgbb_id);

-- Add comment for clarity
COMMENT ON COLUMN miner_images.delete_url IS 'imgbb delete URL for managing image deletion';
COMMENT ON COLUMN miner_images.image_source IS 'Source of image: imgbb, local, or external';
COMMENT ON COLUMN miner_images.imgbb_id IS 'imgbb image ID for reference';
