# Supabase Setup Guide for AI Chat App

This guide will walk you through setting up Supabase backend for your AI Chat App.

## Prerequisites

- [x] Supabase CLI installed and updated (v2.24.3+)
- [x] Supabase project initialized locally (`supabase init` completed)
- [ ] Supabase cloud project created
- [ ] Environment variables configured

## Step 1: Create Supabase Cloud Project

1. **Visit Supabase Dashboard**: https://supabase.com/dashboard
2. **Sign in** with your GitHub account or email
3. **Click "New Project"**
4. **Configure Project Settings**:
   - **Organization**: Select or create your organization
   - **Name**: `ai-chat-app` (or your preferred name)
   - **Database Password**: Generate a strong password (SAVE THIS!)
   - **Region**: Choose closest to your users:
     - US East: `us-east-1` (Virginia)
     - US West: `us-west-1` (N. California)
     - Europe: `eu-west-1` (Ireland)
     - Asia: `ap-southeast-1` (Singapore)
   - **Pricing Plan**: Free (for development)

5. **Click "Create new project"**
6. **Wait 2-3 minutes** for project provisioning

## Step 2: Get Project Credentials

Once your project is ready:

1. **Go to Project Settings** → **API**
2. **Copy the following values**:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Project API Keys**:
     - `anon` `public` key (for client-side)
     - `service_role` `secret` key (for server-side, keep secure!)

## Step 3: Configure Environment Variables

1. **Copy `.env.example` to `.env`**:
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** with your actual values:
   ```bash
   # Replace with your actual Supabase credentials
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-actual-anon-key
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-actual-service-role-key
   ```

3. **Add OpenRouter API Key**:
   - Get your API key from: https://openrouter.ai/keys
   - Add to `.env`: `OPENROUTER_API_KEY=sk-or-v1-your-actual-key`

## Step 4: Link Local Project to Cloud

1. **Login to Supabase CLI**:
   ```bash
   supabase login
   ```

2. **Link your local project**:
   ```bash
   supabase link --project-ref your-project-id
   ```
   
   Replace `your-project-id` with the actual project ID from your Supabase dashboard URL.

3. **Verify connection**:
   ```bash
   supabase status
   ```

## Step 5: Database Schema Setup

The database schema includes these main tables:

### Core Tables
- **`users`** - User profiles and metadata
- **`conversations`** - Chat conversations
- **`messages`** - Individual chat messages  
- **`folders`** - Organization folders for chats
- **`api_keys`** - User's LLM provider API keys (encrypted)

### Key Features
- **Row Level Security (RLS)** for data isolation
- **Real-time subscriptions** for live chat updates
- **File storage** for attachments
- **Edge functions** for LLM API proxying

## Step 6: Configure Authentication

1. **In Supabase Dashboard** → **Authentication** → **Settings**
2. **Configure Site URL**:
   - Development: `http://localhost:3000`
   - Production: Your actual domain
3. **Enable Auth Providers**:
   - **Email/Password**: Already enabled
   - **Google OAuth**: 
     - Get credentials from Google Cloud Console
     - Add Client ID and Secret
   - **Apple OAuth** (for iOS):
     - Configure in Apple Developer Console
     - Add Service ID and Key

## Step 7: Configure Storage

1. **In Supabase Dashboard** → **Storage**
2. **Create Buckets**:
   - `chat-attachments` (private) - for file attachments
   - `user-avatars` (public) - for profile pictures
   - `exports` (private) - for chat exports

3. **Set Storage Policies**:
   - Users can only access their own files
   - File size limits: 10MB per file
   - Allowed types: images, documents, text files

## Step 8: Test Your Setup

1. **Start local development**:
   ```bash
   supabase start
   ```

2. **Open Supabase Studio**: http://localhost:54323
3. **Test database connection**
4. **Verify auth flows work**
5. **Test file upload to storage**

## Step 9: Production Deployment

When ready for production:

1. **Deploy database migrations**:
   ```bash
   supabase db push
   ```

2. **Deploy edge functions**:
   ```bash
   supabase functions deploy
   ```

3. **Update environment variables** in your deployment platform
4. **Configure custom domain** (optional)

## Security Checklist

- [ ] RLS policies enabled on all tables
- [ ] API keys stored securely (encrypted)
- [ ] CORS configured for your domains only  
- [ ] Rate limiting enabled
- [ ] Database backups configured
- [ ] SSL certificates valid
- [ ] Environment variables secured

## Troubleshooting

### Common Issues

**"Project not found" error**:
- Verify project ID is correct
- Check if you're logged in: `supabase login`

**Database connection failed**:
- Check if local Supabase is running: `supabase status`
- Verify credentials in `.env` file

**Auth not working**:
- Check Site URL in auth settings
- Verify redirect URLs are configured
- Check OAuth provider credentials

**Storage upload fails**:
- Verify bucket exists and policies are set
- Check file size and type restrictions
- Ensure user has proper permissions

### Useful Commands

```bash
# Check Supabase status
supabase status

# Reset local database
supabase db reset

# Generate TypeScript types
supabase gen types typescript --local > lib/types/supabase.dart

# View logs
supabase logs

# Stop all services
supabase stop
```

## Next Steps

After completing this setup:

1. **Create database schema** (Task 2.2)
2. **Set up Row Level Security** (Task 2.4)
3. **Configure Flutter Supabase client**
4. **Implement authentication flows**
5. **Build chat functionality**

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Client](https://supabase.com/docs/reference/dart/introduction)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [RLS Policy Examples](https://supabase.com/docs/guides/auth/row-level-security)

---

**Important**: Never commit your `.env` file or expose your service role key publicly!