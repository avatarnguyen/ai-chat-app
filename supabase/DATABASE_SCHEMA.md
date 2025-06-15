# AI Chat App - Database Schema Documentation

## Overview

This document describes the database schema for the AI Chat App, a multi-LLM chat application built with Flutter and Supabase. The schema is designed to support:

- Multi-user chat conversations with various LLM providers
- Hierarchical folder organization system
- Secure API key management
- Message persistence and search
- Conversation templates and exports
- User profiles and subscription management

## Architecture

### Core Principles
- **Row Level Security (RLS)**: All user data is isolated using Supabase RLS policies
- **Hierarchical Organization**: Folders can be nested for flexible organization
- **Audit Trail**: All tables include created_at and updated_at timestamps
- **Performance Optimized**: Strategic indexes for fast queries
- **Extensible**: JSON columns for flexible metadata storage

### Database Extensions
- `uuid-ossp`: For UUID generation
- `pgcrypto`: For encryption of sensitive data (API keys)

## Tables

### 1. user_profiles
**Purpose**: Extended user profile information beyond auth.users

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users (unique) |
| display_name | TEXT | User's display name |
| avatar_url | TEXT | Profile picture URL |
| bio | TEXT | User biography |
| preferred_model | TEXT | Default LLM model preference |
| theme_preference | TEXT | UI theme (light/dark/system) |
| language_preference | TEXT | App language preference |
| subscription_tier | ENUM | free/pro/enterprise |
| total_messages_sent | INTEGER | Lifetime message count |
| total_tokens_used | BIGINT | Lifetime token usage |
| monthly_message_limit | INTEGER | Monthly message limit |
| created_at | TIMESTAMPTZ | Account creation time |
| updated_at | TIMESTAMPTZ | Last profile update |
| last_active_at | TIMESTAMPTZ | Last activity timestamp |

**Key Features:**
- Automatically created when user signs up (trigger)
- Tracks usage statistics for billing/limits
- Supports multiple subscription tiers

### 2. folders
**Purpose**: Hierarchical folder structure for organizing conversations

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| parent_folder_id | UUID | Self-referencing FK for hierarchy |
| name | TEXT | Folder name (1-100 chars) |
| description | TEXT | Optional folder description |
| color | TEXT | Hex color code for UI |
| icon | TEXT | Icon identifier or emoji |
| sort_order | INTEGER | Manual sorting order |
| is_favorite | BOOLEAN | Favorite folder flag |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last modification |

**Key Features:**
- Supports unlimited nesting depth
- Unique name constraint per user/parent combination
- Self-reference check prevents circular references
- Color coding and custom icons for visual organization

### 3. conversations
**Purpose**: Chat conversations with LLM models

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| folder_id | UUID | Foreign key to folders (nullable) |
| title | TEXT | Conversation title |
| description | TEXT | Optional description |
| model_name | TEXT | LLM model identifier |
| model_provider | ENUM | openai/anthropic/google/openrouter/other |
| model_settings | JSONB | Model parameters (temperature, etc.) |
| status | ENUM | active/archived/deleted |
| is_favorite | BOOLEAN | Favorite conversation flag |
| is_pinned | BOOLEAN | Pin to top of list |
| tags | TEXT[] | Array of tags for categorization |
| message_count | INTEGER | Cached message count |
| total_tokens | INTEGER | Cached token usage |
| estimated_cost | DECIMAL | Estimated API cost |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last modification |
| last_message_at | TIMESTAMPTZ | Last message timestamp |

**Key Features:**
- Supports multiple LLM providers
- Flexible model configuration via JSON
- Cached statistics updated by triggers
- Tagging system for categorization
- Status management (active/archived/deleted)

