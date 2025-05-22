import 'dart:typed_data';
import 'dart:io';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:googleapis_auth/auth_io.dart';

Future<String> uploadProfileImageToGCS(Uint8List imageBytes, String userId) async {
  final credentialsJson = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS_JSON'];
  if (credentialsJson == null) {
    throw Exception('GOOGLE_APPLICATION_CREDENTIALS_JSON not set');
  }
  final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
  final scopes = [gcs.StorageApi.devstorageFullControlScope];
  final client = await clientViaServiceAccount(credentials, scopes);

  final storage = gcs.StorageApi(client);
  final bucket = Platform.environment['GCS_BUCKET'];
  if (bucket == null) {
    throw Exception('GCS_BUCKET not set');
  }

  final objectName = 'profile_images/$userId.jpg';
  final media = gcs.Media(Stream.value(imageBytes), imageBytes.length, contentType: 'image/jpeg');
  await storage.objects.insert(
    gcs.Object()..name = objectName,
    bucket,
    uploadMedia: media,
  );

  client.close();

  // Public URL (if bucket/object is public)
  return 'https://storage.googleapis.com/$bucket/$objectName';
}
