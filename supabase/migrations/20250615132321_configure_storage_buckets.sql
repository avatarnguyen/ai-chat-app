-- =====================================================
-- Storage Buckets Configuration for File Attachments
-- =====================================================
-- This migration configures Supabase Storage buckets for handling
-- file attachments in chat conversations with proper security policies.

-- =====================================================
-- CREATE STORAGE BUCKETS
-- =====================================================

-- Create bucket for chat attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat-attachments',
    'chat-attachments',
    false, -- Private bucket
    52428800, -- 50MB limit
    ARRAY[
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'image/svg+xml',
        'text/plain',
        'text/markdown',
        'text/csv',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/json',
        'application/xml',
        'application/zip',
        'application/x-zip-compressed',
        'audio/mpeg',
        'audio/wav',
        'audio/ogg',
        'audio/webm',
        'video/mp4',
        'video/webm',
        'video/quicktime'
    ]
);

-- Create bucket for user avatars (public for easy access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true, -- Public bucket for avatars
    5242880, -- 5MB limit for avatars
    ARRAY[
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp'
    ]
);

-- Create bucket for exported conversations
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'conversation-exports',
    'conversation-exports',
    false, -- Private bucket
    104857600, -- 100MB limit for exports
    ARRAY[
        'application/json',
        'text/markdown',
        'application/pdf',
        'text/csv',
        'application/zip'
    ]
);

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Policy for chat-attachments bucket
-- Users can only access their own attachments

-- Allow users to upload attachments to their own folder
CREATE POLICY "Users can upload attachments to their own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own attachments
CREATE POLICY "Users can view their own attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own attachments
CREATE POLICY "Users can update their own attachments"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own attachments
CREATE POLICY "Users can delete their own attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'chat-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for avatars bucket
-- Users can manage their own avatars, but everyone can view them

-- Allow users to upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow everyone to view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Allow users to update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for conversation-exports bucket
-- Users can only access their own exports

-- Allow users to upload their own exports
CREATE POLICY "Users can upload their own exports"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'conversation-exports' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own exports
CREATE POLICY "Users can view their own exports"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'conversation-exports' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own exports
CREATE POLICY "Users can delete their own exports"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'conversation-exports' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to clean up expired exports
CREATE OR REPLACE FUNCTION cleanup_expired_exports()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Delete storage objects for expired exports
    DELETE FROM storage.objects
    WHERE bucket_id = 'conversation-exports'
    AND created_at < NOW() - INTERVAL '7 days';

    -- Update conversation_exports table to reflect deletion
    UPDATE conversation_exports
    SET status = 'expired',
        file_url = NULL
    WHERE expires_at < NOW()
    AND status = 'completed';
END;
$$;

-- Function to get file size in human readable format
CREATE OR REPLACE FUNCTION format_file_size(size_bytes BIGINT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF size_bytes < 1024 THEN
        RETURN size_bytes || ' B';
    ELSIF size_bytes < 1024 * 1024 THEN
        RETURN ROUND(size_bytes / 1024.0, 1) || ' KB';
    ELSIF size_bytes < 1024 * 1024 * 1024 THEN
        RETURN ROUND(size_bytes / (1024.0 * 1024.0), 1) || ' MB';
    ELSE
        RETURN ROUND(size_bytes / (1024.0 * 1024.0 * 1024.0), 1) || ' GB';
    END IF;
END;
$$;

-- =====================================================
-- SCHEDULED CLEANUP
-- =====================================================

-- Create a trigger to automatically clean up expired exports
-- This will be called daily via a cron job or edge function
CREATE OR REPLACE FUNCTION schedule_cleanup_expired_exports()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- This function can be called by a cron job or edge function
    -- to clean up expired exports on a schedule
    PERFORM cleanup_expired_exports();
END;
$$;

-- =====================================================
-- STORAGE TRIGGERS
-- =====================================================

-- Function to update file metadata when storage object is created
CREATE OR REPLACE FUNCTION update_message_attachment_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_uuid UUID;
    conversation_uuid UUID;
    message_uuid UUID;
    file_info JSONB;
BEGIN
    -- Extract user_id from the storage path
    user_uuid := (storage.foldername(NEW.name))[1]::UUID;

    -- Extract conversation_id and message_id from the storage path if available
    -- Path format: user_id/conversation_id/message_id/filename
    IF array_length(storage.foldername(NEW.name), 1) >= 3 THEN
        conversation_uuid := (storage.foldername(NEW.name))[2]::UUID;
        message_uuid := (storage.foldername(NEW.name))[3]::UUID;

        -- Create file info JSONB
        file_info := jsonb_build_object(
            'file_name', NEW.name,
            'file_size', NEW.metadata->>'size',
            'mime_type', NEW.metadata->>'mimetype',
            'bucket_id', NEW.bucket_id,
            'uploaded_at', NOW()
        );

        -- Update message metadata if message exists
        UPDATE messages
        SET metadata = COALESCE(metadata, '{}'::jsonb) ||
                      jsonb_build_object('attachments',
                          COALESCE(metadata->'attachments', '[]'::jsonb) ||
                          jsonb_build_array(file_info)
                      ),
            updated_at = NOW()
        WHERE id = message_uuid
        AND conversation_id = conversation_uuid;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger for chat-attachments bucket
CREATE TRIGGER on_attachment_upload
    AFTER INSERT ON storage.objects
    FOR EACH ROW
    WHEN (NEW.bucket_id = 'chat-attachments')
    EXECUTE FUNCTION update_message_attachment_metadata();

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Index on storage objects for faster bucket queries
CREATE INDEX IF NOT EXISTS idx_storage_objects_bucket_id
ON storage.objects(bucket_id);

-- Index on storage objects for user-specific queries
CREATE INDEX IF NOT EXISTS idx_storage_objects_user_folder
ON storage.objects(bucket_id, (storage.foldername(name))[1]);

-- =====================================================
-- COMMENTS AND DOCUMENTATION
-- =====================================================

COMMENT ON TABLE storage.buckets IS 'Storage buckets for file attachments, avatars, and exports';

COMMENT ON FUNCTION cleanup_expired_exports() IS 'Removes expired export files from storage and updates database records';

COMMENT ON FUNCTION format_file_size(BIGINT) IS 'Converts file size in bytes to human-readable format';

COMMENT ON FUNCTION update_message_attachment_metadata() IS 'Updates message metadata when file attachments are uploaded';

-- =====================================================
-- SAMPLE STORAGE PATHS
-- =====================================================

/*
Storage path patterns:

Chat Attachments:
- chat-attachments/{user_id}/{conversation_id}/{message_id}/{filename}
- Example: chat-attachments/123e4567-e89b-12d3-a456-426614174000/456e7890-e89b-12d3-a456-426614174001/789e0123-e89b-12d3-a456-426614174002/document.pdf

Avatars:
- avatars/{user_id}/{filename}
- Example: avatars/123e4567-e89b-12d3-a456-426614174000/profile.jpg

Conversation Exports:
- conversation-exports/{user_id}/{export_id}/{filename}
- Example: conversation-exports/123e4567-e89b-12d3-a456-426614174000/exp123-456/conversation_export.json
*/