### 4. messages
**Purpose**: Individual messages within conversations

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| conversation_id | UUID | Foreign key to conversations |
| role | ENUM | user/assistant/system |
| content | TEXT | Message content |
| content_type | TEXT | Content type (text/code/image) |
| model_name | TEXT | Model used for assistant messages |
| model_provider | ENUM | Provider for assistant messages |
| prompt_tokens | INTEGER | Input tokens used |
| completion_tokens | INTEGER | Output tokens generated |
| total_tokens | INTEGER | Total tokens (prompt + completion) |
| estimated_cost | DECIMAL | Estimated cost for this message |
| metadata | JSONB | Additional metadata (attachments, etc.) |
| parent_message_id | UUID | For message threading |
| is_edited | BOOLEAN | Whether message was edited |
| is_deleted | BOOLEAN | Soft delete flag |
| error_message | TEXT | Error message if failed |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last modification |

**Key Features:**
- Full text search enabled on content
- Token usage tracking for cost estimation
- Support for message threading
- Soft delete for data recovery
- Extensible metadata via JSON

### 5. api_keys
**Purpose**: Encrypted storage for user API keys to LLM providers

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| provider | ENUM | LLM provider type |
| provider_name | TEXT | Human-readable provider name |
| encrypted_key | TEXT | Encrypted API key |
| key_hash | TEXT | Hash for validation |
| is_active | BOOLEAN | Whether key is active |
| last_used_at | TIMESTAMPTZ | Last usage timestamp |
| usage_count | INTEGER | Number of times used |
| is_valid | BOOLEAN | Whether key is valid |
| error_message | TEXT | Last validation error |
| daily_limit | INTEGER | Optional daily usage limit |
| monthly_limit | INTEGER | Optional monthly usage limit |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last modification |

**Key Features:**
- API keys encrypted using pgcrypto
- Unique provider constraint per user
- Usage tracking and validation
- Support for usage limits

### 6. conversation_exports
**Purpose**: Export requests and metadata for conversations

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| conversation_id | UUID | Foreign key to conversations |
| export_type | TEXT | Export format (json/markdown/pdf/csv) |
| file_name | TEXT | Generated filename |
| file_size | BIGINT | File size in bytes |
| file_url | TEXT | Storage URL for download |
| include_metadata | BOOLEAN | Whether to include metadata |
| include_timestamps | BOOLEAN | Whether to include timestamps |
| date_range_start | TIMESTAMPTZ | Export date range start |
| date_range_end | TIMESTAMPTZ | Export date range end |
| status | TEXT | pending/processing/completed/failed |
| error_message | TEXT | Error message if failed |
| created_at | TIMESTAMPTZ | Export request time |
| completed_at | TIMESTAMPTZ | Export completion time |
| expires_at | TIMESTAMPTZ | Link expiration (7 days default) |

**Key Features:**
- Multiple export formats
- Date range filtering
- Automatic cleanup of expired exports
- Progress tracking

### 7. conversation_templates
**Purpose**: Reusable conversation templates and prompts

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| name | TEXT | Template name (1-100 chars) |
| description | TEXT | Template description |
| category | TEXT | Template category |
| initial_messages | JSONB | Array of initial messages |
| model_settings | JSONB | Default model configuration |
| default_model | TEXT | Default model to use |
| is_public | BOOLEAN | Whether template is public |
| is_favorite | BOOLEAN | User's favorite template |
| usage_count | INTEGER | Number of times used |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last modification |
| last_used_at | TIMESTAMPTZ | Last usage timestamp |

**Key Features:**
- Public and private templates
- Flexible initial message configuration
- Usage tracking
- Category-based organization

## Relationships

```
auth.users (Supabase Auth)
    ↓ 1:1
user_profiles
    ↓ 1:many
folders (self-referencing hierarchy)
    ↓ 1:many
conversations
    ↓ 1:many
messages (with optional threading)

auth.users
    ↓ 1:many
api_keys (unique per provider)

conversations
    ↓ 1:many
conversation_exports

auth.users
    ↓ 1:many
conversation_templates
```

## Indexes

### Performance Indexes
- **user_profiles**: user_id, subscription_tier
- **folders**: user_id, parent_folder_id, (user_id, parent_folder_id)
- **conversations**: user_id, folder_id, status, (user_id, updated_at DESC), (user_id, is_favorite), tags (GIN)
- **messages**: conversation_id, (conversation_id, created_at), role, created_at DESC, content (full-text search GIN)
- **api_keys**: user_id, provider, (user_id, is_active)

