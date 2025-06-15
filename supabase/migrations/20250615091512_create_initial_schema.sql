-- =====================================================
-- AI Chat App Database Schema
-- =====================================================
-- This migration creates the initial database schema for the AI Chat App
-- including users, conversations, messages, folders, and API key management.

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUMS
-- =====================================================

-- Message role types
CREATE TYPE message_role AS ENUM ('user', 'assistant', 'system');

-- Conversation status
CREATE TYPE conversation_status AS ENUM ('active', 'archived', 'deleted');

-- LLM Provider types
CREATE TYPE llm_provider AS ENUM ('openai', 'anthropic', 'google', 'openrouter', 'other');

-- Subscription tiers
CREATE TYPE subscription_tier AS ENUM ('free', 'pro', 'enterprise');

-- =====================================================
-- USER PROFILES TABLE
-- =====================================================

CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,

    -- Profile information
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,

    -- User preferences
    preferred_model TEXT DEFAULT 'gpt-3.5-turbo',
    theme_preference TEXT DEFAULT 'system', -- 'light', 'dark', 'system'
    language_preference TEXT DEFAULT 'en',

    -- Subscription and usage
    subscription_tier subscription_tier DEFAULT 'free',
    total_messages_sent INTEGER DEFAULT 0,
    total_tokens_used BIGINT DEFAULT 0,
    monthly_message_limit INTEGER DEFAULT 100,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- FOLDERS TABLE
-- =====================================================

CREATE TABLE public.folders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    parent_folder_id UUID REFERENCES public.folders(id) ON DELETE CASCADE,

    -- Folder properties
    name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    description TEXT,
    color TEXT DEFAULT '#6366f1', -- Hex color code
    icon TEXT, -- Icon name or emoji

    -- Organization
    sort_order INTEGER DEFAULT 0,
    is_favorite BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT folders_no_self_reference CHECK (id != parent_folder_id),
    CONSTRAINT folders_unique_name_per_user_and_parent UNIQUE (user_id, parent_folder_id, name)
);

-- =====================================================
-- CONVERSATIONS TABLE
-- =====================================================

CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    folder_id UUID REFERENCES public.folders(id) ON DELETE SET NULL,

    -- Conversation metadata
    title TEXT NOT NULL DEFAULT 'New Conversation',
    description TEXT,

    -- Model configuration
    model_name TEXT NOT NULL DEFAULT 'gpt-3.5-turbo',
    model_provider llm_provider DEFAULT 'openai',
    model_settings JSONB DEFAULT '{}', -- Temperature, max_tokens, etc.

    -- Status and organization
    status conversation_status DEFAULT 'active',
    is_favorite BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    tags TEXT[] DEFAULT '{}',

    -- Statistics
    message_count INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10,4) DEFAULT 0.0000,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- MESSAGES TABLE
-- =====================================================

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,

    -- Message content
    role message_role NOT NULL,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'text', -- 'text', 'code', 'image', etc.

    -- Model information (for assistant messages)
    model_name TEXT,
    model_provider llm_provider,

    -- Token usage and cost
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10,6) DEFAULT 0.000000,

    -- Message metadata
    metadata JSONB DEFAULT '{}', -- Additional data like function calls, attachments, etc.
    parent_message_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,

    -- Status and features
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- API KEYS TABLE
-- =====================================================

CREATE TABLE public.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Provider information
    provider llm_provider NOT NULL,
    provider_name TEXT NOT NULL, -- Display name like "OpenAI GPT-4"

    -- Encrypted key storage
    encrypted_key TEXT NOT NULL, -- Encrypted API key
    key_hash TEXT NOT NULL, -- Hash for validation

    -- Key metadata
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0,

    -- Validation and limits
    is_valid BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    daily_limit INTEGER,
    monthly_limit INTEGER,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT api_keys_unique_provider_per_user UNIQUE (user_id, provider)
);

-- =====================================================
-- CONVERSATION EXPORTS TABLE
-- =====================================================

CREATE TABLE public.conversation_exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,

    -- Export metadata
    export_type TEXT NOT NULL DEFAULT 'json', -- 'json', 'markdown', 'pdf', 'csv'
    file_name TEXT NOT NULL,
    file_size BIGINT,
    file_url TEXT,

    -- Export settings
    include_metadata BOOLEAN DEFAULT TRUE,
    include_timestamps BOOLEAN DEFAULT TRUE,
    date_range_start TIMESTAMP WITH TIME ZONE,
    date_range_end TIMESTAMP WITH TIME ZONE,

    -- Status
    status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days')
);

-- =====================================================
-- CONVERSATION TEMPLATES TABLE
-- =====================================================

CREATE TABLE public.conversation_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Template metadata
    name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    description TEXT,
    category TEXT DEFAULT 'general',

    -- Template content
    initial_messages JSONB NOT NULL DEFAULT '[]', -- Array of message objects
    model_settings JSONB DEFAULT '{}',
    default_model TEXT DEFAULT 'gpt-3.5-turbo',

    -- Organization
    is_public BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- User profiles indexes
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX idx_user_profiles_subscription_tier ON public.user_profiles(subscription_tier);

-- Folders indexes
CREATE INDEX idx_folders_user_id ON public.folders(user_id);
CREATE INDEX idx_folders_parent_folder_id ON public.folders(parent_folder_id);
CREATE INDEX idx_folders_user_parent ON public.folders(user_id, parent_folder_id);

