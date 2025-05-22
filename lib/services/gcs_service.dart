import 'dart:typed_data';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as gcs;


Future<String> uploadProfileImageToGCS(Uint8List imageBytes, String userId) async {
  print('[GCS] Starting upload for user: $userId');
  try {
  final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
} catch (e) {
  print('[GCS] ERROR: Failed to parse credentials JSON: $e');
}
  if (credentialsJson == null) {
    print('[GCS] ERROR: GOOGLE_APPLICATION_CREDENTIALS_JSON not set');
    throw Exception('GOOGLE_APPLICATION_CREDENTIALS_JSON not set');
  }
  print('[GCS] Credentials loaded');

  final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
  final scopes = [gcs.StorageApi.devstorageFullControlScope];
  final client = await clientViaServiceAccount(credentials, scopes);

  print('[GCS] Authenticated client created');
  final storage = gcs.StorageApi(client);
  final bucket = Platform.environment['GCS_BUCKET'];
  if (bucket == null) {
    print('[GCS] ERROR: GCS_BUCKET not set');
    throw Exception('GCS_BUCKET not set');
  }
  print('[GCS] Bucket: $bucket');

  final objectName = 'profile_images/$userId.jpg';
  final media = gcs.Media(Stream.value(imageBytes), imageBytes.length, contentType: 'image/jpeg');
  print('[GCS] Uploading to GCS: $objectName');
  await storage.objects.insert(
    gcs.Object()..name = objectName,
    bucket,
    uploadMedia: media,
  );
  print('[GCS] Upload complete');

  client.close();

  final url = 'https://storage.googleapis.com/$bucket/$objectName';
  print('[GCS] Public URL: $url');
  return url;
}
