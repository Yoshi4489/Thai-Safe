import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService() {
    _initCloudinary();
  }

  void _initCloudinary() {
    CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
      cloudName: dotenv.env['CLOUD_NAME']!,
    );
  }

  Future<String> uploadImage(File imageFile) async {
    final cloudName = dotenv.env['CLOUD_NAME']!;
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Cloudinary upload failed");
    }

    final responseData = await response.stream.bytesToString();
    final jsonMap = jsonDecode(responseData);

    return jsonMap['secure_url'];
  }
}
