import 'dart:convert';
import 'dart:io';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:googleapis_auth/auth_io.dart';

Future<String> uploadProfileImageToGCS(Uint8List imageBytes, String userId) async {
  final accountCredentials = ServiceAccountCredentials.fromJson(
    Platform.environment['587e882b1d3452150b9607941e910c47ca55c26b']!,
  );
  final scopes = [gcs.StorageApi.devstorageFullControlScope];
  final client = await clientViaServiceAccount(accountCredentials, scopes);

  final storage = gcs.StorageApi(client);
  final bucket = Platform.environment['photoaid17']!;

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

