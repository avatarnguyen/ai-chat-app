-- =====================================================
-- AI Chat App - RLS Testing Script
-- =====================================================
-- This script comprehensively tests Row Level Security policies
-- Run with: psql "postgresql://postgres:postgres@localhost:54322/postgres" -f test_rls.sql

\echo '==================================='
\echo 'AI Chat App - RLS Security Testing'
\echo '==================================='
\echo ''

-- Start transaction for testing
BEGIN;

-- =====================================================
-- TEST 1: VERIFY RLS IS ENABLED
-- =====================================================
\echo '1. Testing RLS Status...'

DO $$
DECLARE
    table_record RECORD;
    insecure_count INTEGER := 0;
BEGIN
    FOR table_record IN
        SELECT * FROM public.validate_rls_security()
        WHERE security_status != 'SECURE'
    LOOP
        RAISE WARNING 'Table % is not secure: %', table_record.table_name, table_record.security_status;
        insecure_count := insecure_count + 1;
    END LOOP;

    IF insecure_count = 0 THEN
        RAISE NOTICE '✓ All tables have RLS properly configured';
    ELSE
        RAISE WARNING '✗ % table(s) have security issues', insecure_count;
    END IF;
END $$;

\echo ''

-- =====================================================
-- TEST 2: CREATE TEST USERS AND DATA
-- =====================================================
\echo '2. Setting up test data...'

-- Create test user profiles (simulating authenticated users)
INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'user1@test.com', NOW(), NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'user2@test.com', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Create user profiles (will be auto-created by trigger, but ensuring they exist)
INSERT INTO public.user_profiles (user_id, display_name)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Test User 1'),
    ('22222222-2222-2222-2222-222222222222', 'Test User 2')
ON CONFLICT (user_id) DO NOTHING;

\echo '✓ Test users created'

-- =====================================================
-- TEST 3: TEST USER ISOLATION
-- =====================================================
\echo ''
\echo '3. Testing user data isolation...'

-- Test as User 1
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

-- Create data for User 1
INSERT INTO public.folders (user_id, name, color)
VALUES (auth.uid(), 'User 1 Work Folder', '#3b82f6');

INSERT INTO public.conversations (user_id, title, model_name)
VALUES (auth.uid(), 'User 1 Conversation', 'gpt-4');

-- Get conversation ID for messages
DO $$
DECLARE
    conv_id UUID;
BEGIN
    SELECT id INTO conv_id FROM public.conversations WHERE user_id = auth.uid() LIMIT 1;

    INSERT INTO public.messages (conversation_id, role, content)
    VALUES (conv_id, 'user', 'Hello from User 1');
END $$;

INSERT INTO public.api_keys (user_id, provider, provider_name, encrypted_key, key_hash)
VALUES (auth.uid(), 'openai', 'OpenAI', 'encrypted_key_user1', 'hash_user1');

\echo '✓ User 1 data created'

-- Switch to User 2 context
SET LOCAL request.jwt.claims '{"sub": "22222222-2222-2222-2222-222222222222"}';

-- Create data for User 2
INSERT INTO public.folders (user_id, name, color)
VALUES (auth.uid(), 'User 2 Personal Folder', '#10b981');

INSERT INTO public.conversations (user_id, title, model_name)
VALUES (auth.uid(), 'User 2 Conversation', 'claude-3-sonnet');

-- Get conversation ID for messages
DO $$
DECLARE
    conv_id UUID;
BEGIN
    SELECT id INTO conv_id FROM public.conversations WHERE user_id = auth.uid() LIMIT 1;

    INSERT INTO public.messages (conversation_id, role, content)
    VALUES (conv_id, 'user', 'Hello from User 2');
END $$;

INSERT INTO public.api_keys (user_id, provider, provider_name, encrypted_key, key_hash)
VALUES (auth.uid(), 'anthropic', 'Anthropic', 'encrypted_key_user2', 'hash_user2');

\echo '✓ User 2 data created'

-- =====================================================
-- TEST 4: VERIFY DATA ISOLATION
-- =====================================================
\echo ''
\echo '4. Testing data isolation enforcement...'

-- Test User 1 can only see their own data
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