### Search Indexes
- **messages.content**: Full-text search using GIN index on to_tsvector('english', content)
- **conversations.tags**: GIN index for array operations

## Triggers and Functions

### Automatic Timestamp Updates
- All tables have `updated_at` triggers that automatically set the timestamp on UPDATE

### User Profile Creation
- `create_user_profile()`: Automatically creates user profile when user signs up in auth.users

### Conversation Statistics
- `update_conversation_stats()`: Maintains conversation message_count, total_tokens, estimated_cost, and last_message_at
- Triggered on INSERT, UPDATE, DELETE of messages

### Utility Functions
- `get_folder_hierarchy(UUID)`: Returns folder hierarchy with levels and paths
- `create_sample_data_for_user(UUID)`: Creates sample data for development/testing
- `get_user_stats(UUID)`: Returns user statistics summary
- `search_messages(UUID, TEXT, INTEGER)`: Full-text search across user's messages

## Security

### Row Level Security (RLS)
All tables have RLS policies ensuring users can only access their own data:

- **user_profiles**: Users can only see/modify their own profile
- **folders**: Users can only access their own folders
- **conversations**: Users can only access their own conversations
- **messages**: Users can only access messages from their own conversations
- **api_keys**: Users can only access their own API keys
- **conversation_exports**: Users can only access their own exports
- **conversation_templates**: Users can see public templates and their own private templates

### Data Encryption
- **API Keys**: Encrypted using pgcrypto before storage
- **Sensitive Metadata**: Can be encrypted in JSONB fields as needed

## Usage Examples

### Creating a New Conversation
```sql
-- Create conversation
INSERT INTO conversations (user_id, title, model_name, model_provider, model_settings)
VALUES (
    'user-uuid',
    'Python Learning Session',
    'gpt-4',
    'openai',
    '{"temperature": 0.7, "max_tokens": 2000}'::jsonb
);

-- Add initial message
INSERT INTO messages (conversation_id, role, content)
VALUES (
    'conversation-uuid',
    'user',
    'I want to learn Python programming. Where should I start?'
);
```

### Organizing with Folders
```sql
-- Create nested folder structure
INSERT INTO folders (user_id, name, color) 
VALUES ('user-uuid', 'Programming', '#3b82f6');

INSERT INTO folders (user_id, parent_folder_id, name, color)
VALUES ('user-uuid', 'parent-folder-uuid', 'Python Projects', '#10b981');

-- Move conversation to folder
UPDATE conversations 
SET folder_id = 'folder-uuid' 
WHERE id = 'conversation-uuid' AND user_id = 'user-uuid';
```

### Searching Messages
```sql
-- Search user's messages
SELECT * FROM search_messages(
    'user-uuid',
    'python functions',
    10
);
```

### Getting User Statistics
```sql
-- Get comprehensive user stats
SELECT * FROM get_user_stats('user-uuid');
```

## Migration Strategy

### Version 1.0 (Current)
- Basic schema with core functionality
- User profiles and conversations
- Folder organization
- API key management
- Export system
- Templates

### Future Versions
- **v1.1**: Add conversation sharing and collaboration
- **v1.2**: Add voice message support
- **v1.3**: Add image/file attachment metadata
- **v1.4**: Add conversation analytics and insights
- **v1.5**: Add custom model fine-tuning metadata

## Development Notes

### Sample Data
- Use `create_sample_data_for_user(user_id)` to create test data
- Sample data includes folders, conversations, messages, and templates
- All sample data is automatically linked to the provided user_id

### Performance Considerations
- Message content is indexed for full-text search
- Conversation statistics are maintained via triggers for fast queries
- Expired exports are automatically cleaned up
- Consider partitioning messages table for very large deployments

### Backup and Recovery
- All critical data relationships preserve referential integrity
- Soft deletes used where data recovery might be needed
- Foreign key cascades configured appropriately for cleanup

This schema provides a solid foundation for the AI Chat App with room for growth and optimization as the application scales.