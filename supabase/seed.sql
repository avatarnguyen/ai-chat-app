-- =====================================================
-- AI Chat App - Development Seed Data
-- =====================================================
-- This file contains sample data for development and testing
-- Run with: supabase db reset (automatically applies seed.sql)

-- =====================================================
-- CONVERSATION TEMPLATES (Public/System Templates)
-- =====================================================

-- Note: These templates use a placeholder user_id that should be replaced
-- with actual user IDs in production, or create a system user

-- For now, we'll create templates without user_id constraint
-- These will be created when real users exist

-- =====================================================
-- SAMPLE DATA FUNCTIONS
-- =====================================================

-- Function to create sample data for a given user
CREATE OR REPLACE FUNCTION create_sample_data_for_user(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Create sample folders
    INSERT INTO public.folders (id, user_id, name, description, color, icon) VALUES
        (gen_random_uuid(), target_user_id, 'Work Projects', 'Conversations related to work and professional projects', '#3b82f6', '💼'),
        (gen_random_uuid(), target_user_id, 'Personal', 'Personal conversations and casual chats', '#10b981', '🏠'),
        (gen_random_uuid(), target_user_id, 'Learning', 'Educational conversations and learning materials', '#f59e0b', '📚'),
        (gen_random_uuid(), target_user_id, 'Code Review', 'Programming help and code review sessions', '#8b5cf6', '💻'),
        (gen_random_uuid(), target_user_id, 'Creative Writing', 'Story writing and creative content', '#ec4899', '✍️');

    -- Get folder IDs for use in conversations
    DECLARE
        work_folder_id UUID;
        personal_folder_id UUID;
        learning_folder_id UUID;
        code_folder_id UUID;
    BEGIN
        SELECT id INTO work_folder_id FROM public.folders WHERE user_id = target_user_id AND name = 'Work Projects';
        SELECT id INTO personal_folder_id FROM public.folders WHERE user_id = target_user_id AND name = 'Personal';
        SELECT id INTO learning_folder_id FROM public.folders WHERE user_id = target_user_id AND name = 'Learning';
        SELECT id INTO code_folder_id FROM public.folders WHERE user_id = target_user_id AND name = 'Code Review';

        -- Create sample conversations
        INSERT INTO public.conversations (id, user_id, folder_id, title, model_name, model_provider, model_settings, tags) VALUES
            (gen_random_uuid(), target_user_id, work_folder_id, 'Project Planning Assistant', 'gpt-4', 'openai', '{"temperature": 0.7, "max_tokens": 2000}', ARRAY['planning', 'productivity']),
            (gen_random_uuid(), target_user_id, work_folder_id, 'Email Draft Helper', 'gpt-3.5-turbo', 'openai', '{"temperature": 0.5, "max_tokens": 1000}', ARRAY['writing', 'communication']),
            (gen_random_uuid(), target_user_id, personal_folder_id, 'Travel Planning', 'claude-3-sonnet-20240229', 'anthropic', '{"temperature": 0.6, "max_tokens": 1500}', ARRAY['travel', 'planning']),
            (gen_random_uuid(), target_user_id, learning_folder_id, 'Python Learning Journey', 'gpt-4', 'openai', '{"temperature": 0.3, "max_tokens": 2000}', ARRAY['python', 'programming', 'learning']),
            (gen_random_uuid(), target_user_id, code_folder_id, 'React App Debugging', 'gpt-4', 'openai', '{"temperature": 0.2, "max_tokens": 2500}', ARRAY['react', 'debugging', 'javascript']),
            (gen_random_uuid(), target_user_id, NULL, 'Quick Questions', 'gpt-3.5-turbo', 'openai', '{"temperature": 0.7, "max_tokens": 1000}', ARRAY['general']);

        -- Create sample messages for one conversation
        DECLARE
            sample_conv_id UUID;
        BEGIN
            SELECT id INTO sample_conv_id FROM public.conversations WHERE user_id = target_user_id AND title = 'Python Learning Journey';

            INSERT INTO public.messages (conversation_id, role, content, model_name, model_provider, prompt_tokens, completion_tokens, total_tokens) VALUES
                (sample_conv_id, 'user', 'I''m just starting to learn Python. Can you help me understand the basics?', NULL, NULL, 0, 0, 0),
                (sample_conv_id, 'assistant', 'I''d be happy to help you learn Python! Python is a great language for beginners because of its clean, readable syntax. Let''s start with the fundamentals:\n\n**1. Variables and Data Types**\n```python\n# Numbers\nage = 25\npi = 3.14159\n\n# Strings\nname = "Alice"\ngreeting = ''Hello, World!''\n\n# Booleans\nis_student = True\nhas_license = False\n```\n\n**2. Basic Operations**\n```python\n# Math\nresult = 10 + 5 * 2  # 20\npower = 2 ** 3       # 8\n\n# String operations\nfull_name = "John" + " " + "Doe"\nrepeated = "Ha" * 3  # "HaHaHa"\n```\n\nWhat specific area would you like to explore first? Functions, loops, or data structures like lists and dictionaries?', 'gpt-4', 'openai', 150, 185, 335),
                (sample_conv_id, 'user', 'That''s great! I''d like to learn about functions. How do I create and use them?', NULL, NULL, 0, 0, 0),
                (sample_conv_id, 'assistant', 'Great choice! Functions are essential in Python. They help you organize code and avoid repetition.\n\n**Basic Function Syntax:**\n```python\ndef function_name(parameters):\n    """Optional docstring"""\n    # Function body\n    return result  # Optional\n```\n\n**Examples:**\n\n1. **Simple function:**\n```python\ndef greet(name):\n    return f"Hello, {name}!"\n\n# Usage\nmessage = greet("Alice")\nprint(message)  # Output: Hello, Alice!\n```\n\n2. **Function with multiple parameters:**\n```python\ndef calculate_area(length, width):\n    """Calculate the area of a rectangle"""\n    area = length * width\n    return area\n\n# Usage\nroom_area = calculate_area(12, 10)\nprint(f"Room area: {room_area} square feet")\n```\n\n3. **Function with default parameters:**\n```python\ndef introduce(name, age=25, city="Unknown"):\n    return f"Hi, I''m {name}, {age} years old, from {city}"\n\n# Usage\nprint(introduce("Bob"))  # Uses default age and city\nprint(introduce("Alice", 30, "New York"))  # All parameters provided\n```\n\nTry creating a simple function yourself! What would you like to build?', 'gpt-4', 'openai', 120, 220, 340);
        END;
    END;

    -- Create sample conversation templates for this user
    INSERT INTO public.conversation_templates (user_id, name, description, category, initial_messages, model_settings, is_public) VALUES
        (target_user_id, 'Code Review Assistant', 'Help review and improve code quality', 'programming',
         '[{"role": "system", "content": "You are an expert code reviewer. Analyze code for best practices, potential bugs, performance issues, and suggest improvements. Be constructive and educational in your feedback."}]'::jsonb,
         '{"temperature": 0.3, "max_tokens": 2000}'::jsonb, false),

        (target_user_id, 'Creative Writing Partner', 'Collaborative story and content writing', 'creative',
         '[{"role": "system", "content": "You are a creative writing partner. Help brainstorm ideas, develop characters, plot storylines, and improve writing style. Be imaginative and supportive."}]'::jsonb,
         '{"temperature": 0.8, "max_tokens": 1500}'::jsonb, false),

        (target_user_id, 'Learning Tutor', 'Personalized learning and explanation assistant', 'education',
         '[{"role": "system", "content": "You are a patient and knowledgeable tutor. Explain concepts clearly, use examples, and adapt your teaching style to the student''s level. Ask questions to check understanding."}]'::jsonb,
         '{"temperature": 0.6, "max_tokens": 2000}'::jsonb, false);

END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PUBLIC CONVERSATION TEMPLATES
-- =====================================================

-- Create a system/public user for public templates
-- Note: This is a workaround for development. In production, handle this differently.

-- We'll create public templates when users exist, or modify the schema to allow NULL user_id for system templates

-- For now, let's create some helper functions and sample data that can be used once users are created

-- =====================================================
-- DEVELOPMENT UTILITIES
-- =====================================================

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
    total_conversations INTEGER,
    total_messages INTEGER,
    total_folders INTEGER,
    total_tokens BIGINT,
    favorite_conversations INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INTEGER FROM public.conversations WHERE user_id = target_user_id),
        (SELECT COUNT(*)::INTEGER FROM public.messages m JOIN public.conversations c ON m.conversation_id = c.id WHERE c.user_id = target_user_id),
        (SELECT COUNT(*)::INTEGER FROM public.folders WHERE user_id = target_user_id),
        (SELECT COALESCE(SUM(total_tokens), 0)::BIGINT FROM public.messages m JOIN public.conversations c ON m.conversation_id = c.id WHERE c.user_id = target_user_id),
        (SELECT COUNT(*)::INTEGER FROM public.conversations WHERE user_id = target_user_id AND is_favorite = true);
