import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';
import '../../services/attachment_service.dart';
import '../../services/file_picker_service.dart';

/// Core services module for dependency injection
@module
abstract class CoreModule {
  /// Provide Supabase client instance
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;

  /// Provide storage service
  @singleton
  StorageService storageService(SupabaseClient supabaseClient) =>
      StorageService(supabaseClient);

  /// Provide file picker service
  @singleton
  FilePickerService get filePickerService => FilePickerService();

  /// Provide attachment service
  @singleton
  AttachmentService attachmentService(
    StorageService storageService,
    FilePickerService filePickerService,
  ) => AttachmentService(
    storageService: storageService,
    filePickerService: filePickerService,
  );

  /// Development-specific storage service (with enhanced logging)
  @Environment(Environment.dev)
  @Named('dev_storage')
  @singleton
  StorageService devStorageService(SupabaseClient supabaseClient) =>
      StorageService(supabaseClient);

  /// Test storage service (potentially with mocks)
  @Environment(Environment.test)
  @Named('test_storage')
  @singleton
  StorageService testStorageService(SupabaseClient supabaseClient) =>
      StorageService(supabaseClient);

  /// Production storage service (optimized)
  @Environment(Environment.prod)
  @Named('prod_storage')
  @singleton
  StorageService prodStorageService(SupabaseClient supabaseClient) =>
      StorageService(supabaseClient);
}
