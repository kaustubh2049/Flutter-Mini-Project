import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'property-images';

  /// Upload a single image file to Supabase Storage.
  ///
  /// [file]       - The image File picked via image_picker
  /// [folder]     - Organise by owner UID (e.g., "uid123/filename.jpg")
  ///
  /// Returns the public URL string of the uploaded image.
  Future<String> uploadPropertyImage({
    required File file,
    required String ownerUid,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$ext'; // unique name
    final storagePath = '$ownerUid/$fileName'; // e.g. uid123/1700000000.jpg

    // Upload the file bytes
    await _client.storage.from(_bucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false, // never overwrite
          ),
        );

    // Return the public URL
    final publicUrl =
        _client.storage.from(_bucket).getPublicUrl(storagePath);

    return publicUrl;
  }

  /// Upload multiple images at once (for the Add Property form).
  /// Returns a list of public URLs.
  Future<List<String>> uploadMultipleImages({
    required List<File> files,
    required String ownerUid,
  }) async {
    final List<String> urls = [];

    for (final file in files) {
      final url = await uploadPropertyImage(
        file: file,
        ownerUid: ownerUid,
      );
      urls.add(url);
    }

    return urls;
  }

  /// Delete an image from storage by its public URL.
  Future<void> deleteImage(String publicUrl) async {
    // Extract the storage path from the public URL
    // Public URL format: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
    final uri = Uri.parse(publicUrl);
    final pathSegments = uri.pathSegments;
    // pathSegments: ['storage','v1','object','public','property-images','uid','file.jpg']
    final bucketIndex = pathSegments.indexOf(_bucket);
    if (bucketIndex == -1) return;

    final storagePath =
        pathSegments.sublist(bucketIndex + 1).join('/');

    await _client.storage.from(_bucket).remove([storagePath]);
  }
}
