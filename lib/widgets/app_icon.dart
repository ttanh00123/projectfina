import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget hiển thị icon của ứng dụng nằm trong hình tròn xanh với hiệu ứng đổ bóng.
class AppIcon extends StatelessWidget {
  /// Kích thước của toàn bộ Widget (đường kính hình tròn).
  final double size;

  /// Kích thước của icon bên trong hình tròn.
  final double iconSize;

  /// Đường dẫn asset của tệp SVG.
  final String svgPath;

  /// Màu sắc của hình tròn.
  final Color? backgroundColor;

  /// Màu sắc của icon.
  final Color iconColor;

  const AppIcon({
    super.key,
    this.size = 80.0,
    this.iconSize = 40.0,
    this.svgPath = 'assets/icon/fina_icon.svg',
    this.backgroundColor,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final themeBgColor = backgroundColor ?? Colors.blue[600]!;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: themeBgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeBgColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Center giúp icon không bị dãn tràn ra toàn bộ Container
      child: Center(
        child: SvgPicture.asset(
          svgPath,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            iconColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}