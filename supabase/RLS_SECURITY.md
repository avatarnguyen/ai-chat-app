# Row Level Security (RLS) Documentation

## Overview

This document describes the Row Level Security (RLS) implementation for the AI Chat App. RLS ensures complete data isolation between users - each user can only access their own data, providing a secure multi-tenant architecture.

## Security Model

### Core Principle
**Data Isolation**: Every user can only see and modify their own data. No user can access another user's conversations, messages, folders, API keys, or exports.

### Authentication Context
- `auth.uid()`: Returns the UUID of the currently authenticated user
- `auth.role()`: Returns the role of the current session ('anon', 'authenticated', 'service_role')

## RLS Policies by Table

### 1. user_profiles

**Enabled Operations**: SELECT, INSERT, UPDATE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own profile | SELECT | `auth.uid() = user_id` |
| Users can insert own profile | INSERT | `auth.uid() = user_id` |
| Users can update own profile | UPDATE | `auth.uid() = user_id` |

**Notes**: 
- No DELETE policy needed (handled by auth.users CASCADE)
- Profile creation is automatic via trigger

### 2. folders

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own folders | SELECT | `auth.uid() = user_id` |
| Users can insert own folders | INSERT | `auth.uid() = user_id` |
| Users can update own folders | UPDATE | `auth.uid() = user_id` |
| Users can delete own folders | DELETE | `auth.uid() = user_id` |

**Notes**:
- Supports hierarchical folder structures
- Cascade deletes handle nested folders

### 3. conversations

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own conversations | SELECT | `auth.uid() = user_id` |
| Users can insert own conversations | INSERT | `auth.uid() = user_id` |
| Users can update own conversations | UPDATE | `auth.uid() = user_id` |
| Users can delete own conversations | DELETE | `auth.uid() = user_id` |

### 4. messages

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own messages | SELECT | `conversation_id IN (SELECT id FROM conversations WHERE user_id = auth.uid())` |
| Users can insert own messages | INSERT | `conversation_id IN (SELECT id FROM conversations WHERE user_id = auth.uid())` |
| Users can update own messages | UPDATE | `conversation_id IN (SELECT id FROM conversations WHERE user_id = auth.uid())` |
| Users can delete own messages | DELETE | `conversation_id IN (SELECT id FROM conversations WHERE user_id = auth.uid())` |

**Notes**:
- Messages are secured through conversation ownership
- Most complex policies due to relationship traversal

### 5. api_keys

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own api keys | SELECT | `auth.uid() = user_id` |
| Users can insert own api keys | INSERT | `auth.uid() = user_id` |
| Users can update own api keys | UPDATE | `auth.uid() = user_id` |
| Users can delete own api keys | DELETE | `auth.uid() = user_id` |

**Notes**:
- API keys are encrypted before storage
- Critical for security - only owner can access

### 6. conversation_exports

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own exports | SELECT | `auth.uid() = user_id` |
| Users can insert own exports | INSERT | `auth.uid() = user_id AND (conversation_id IS NULL OR conversation_id IN (...))` |
| Users can update own exports | UPDATE | `auth.uid() = user_id` |
| Users can delete own exports | DELETE | `auth.uid() = user_id` |

### 7. conversation_templates

**Enabled Operations**: SELECT, INSERT, UPDATE, DELETE

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view templates | SELECT | `auth.uid() = user_id OR is_public = true` |
| Users can insert own templates | INSERT | `auth.uid() = user_id` |
| Users can update own templates | UPDATE | `auth.uid() = user_id` |
| Users can delete own templates | DELETE | `auth.uid() = user_id` |

**Notes**:
- Only table that allows cross-user access (public templates)
- Users can see public templates but only modify their own

## Service Role Policies

### Administrative Access
The `service_role` has bypass policies for all tables to enable:
- Data migration and maintenance
- Analytics and reporting
- System-level operations
- Bulk data processing

**Security Note**: Service role keys must be kept secure and only used server-side.

## Performance Considerations

### Optimized Indexes
RLS policies use indexes on:
- `user_id` columns for direct ownership checks
- `conversation_id` for message relationship lookups
- `is_public` for template visibility

### Query Performance
- Simple ownership checks (user_id = auth.uid()) are very fast
- Message policies require subquery optimization
- Postgres query planner handles RLS efficiently

## Testing RLS Policies

### 1. Validation Function
```sql
SELECT * FROM public.validate_rls_security();
```

Expected output: All tables should show `SECURE` status.

### 2. Manual Testing

