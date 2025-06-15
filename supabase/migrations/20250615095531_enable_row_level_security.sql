-- =====================================================
-- AI Chat App - Row Level Security (RLS) Policies
-- =====================================================
-- This migration enables Row Level Security on all tables and creates
-- comprehensive policies to ensure users can only access their own data.

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

-- Enable RLS on all user data tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_templates ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USER PROFILES POLICIES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own profile (handled by trigger, but needed for flexibility)
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users cannot delete their profile (handled by auth.users cascade)
-- No DELETE policy needed as profiles are deleted when user is deleted

-- =====================================================
-- FOLDERS POLICIES
-- =====================================================

-- Users can view their own folders
CREATE POLICY "Users can view own folders" ON public.folders
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert folders for themselves
CREATE POLICY "Users can insert own folders" ON public.folders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own folders
CREATE POLICY "Users can update own folders" ON public.folders
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can delete their own folders
CREATE POLICY "Users can delete own folders" ON public.folders
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- CONVERSATIONS POLICIES
-- =====================================================

-- Users can view their own conversations
CREATE POLICY "Users can view own conversations" ON public.conversations
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert conversations for themselves
CREATE POLICY "Users can insert own conversations" ON public.conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own conversations
CREATE POLICY "Users can update own conversations" ON public.conversations
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can delete their own conversations
CREATE POLICY "Users can delete own conversations" ON public.conversations
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Users can view messages from their own conversations
CREATE POLICY "Users can view own messages" ON public.messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- Users can insert messages into their own conversations
CREATE POLICY "Users can insert own messages" ON public.messages
    FOR INSERT WITH CHECK (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- Users can update messages in their own conversations
CREATE POLICY "Users can update own messages" ON public.messages
    FOR UPDATE USING (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    ) WITH CHECK (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- Users can delete messages from their own conversations
CREATE POLICY "Users can delete own messages" ON public.messages
    FOR DELETE USING (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- API KEYS POLICIES
-- =====================================================

-- Users can view their own API keys
CREATE POLICY "Users can view own api keys" ON public.api_keys
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own API keys
CREATE POLICY "Users can insert own api keys" ON public.api_keys
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own API keys
CREATE POLICY "Users can update own api keys" ON public.api_keys
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can delete their own API keys
CREATE POLICY "Users can delete own api keys" ON public.api_keys
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- CONVERSATION EXPORTS POLICIES
-- =====================================================

-- Users can view their own exports
CREATE POLICY "Users can view own exports" ON public.conversation_exports
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create export requests for their own conversations
CREATE POLICY "Users can insert own exports" ON public.conversation_exports
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        (conversation_id IS NULL OR conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        ))
    );

-- Users can update their own export requests
CREATE POLICY "Users can update own exports" ON public.conversation_exports
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can delete their own export requests
CREATE POLICY "Users can delete own exports" ON public.conversation_exports
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- CONVERSATION TEMPLATES POLICIES
-- =====================================================

-- Users can view their own templates and public templates
CREATE POLICY "Users can view templates" ON public.conversation_templates
    FOR SELECT USING (
        auth.uid() = user_id OR is_public = true
    );

-- Users can insert their own templates
CREATE POLICY "Users can insert own templates" ON public.conversation_templates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own templates
CREATE POLICY "Users can update own templates" ON public.conversation_templates
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can delete their own templates
CREATE POLICY "Users can delete own templates" ON public.conversation_templates
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- SPECIAL POLICIES FOR SYSTEM OPERATIONS
-- =====================================================

-- Service role can bypass RLS for admin operations
-- This allows backend services to perform maintenance tasks

-- Allow service role to manage user profiles for system operations
CREATE POLICY "Service role can manage user profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- Allow service role to manage all data for system operations
CREATE POLICY "Service role can manage folders" ON public.folders
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage conversations" ON public.conversations
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage messages" ON public.messages
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage api keys" ON public.api_keys
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage exports" ON public.conversation_exports
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage templates" ON public.conversation_templates
    FOR ALL USING (auth.role() = 'service_role');

-- =====================================================
-- UTILITY FUNCTIONS FOR RLS
-- =====================================================

-- Function to check if user owns a conversation
CREATE OR REPLACE FUNCTION public.user_owns_conversation(conv_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conv_id AND conversations.user_id = user_owns_conversation.user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access a folder
CREATE OR REPLACE FUNCTION public.user_can_access_folder(folder_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.folders
        WHERE id = folder_id AND folders.user_id = user_can_access_folder.user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get accessible conversation IDs for a user
CREATE OR REPLACE FUNCTION public.get_user_conversation_ids(target_user_id UUID)
RETURNS TABLE(conversation_id UUID) AS $$
BEGIN
    RETURN QUERY
    SELECT id FROM public.conversations
    WHERE user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- INDEXES FOR RLS PERFORMANCE
-- =====================================================

-- Add indexes on columns used in RLS policies for better performance
-- Most of these already exist from the initial schema, but adding any missing ones

-- Ensure we have indexes on user_id columns for all tables
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id_rls ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_folders_user_id_rls ON public.folders(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id_rls ON public.conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id_rls ON public.api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_exports_user_id_rls ON public.conversation_exports(user_id);
CREATE INDEX IF NOT EXISTS idx_templates_user_id_rls ON public.conversation_templates(user_id);

-- Index for messages RLS policy (conversation_id lookups)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id_rls ON public.messages(conversation_id);

-- Index for public templates
CREATE INDEX IF NOT EXISTS idx_templates_public_rls ON public.conversation_templates(is_public) WHERE is_public = true;

-- =====================================================
-- RLS TESTING FUNCTIONS
-- =====================================================

-- Function to test RLS policies (for development)
CREATE OR REPLACE FUNCTION public.test_rls_policies()
RETURNS TABLE(
    table_name TEXT,
    policy_count INTEGER,
    rls_enabled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname || '.' || tablename as table_name,
        COUNT(pol.policyname)::INTEGER as policy_count,
        relrowsecurity as rls_enabled
    FROM pg_tables t
    LEFT JOIN pg_policies pol ON pol.tablename = t.tablename
    LEFT JOIN pg_class c ON c.relname = t.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename IN ('user_profiles', 'folders', 'conversations', 'messages', 'api_keys', 'conversation_exports', 'conversation_templates')
    GROUP BY schemaname, t.tablename, relrowsecurity
    ORDER BY table_name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SECURITY VALIDATION
-- =====================================================

-- Function to validate that all user tables have RLS enabled
CREATE OR REPLACE FUNCTION public.validate_rls_security()
RETURNS TABLE(
    table_name TEXT,
    rls_enabled BOOLEAN,
    has_policies BOOLEAN,
    security_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH table_security AS (
        SELECT
            t.tablename,
            c.relrowsecurity as table_rls_enabled,
            COUNT(pol.policyname) > 0 as table_has_policies
        FROM pg_tables t
        LEFT JOIN pg_class c ON c.relname = t.tablename
        LEFT JOIN pg_policies pol ON pol.tablename = t.tablename
        WHERE t.schemaname = 'public'
        AND t.tablename IN ('user_profiles', 'folders', 'conversations', 'messages', 'api_keys', 'conversation_exports', 'conversation_templates')
        GROUP BY t.tablename, c.relrowsecurity
    )
    SELECT
        tablename::TEXT,
        table_rls_enabled,
        table_has_policies,
        CASE
            WHEN table_rls_enabled AND table_has_policies THEN 'SECURE'
            WHEN table_rls_enabled AND NOT table_has_policies THEN 'RLS_ENABLED_NO_POLICIES'
            WHEN NOT table_rls_enabled AND table_has_policies THEN 'POLICIES_EXIST_RLS_DISABLED'
            ELSE 'INSECURE'
        END::TEXT as security_status
    FROM table_security
    ORDER BY tablename;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION public.user_owns_conversation IS 'Helper function to check if a user owns a specific conversation';
COMMENT ON FUNCTION public.user_can_access_folder IS 'Helper function to check if a user can access a specific folder';
COMMENT ON FUNCTION public.get_user_conversation_ids IS 'Returns all conversation IDs that a user can access';
COMMENT ON FUNCTION public.test_rls_policies IS 'Development function to test RLS policy coverage';
COMMENT ON FUNCTION public.validate_rls_security IS 'Validates that all tables have proper RLS configuration';

-- =====================================================
-- RLS SETUP COMPLETE
-- =====================================================

-- Verify RLS is properly configured
DO $$
DECLARE
    rec RECORD;
    insecure_tables TEXT[] := '{}';
BEGIN
    -- Check if any tables are not properly secured
    FOR rec IN SELECT * FROM public.validate_rls_security() WHERE security_status != 'SECURE' LOOP
        insecure_tables := insecure_tables || rec.table_name;
    END LOOP;

    IF array_length(insecure_tables, 1) > 0 THEN
        RAISE WARNING 'Some tables may not be properly secured: %', array_to_string(insecure_tables, ', ');
    ELSE
        RAISE NOTICE 'All tables are properly secured with RLS policies';
    END IF;
END $$;