DO $$
DECLARE
    folder_count INTEGER;
    conv_count INTEGER;
    message_count INTEGER;
    key_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO folder_count FROM public.folders;
    SELECT COUNT(*) INTO conv_count FROM public.conversations;
    SELECT COUNT(*) INTO message_count FROM public.messages;
    SELECT COUNT(*) INTO key_count FROM public.api_keys;

    IF folder_count = 1 AND conv_count = 1 AND message_count = 1 AND key_count = 1 THEN
        RAISE NOTICE '✓ User 1 sees only their own data (% folders, % conversations, % messages, % keys)',
                     folder_count, conv_count, message_count, key_count;
    ELSE
        RAISE WARNING '✗ User 1 data isolation failed: % folders, % conversations, % messages, % keys',
                      folder_count, conv_count, message_count, key_count;
    END IF;
END $$;

-- Test User 2 can only see their own data
SET LOCAL request.jwt.claims '{"sub": "22222222-2222-2222-2222-222222222222"}';

DO $$
DECLARE
    folder_count INTEGER;
    conv_count INTEGER;
    message_count INTEGER;
    key_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO folder_count FROM public.folders;
    SELECT COUNT(*) INTO conv_count FROM public.conversations;
    SELECT COUNT(*) INTO message_count FROM public.messages;
    SELECT COUNT(*) INTO key_count FROM public.api_keys;

    IF folder_count = 1 AND conv_count = 1 AND message_count = 1 AND key_count = 1 THEN
        RAISE NOTICE '✓ User 2 sees only their own data (% folders, % conversations, % messages, % keys)',
                     folder_count, conv_count, message_count, key_count;
    ELSE
        RAISE WARNING '✗ User 2 data isolation failed: % folders, % conversations, % messages, % keys',
                      folder_count, conv_count, message_count, key_count;
    END IF;
END $$;

-- =====================================================
-- TEST 5: TEST UNAUTHORIZED ACCESS ATTEMPTS
-- =====================================================
\echo ''
\echo '5. Testing unauthorized access prevention...'

-- Try to access another user's conversation as User 1
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

DO $$
DECLARE
    user2_conv_id UUID;
    violation_caught BOOLEAN := FALSE;
BEGIN
    -- Get User 2's conversation ID using service role
    SET LOCAL role service_role;
    SELECT id INTO user2_conv_id FROM public.conversations
    WHERE user_id = '22222222-2222-2222-2222-222222222222' LIMIT 1;

    -- Switch back to User 1 context
    SET LOCAL role authenticated;
    SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

    -- Try to insert a message into User 2's conversation (should fail)
    BEGIN
        INSERT INTO public.messages (conversation_id, role, content)
        VALUES (user2_conv_id, 'user', 'Unauthorized message');

        RAISE WARNING '✗ Security breach: User 1 was able to insert into User 2 conversation';
    EXCEPTION
        WHEN insufficient_privilege OR check_violation THEN
            violation_caught := TRUE;
            RAISE NOTICE '✓ Unauthorized access properly blocked';
    END;

    IF NOT violation_caught THEN
        RAISE WARNING '✗ RLS policy may not be working correctly';
    END IF;
END $$;

-- =====================================================
-- TEST 6: TEST CROSS-USER READ ATTEMPTS
-- =====================================================
\echo ''
\echo '6. Testing cross-user read protection...'

-- User 1 tries to read User 2's data directly
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

DO $$
DECLARE
    other_user_data_count INTEGER;
BEGIN
    -- Try to find data that belongs to User 2
    SELECT COUNT(*) INTO other_user_data_count
    FROM public.folders
    WHERE name LIKE '%User 2%';

    IF other_user_data_count = 0 THEN
        RAISE NOTICE '✓ Cross-user read protection working';
    ELSE
        RAISE WARNING '✗ User 1 can see User 2 data: % records', other_user_data_count;
    END IF;
END $$;

-- =====================================================
-- TEST 7: TEST CONVERSATION TEMPLATES (PUBLIC ACCESS)
-- =====================================================
\echo ''
\echo '7. Testing public template access...'

-- Create public template as User 1
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

INSERT INTO public.conversation_templates (user_id, name, description, is_public, initial_messages)
VALUES (auth.uid(), 'Public Template', 'A public template for testing', true, '[]'::jsonb);

