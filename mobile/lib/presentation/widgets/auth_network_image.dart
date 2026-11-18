import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/core/api_config.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Gambar dari API yang butuh `Authorization: Bearer`.
class AuthNetworkImage extends StatelessWidget {
  const AuthNetworkImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Path relatif seperti `/history/{id}/photos/front`.
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthCubit>().accessToken;
    final url = path.startsWith('http')
        ? path
        : '${ApiConfig.baseUrl}$path';

    final image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      headers: {
        'Accept': 'image/*',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      errorBuilder: (context, error, stack) {
        debugPrint('AuthNetworkImage error: $error');
        return ColoredBox(
          color: AppColors.muted,
          child: SizedBox(
            width: width,
            height: height,
            child: const Icon(
              LucideIcons.imageOff,
              color: AppColors.inkMuted,
              size: 22,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: AppColors.muted,
          child: SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(size: 18),
            ),
          ),
        );
      },
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
