-- =====================================================
-- Fix Missing User Profile Columns
-- =====================================================
-- This migration adds the missing is_onboarding_completed column
-- to the user_profiles table that is referenced in the functions
-- but was not included in the initial schema.

-- Add missing column to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS is_onboarding_completed BOOLEAN DEFAULT FALSE;

-- Update existing users to have completed onboarding by default
UPDATE public.user_profiles
SET is_onboarding_completed = TRUE
WHERE is_onboarding_completed IS NULL;

-- Add comment to document the column
COMMENT ON COLUMN public.user_profiles.is_onboarding_completed IS 'Tracks whether the user has completed the initial onboarding process';