-- Create private template as User 1
INSERT INTO public.conversation_templates (user_id, name, description, is_public, initial_messages)
VALUES (auth.uid(), 'Private Template', 'A private template for testing', false, '[]'::jsonb);

-- Switch to User 2 and test access
SET LOCAL request.jwt.claims '{"sub": "22222222-2222-2222-2222-222222222222"}';

DO $$
DECLARE
    public_template_count INTEGER;
    total_template_count INTEGER;
BEGIN
    -- Count public templates (should see User 1's public template)
    SELECT COUNT(*) INTO public_template_count
    FROM public.conversation_templates
    WHERE is_public = true;

    -- Count total templates visible to User 2
    SELECT COUNT(*) INTO total_template_count
    FROM public.conversation_templates;

    IF public_template_count >= 1 AND total_template_count = public_template_count THEN
        RAISE NOTICE '✓ Template visibility working: % public templates visible, % total',
                     public_template_count, total_template_count;
    ELSE
        RAISE WARNING '✗ Template visibility issue: % public, % total visible',
                      public_template_count, total_template_count;
    END IF;
END $$;

-- =====================================================
-- TEST 8: TEST SERVICE ROLE BYPASS
-- =====================================================
\echo ''
\echo '8. Testing service role administrative access...'

-- Switch to service role
SET LOCAL role service_role;

DO $$
DECLARE
    total_folders INTEGER;
    total_conversations INTEGER;
    total_messages INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_folders FROM public.folders;
    SELECT COUNT(*) INTO total_conversations FROM public.conversations;
    SELECT COUNT(*) INTO total_messages FROM public.messages;

    IF total_folders >= 2 AND total_conversations >= 2 AND total_messages >= 2 THEN
        RAISE NOTICE '✓ Service role can see all data: % folders, % conversations, % messages',
                     total_folders, total_conversations, total_messages;
    ELSE
        RAISE WARNING '✗ Service role access limited: % folders, % conversations, % messages',
                      total_folders, total_conversations, total_messages;
    END IF;
END $$;

-- =====================================================
-- TEST 9: TEST ANON ROLE (NO ACCESS)
-- =====================================================
\echo ''
\echo '9. Testing anonymous access (should be blocked)...'

-- Switch to anon role (no user context)
SET LOCAL role anon;
RESET request.jwt.claims;

DO $$
DECLARE
    anon_folder_count INTEGER;
    anon_conv_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO anon_folder_count FROM public.folders;
    SELECT COUNT(*) INTO anon_conv_count FROM public.conversations;

    IF anon_folder_count = 0 AND anon_conv_count = 0 THEN
        RAISE NOTICE '✓ Anonymous users cannot see any data';
    ELSE
        RAISE WARNING '✗ Anonymous users can see data: % folders, % conversations',
                      anon_folder_count, anon_conv_count;
    END IF;
END $$;

-- =====================================================
-- TEST SUMMARY
-- =====================================================
\echo ''
\echo '========================================='
\echo 'RLS TESTING COMPLETE'
\echo '========================================='
\echo ''
\echo 'Summary of tests performed:'
\echo '1. ✓ RLS enabled on all tables'
\echo '2. ✓ Test data creation'
\echo '3. ✓ User data isolation'
\echo '4. ✓ Unauthorized access prevention'
\echo '5. ✓ Cross-user read protection'
\echo '6. ✓ Public template access'
\echo '7. ✓ Service role administrative access'
\echo '8. ✓ Anonymous access blocking'
\echo ''
\echo 'If all tests show ✓, your RLS policies are working correctly!'
\echo 'Any ✗ indicates a potential security issue that needs investigation.'
\echo ''

-- =====================================================
-- CLEANUP
-- =====================================================
\echo 'Cleaning up test data...'

-- Use service role to clean up
SET LOCAL role service_role;

-- Delete test data
DELETE FROM public.messages WHERE conversation_id IN (
    SELECT id FROM public.conversations
    WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
);

DELETE FROM public.conversations
WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM public.folders
WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM public.api_keys
WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM public.conversation_templates
WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM public.user_profiles
WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

DELETE FROM auth.users
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

\echo '✓ Test data cleaned up'

-- Rollback transaction to leave database in original state
ROLLBACK;

\echo ''
\echo 'RLS testing completed. Database restored to original state.'
\echo ''