#### Test User Isolation
```sql
-- Create test users (through auth)
-- User A: 11111111-1111-1111-1111-111111111111
-- User B: 22222222-2222-2222-2222-222222222222

-- Test folder isolation
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';

INSERT INTO folders (user_id, name) VALUES (auth.uid(), 'User A Folder');

-- Switch to User B
SET LOCAL request.jwt.claims '{"sub": "22222222-2222-2222-2222-222222222222"}';

-- This should return empty (User B can't see User A's folders)
SELECT * FROM folders;
```

#### Test Conversation Access
```sql
-- As User A: Create conversation
SET LOCAL request.jwt.claims '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO conversations (user_id, title) VALUES (auth.uid(), 'User A Conversation');

-- As User B: Try to access (should return empty)
SET LOCAL request.jwt.claims '{"sub": "22222222-2222-2222-2222-222222222222"}';
SELECT * FROM conversations;
```

### 3. API Testing

#### Test with Anon Key (No User)
```bash
curl -H "apikey: [ANON_KEY]" \
     "http://localhost:54321/rest/v1/user_profiles"
# Should return: []
```

#### Test with Valid JWT
```bash
# Get JWT token for a user first, then:
curl -H "apikey: [ANON_KEY]" \
     -H "Authorization: Bearer [USER_JWT]" \
     "http://localhost:54321/rest/v1/user_profiles"
# Should return: user's profile only
```

## Security Best Practices

### 1. Client-Side Security
- **Never** use service_role key in client applications
- Always use anon key with user JWT tokens
- Validate user input before sending to database

### 2. Server-Side Security
- Use service_role sparingly and securely
- Implement additional validation in Edge Functions
- Log and monitor administrative operations

### 3. API Key Management
- API keys are encrypted at rest using pgcrypto
- Only the owning user can decrypt and use their keys
- Implement key rotation policies

### 4. Data Validation
```sql
-- Example: Additional validation in application layer
CREATE OR REPLACE FUNCTION validate_conversation_access(conv_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Additional business logic validation
    RETURN public.user_owns_conversation(conv_id, auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Troubleshooting

### Common Issues

#### 1. "Row level security policy violation"
**Cause**: User trying to access data they don't own
**Solution**: Check authentication and ensure user_id matches auth.uid()

#### 2. Empty results when data should exist
**Cause**: RLS policies are working correctly, filtering out unauthorized data
**Solution**: Verify user authentication and data ownership

#### 3. "Permission denied for table"
**Cause**: RLS enabled but no policies defined, or insufficient privileges
**Solution**: Check policy definitions and table permissions

### Debugging Queries

#### Check RLS Status
```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

#### List All Policies
```sql
SELECT tablename, policyname, cmd, roles, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public';
```

#### Check Current User Context
```sql
SELECT auth.uid(), auth.role();
```

### Performance Debugging

#### Check Query Plans
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM messages 
WHERE conversation_id IN (
    SELECT id FROM conversations WHERE user_id = auth.uid()
);
```

#### Monitor RLS Overhead
```sql
-- Compare with and without RLS
SET row_security = off;  -- Admin only
EXPLAIN ANALYZE SELECT * FROM messages;

SET row_security = on;
EXPLAIN ANALYZE SELECT * FROM messages;
```

## Migration and Deployment

### Production Checklist
- [ ] All tables have RLS enabled
- [ ] All tables have appropriate policies
- [ ] Service role access is properly restricted
- [ ] Performance indexes are in place
- [ ] Security validation passes
- [ ] Test with real user data

### Rollback Plan
```sql
-- Emergency RLS disable (admin only)
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Re-enable after fix
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

## Monitoring and Auditing

### Security Monitoring
```sql
-- Check for policy violations (if logging enabled)
SELECT * FROM pg_stat_user_tables WHERE n_tup_ins + n_tup_upd + n_tup_del > 0;

-- Monitor RLS policy usage
SELECT schemaname, tablename, COUNT(*) as policy_count
FROM pg_policies 
GROUP BY schemaname, tablename;
```

### Regular Security Audits
1. Run `validate_rls_security()` monthly
2. Review and test all policies quarterly
3. Monitor for unauthorized access attempts
4. Audit service_role usage

## Compliance Notes

### Data Privacy (GDPR/CCPA)
- RLS ensures user data isolation
- User deletion cascades properly remove all related data
- Export functionality supports data portability requirements

### SOC 2 Compliance
- Access controls implemented at database level
- Audit trails maintained through timestamps
- Principle of least privilege enforced

---

**Last Updated**: 2024-12-15
**Version**: 1.0
**Next Review**: 2024-03-15

For questions or security concerns, contact the development team.