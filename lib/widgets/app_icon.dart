// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../theme/app_theme.dart';

// /// Widget hiển thị icon của ứng dụng nằm trong hình tròn xanh với hiệu ứng đổ bóng.
// class AppIcon extends StatelessWidget {
//   /// Kích thước của toàn bộ Widget (đường kính hình tròn).
//   final double size;

//   /// Đường dẫn asset của tệp SVG.
//   // final String svgPath;

//   /// Màu sắc của hình tròn.
//   final Color? backgroundColor;

//   /// Màu sắc của icon.
//   final Color iconColor;

//   const AppIcon({
//     super.key,
//     this.size = 32.0,
//     // this.svgPath = 'assets/icon/fina_icon.svg',
//     this.backgroundColor,
//     this.iconColor = Colors.white,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // final themeBgColor = backgroundColor ?? Colors.blue[600]!;

//     return Container(
//       height: size,
//       width: size,
//       decoration: BoxDecoration(
//         color: kPrimary,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: kPrimary.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       // Center giúp icon không bị dãn tràn ra toàn bộ Container
//       child: Center(
//         child: SvgPicture.asset(
//           'assets/icon/fina_icon.svg',
//           width: size * 0.55,
//           height: size * 0.55,
//           colorFilter: ColorFilter.mode(
//             iconColor,
//             BlendMode.srcIn,
//           ),
//         ),
//       ),
//     );
//   }
// }