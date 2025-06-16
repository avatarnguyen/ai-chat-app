-- =====================================================
-- AI Chat App - User Management Functions
-- =====================================================
-- This migration adds database functions for user management,
-- usage tracking, and authentication-related operations.

-- =====================================================
-- FUNCTION: Create User Profile
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (
        user_id,
        display_name,
        created_at,
        updated_at,
        last_active_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        NOW(),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.create_user_profile();

-- =====================================================
-- FUNCTION: Update User Profile Timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_user_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically update updated_at timestamp
DROP TRIGGER IF EXISTS on_user_profile_updated ON public.user_profiles;
CREATE TRIGGER on_user_profile_updated
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_user_profile_updated_at();

-- =====================================================
-- FUNCTION: Increment Message Count
-- =====================================================

CREATE OR REPLACE FUNCTION public.increment_message_count(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles
    SET total_messages_sent = total_messages_sent + 1,
        updated_at = NOW()
    WHERE user_profiles.user_id = increment_message_count.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Add Token Usage
-- =====================================================

CREATE OR REPLACE FUNCTION public.add_token_usage(
    user_id UUID,
    tokens INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles
    SET total_tokens_used = total_tokens_used + tokens,
        updated_at = NOW()
    WHERE user_profiles.user_id = add_token_usage.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Update Last Active
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_last_active(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles
    SET last_active_at = NOW(),
        updated_at = NOW()
    WHERE user_profiles.user_id = update_last_active.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Get User Usage Stats
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_user_usage_stats(user_id UUID)
RETURNS TABLE (
    total_messages_sent INTEGER,
    total_tokens_used BIGINT,
    monthly_message_limit INTEGER,
    subscription_tier TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    last_active_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        up.total_messages_sent,
        up.total_tokens_used,
        up.monthly_message_limit,
        up.subscription_tier::TEXT,
        up.created_at,
        up.last_active_at
    FROM public.user_profiles up
    WHERE up.user_id = get_user_usage_stats.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Check Message Limit
-- =====================================================

CREATE OR REPLACE FUNCTION public.check_message_limit(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_count INTEGER;
    message_limit INTEGER;
    tier TEXT;
BEGIN
    SELECT
        total_messages_sent,
        monthly_message_limit,
        subscription_tier::TEXT
    INTO current_count, message_limit, tier
    FROM public.user_profiles
    WHERE user_profiles.user_id = check_message_limit.user_id;

    -- Enterprise tier has unlimited messages
    IF tier = 'enterprise' THEN
        RETURN FALSE;
    END IF;

    -- Check if user has reached their limit
    RETURN current_count >= message_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Reset Monthly Usage
-- =====================================================

CREATE OR REPLACE FUNCTION public.reset_monthly_usage()
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles
    SET total_messages_sent = 0,
        total_tokens_used = 0,
        updated_at = NOW()
    WHERE subscription_tier != 'enterprise'; -- Don't reset enterprise users
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Update Subscription Tier
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_subscription_tier(
    user_id UUID,
    new_tier TEXT
)
RETURNS VOID AS $$
DECLARE
    new_limit INTEGER;
BEGIN
    -- Set appropriate message limit based on tier
    CASE new_tier
        WHEN 'free' THEN new_limit := 100;
        WHEN 'pro' THEN new_limit := 1000;
        WHEN 'enterprise' THEN new_limit := -1; -- Unlimited
        ELSE RAISE EXCEPTION 'Invalid subscription tier: %', new_tier;
    END CASE;

    UPDATE public.user_profiles
    SET subscription_tier = new_tier::subscription_tier,
        monthly_message_limit = new_limit,
        updated_at = NOW()
    WHERE user_profiles.user_id = update_subscription_tier.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Get User Profile with Auth Data
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_user_profile_with_auth(user_id UUID)
RETURNS TABLE (
    id UUID,
    email TEXT,
    email_confirmed_at TIMESTAMP WITH TIME ZONE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    preferred_model TEXT,
    theme_preference TEXT,
    language_preference TEXT,
    subscription_tier TEXT,
    total_messages_sent INTEGER,
    total_tokens_used BIGINT,
    monthly_message_limit INTEGER,
    is_onboarding_completed BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    last_active_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        au.id,
        au.email,
        au.email_confirmed_at,
        up.display_name,
        up.avatar_url,
        up.bio,
        up.preferred_model,
        up.theme_preference,
        up.language_preference,
        up.subscription_tier::TEXT,
        up.total_messages_sent,
        up.total_tokens_used,
        up.monthly_message_limit,
        up.is_onboarding_completed,
        up.created_at,
        up.updated_at,
        up.last_active_at
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.user_id
    WHERE au.id = get_user_profile_with_auth.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Delete User Data
-- =====================================================

CREATE OR REPLACE FUNCTION public.delete_user_data(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Delete in order to respect foreign key constraints
    DELETE FROM public.messages WHERE conversation_id IN (
        SELECT id FROM public.conversations WHERE conversations.user_id = delete_user_data.user_id
    );

    DELETE FROM public.conversations WHERE conversations.user_id = delete_user_data.user_id;
    DELETE FROM public.folders WHERE folders.user_id = delete_user_data.user_id;
    DELETE FROM public.api_keys WHERE api_keys.user_id = delete_user_data.user_id;
    DELETE FROM public.conversation_exports WHERE conversation_exports.user_id = delete_user_data.user_id;
    DELETE FROM public.conversation_templates WHERE conversation_templates.user_id = delete_user_data.user_id;
    DELETE FROM public.user_profiles WHERE user_profiles.user_id = delete_user_data.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Clean Up Inactive Users
-- =====================================================

CREATE OR REPLACE FUNCTION public.cleanup_inactive_users()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    user_record RECORD;
BEGIN
    -- Find users inactive for more than 1 year with free tier
    FOR user_record IN
        SELECT user_id
        FROM public.user_profiles
        WHERE subscription_tier = 'free'
        AND last_active_at < NOW() - INTERVAL '1 year'
        AND total_messages_sent = 0
    LOOP
        -- Delete user data
        PERFORM public.delete_user_data(user_record.user_id);
        deleted_count := deleted_count + 1;
    END LOOP;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNCTION: Update Message Statistics
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_message_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update conversation message count and last message timestamp
    UPDATE public.conversations
    SET message_count = (
        SELECT COUNT(*)
        FROM public.messages
        WHERE conversation_id = NEW.conversation_id
        AND is_deleted = FALSE
    ),
    last_message_at = NOW(),
    updated_at = NOW()
    WHERE id = NEW.conversation_id;

    -- Update user message count
    PERFORM public.increment_message_count(
        (SELECT user_id FROM public.conversations WHERE id = NEW.conversation_id)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to update statistics when messages are inserted
DROP TRIGGER IF EXISTS on_message_inserted ON public.messages;
CREATE TRIGGER on_message_inserted
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_message_statistics();

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Index for user profile lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_tier ON public.user_profiles(subscription_tier);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active ON public.user_profiles(last_active_at);

-- Index for message statistics
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- Index for conversation lookups
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON public.conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations(last_message_at);

-- =====================================================
-- GRANTS AND PERMISSIONS
-- =====================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.increment_message_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_token_usage(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_last_active(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_usage_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_message_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile_with_auth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_data(UUID) TO authenticated;

-- Grant execute permissions to service role for admin functions
GRANT EXECUTE ON FUNCTION public.reset_monthly_usage() TO service_role;
GRANT EXECUTE ON FUNCTION public.update_subscription_tier(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_inactive_users() TO service_role;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION public.create_user_profile() IS 'Automatically creates a user profile when a new user signs up';
COMMENT ON FUNCTION public.increment_message_count(UUID) IS 'Increments the message count for a user';
COMMENT ON FUNCTION public.add_token_usage(UUID, INTEGER) IS 'Adds token usage to a user''s counter';
COMMENT ON FUNCTION public.update_last_active(UUID) IS 'Updates the last active timestamp for a user';
COMMENT ON FUNCTION public.get_user_usage_stats(UUID) IS 'Returns usage statistics for a user';
COMMENT ON FUNCTION public.check_message_limit(UUID) IS 'Checks if a user has reached their message limit';
COMMENT ON FUNCTION public.update_subscription_tier(UUID, TEXT) IS 'Updates a user''s subscription tier and message limit';
COMMENT ON FUNCTION public.get_user_profile_with_auth(UUID) IS 'Returns user profile with auth data';
COMMENT ON FUNCTION public.delete_user_data(UUID) IS 'Deletes all data associated with a user';
COMMENT ON FUNCTION public.cleanup_inactive_users() IS 'Cleans up inactive free tier users';
COMMENT ON FUNCTION public.reset_monthly_usage() IS 'Resets monthly usage counters for all users';