-- Conversations indexes
CREATE INDEX idx_conversations_user_id ON public.conversations(user_id);
CREATE INDEX idx_conversations_folder_id ON public.conversations(folder_id);
CREATE INDEX idx_conversations_status ON public.conversations(status);
CREATE INDEX idx_conversations_user_updated ON public.conversations(user_id, updated_at DESC);
CREATE INDEX idx_conversations_user_favorite ON public.conversations(user_id, is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX idx_conversations_tags ON public.conversations USING GIN(tags);

-- Messages indexes
CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_conversation_created ON public.messages(conversation_id, created_at);
CREATE INDEX idx_messages_role ON public.messages(role);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX idx_messages_content_search ON public.messages USING GIN(to_tsvector('english', content));

-- API keys indexes
CREATE INDEX idx_api_keys_user_id ON public.api_keys(user_id);
CREATE INDEX idx_api_keys_provider ON public.api_keys(provider);
CREATE INDEX idx_api_keys_active ON public.api_keys(user_id, is_active) WHERE is_active = TRUE;

-- Export indexes
CREATE INDEX idx_exports_user_id ON public.conversation_exports(user_id);
CREATE INDEX idx_exports_conversation_id ON public.conversation_exports(conversation_id);
CREATE INDEX idx_exports_status ON public.conversation_exports(status);

-- Template indexes
CREATE INDEX idx_templates_user_id ON public.conversation_templates(user_id);
CREATE INDEX idx_templates_category ON public.conversation_templates(category);
CREATE INDEX idx_templates_public ON public.conversation_templates(is_public) WHERE is_public = TRUE;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_folders_updated_at
    BEFORE UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at
    BEFORE UPDATE ON public.api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at
    BEFORE UPDATE ON public.conversation_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CONVERSATION STATISTICS TRIGGERS
-- =====================================================

-- Function to update conversation statistics
CREATE OR REPLACE FUNCTION update_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update message count and last message time
    UPDATE public.conversations
    SET
        message_count = (
            SELECT COUNT(*)
            FROM public.messages
            WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
            AND is_deleted = FALSE
        ),
        last_message_at = (
            SELECT MAX(created_at)
            FROM public.messages
            WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
            AND is_deleted = FALSE
        ),
        total_tokens = (
            SELECT COALESCE(SUM(total_tokens), 0)
            FROM public.messages
            WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
            AND is_deleted = FALSE
        ),
        estimated_cost = (
            SELECT COALESCE(SUM(estimated_cost), 0.0000)
            FROM public.messages
            WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
            AND is_deleted = FALSE
        )
    WHERE id = COALESCE(NEW.conversation_id, OLD.conversation_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Apply conversation stats triggers
CREATE TRIGGER update_conversation_stats_on_insert
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_stats();

CREATE TRIGGER update_conversation_stats_on_update
    AFTER UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_stats();

CREATE TRIGGER update_conversation_stats_on_delete
    AFTER DELETE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_stats();

-- =====================================================
-- USER PROFILE AUTO-CREATION
-- =====================================================

-- Function to create user profile when user signs up
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
    );
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to create profile on user signup
CREATE TRIGGER create_user_profile_on_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_user_profile();

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to get conversation hierarchy (for folders)
CREATE OR REPLACE FUNCTION get_folder_hierarchy(folder_uuid UUID)
RETURNS TABLE(
    id UUID,
    name TEXT,
    level INTEGER,
    path TEXT[]
) AS $$
WITH RECURSIVE folder_tree AS (
    -- Base case: start with the given folder
    SELECT
        f.id,
        f.name,
        f.parent_folder_id,
        0 as level,
        ARRAY[f.name] as path
    FROM public.folders f
    WHERE f.id = folder_uuid

    UNION ALL

    -- Recursive case: get parent folders
    SELECT
        f.id,
        f.name,
        f.parent_folder_id,
        ft.level + 1,
        f.name || ft.path
    FROM public.folders f
    JOIN folder_tree ft ON f.id = ft.parent_folder_id
)
SELECT
    folder_tree.id,
    folder_tree.name,
    folder_tree.level,
    folder_tree.path
FROM folder_tree
ORDER BY level DESC;
$$ language 'sql';

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.user_profiles IS 'Extended user profile information beyond auth.users';
COMMENT ON TABLE public.folders IS 'Hierarchical folder structure for organizing conversations';
COMMENT ON TABLE public.conversations IS 'Chat conversations with LLM models';
COMMENT ON TABLE public.messages IS 'Individual messages within conversations';
COMMENT ON TABLE public.api_keys IS 'Encrypted storage for user API keys to LLM providers';
COMMENT ON TABLE public.conversation_exports IS 'Export requests and metadata for conversations';
COMMENT ON TABLE public.conversation_templates IS 'Reusable conversation templates and prompts';

-- Column comments for important fields
COMMENT ON COLUMN public.messages.metadata IS 'JSON metadata for function calls, attachments, formatting, etc.';
COMMENT ON COLUMN public.api_keys.encrypted_key IS 'API key encrypted using pg_crypto functions';
COMMENT ON COLUMN public.conversations.model_settings IS 'JSON object with model parameters like temperature, max_tokens, etc.';
COMMENT ON COLUMN public.user_profiles.total_tokens_used IS 'Lifetime token usage across all conversations';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Schema created successfully. Initial data will be seeded separately.
