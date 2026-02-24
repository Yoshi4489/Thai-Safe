import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/services/cloudinary_service.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (ref) => CloudinaryService()
);