END;
$$ LANGUAGE plpgsql;

-- Function to search messages
CREATE OR REPLACE FUNCTION search_messages(
    target_user_id UUID,
    search_query TEXT,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
    message_id UUID,
    conversation_id UUID,
    conversation_title TEXT,
    role message_role,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        m.conversation_id,
        c.title,
        m.role,
        m.content,
        m.created_at,
        ts_rank(to_tsvector('english', m.content), plainto_tsquery('english', search_query)) as rank
    FROM public.messages m
    JOIN public.conversations c ON m.conversation_id = c.id
    WHERE c.user_id = target_user_id
    AND to_tsvector('english', m.content) @@ plainto_tsquery('english', search_query)
    ORDER BY rank DESC, m.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAMPLE DATA CREATION INSTRUCTIONS
-- =====================================================

-- After creating your first user through authentication, run:
-- SELECT create_sample_data_for_user('your-user-id-here');

-- To get user statistics:
-- SELECT * FROM get_user_stats('your-user-id-here');

-- To search messages:
-- SELECT * FROM search_messages('your-user-id-here', 'python functions', 5);

-- =====================================================
-- DEFAULT MODEL SETTINGS
-- =====================================================

-- Common model configurations that can be referenced
-- These can be used as defaults in the application

-- Example usage in application:
-- const DEFAULT_MODEL_SETTINGS = {
--   'gpt-4': { temperature: 0.7, max_tokens: 2000, top_p: 1 },
--   'gpt-3.5-turbo': { temperature: 0.7, max_tokens: 1000, top_p: 1 },
--   'claude-3-sonnet': { temperature: 0.6, max_tokens: 1500, top_p: 0.9 },
--   'gemini-pro': { temperature: 0.5, max_tokens: 1000, top_p: 0.95 }
-- };

-- =====================================================
-- DEVELOPMENT NOTES
-- =====================================================

-- 1. To create sample data for testing:
--    - First, create a user through the authentication system
--    - Then run: SELECT create_sample_data_for_user('user-uuid-here');

-- 2. To clean up sample data:
--    - DELETE FROM public.messages WHERE conversation_id IN (SELECT id FROM public.conversations WHERE user_id = 'user-uuid-here');
--    - DELETE FROM public.conversations WHERE user_id = 'user-uuid-here';
--    - DELETE FROM public.folders WHERE user_id = 'user-uuid-here';

-- 3. The seed data includes:
--    - 5 sample folders with different categories
--    - 6 sample conversations with different models and settings
--    - Sample messages showing a learning conversation
--    - 3 conversation templates for different use cases

-- 4. All timestamps will be set to the current time when the seed data is created

-- =====================================================
-- SEED COMPLETE
-- =====================================================

-- Seed file ready for development use
-- Run 'supabase db reset' to apply this seed data
-- Remember to create sample data for users after they sign up!
