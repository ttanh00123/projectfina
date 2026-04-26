// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:taexpense/services/auth_service.dart';
// import 'package:taexpense/session.dart';
// // import '../services/auth_provider.dart';
// import '../theme/app_theme.dart';
// import 'login_screen.dart';

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = Session.user;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         // Avatar card
//         Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(colors: [kPrimary, kPrimaryL],
//               begin: Alignment.topLeft, end: Alignment.bottomRight),
//             borderRadius: BorderRadius.circular(20)),
//           child: Row(children: [
//             Container(width: 56, height: 56,
//               decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
//                 shape: BoxShape.circle),
//               child: Center(child: Text(
//                 user?.displayName?.isNotEmpty == true ? user!.displayName!.toUpperCase() : '?',
//                 style: GoogleFonts.spaceGrotesk(
//                   fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)))),
//             const SizedBox(width: 16),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(user?.displayName ?? '—', style: GoogleFonts.spaceGrotesk(
//                 fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
//               Text(user?.email ?? '', style: GoogleFonts.dmSans(
//                 fontSize: 13, color: Colors.white70)),
//               const SizedBox(height: 4),
//               // Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//               //   decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
//               //     borderRadius: BorderRadius.circular(20)),
//               //   child: Text('${user?.currencyCode ?? ''} · ${user?.countryCode ?? ''}',
//               //     style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white,
//               //       fontWeight: FontWeight.w600))),
//             ])),
//           ]),
//         ),
//         const SizedBox(height: 24),

//         // Info tiles
//         _Section(title: 'Account Info', tiles: [
//           _InfoTile(icon: Icons.badge_outlined, label: 'Name', value: user?.displayName ?? '—'),
//           _InfoTile(icon: Icons.mail_outlined, label: 'Email', value: user?.email ?? '—'),
//           _InfoTile(icon: Icons.wc_rounded, label: 'Gender',
//             value: {'M':'Male','F':'Female','O':'Other'}[user?.gender] ?? '—'),
//           // _InfoTile(icon: Icons.cake_outlined, label: 'Birthday',
//           //   value: user != null ? DateFormat('dd MMM yyyy').format(user.birthDate) : '—'),
//         ]),
//         const SizedBox(height: 16),

//         // _Section(title: 'Preferences', tiles: [
//         //   _InfoTile(icon: Icons.currency_exchange_rounded, label: 'Currency',
//         //     value: user?.currencyCode ?? '—'),
//         //   _InfoTile(icon: Icons.public_rounded, label: 'Country',
//         //     value: {'VN':'🇻🇳 Vietnam','SG':'🇸🇬 Singapore','US':'🇺🇸 United States'}[user?.countryCode] ?? '—'),
//         // ]),
//         const SizedBox(height: 16),

//         // Logout
//         _Section(title: 'Account', tiles: [
//           _ActionTile(
//             icon: Icons.logout_rounded, label: 'Sign Out', color: kError,
//             onTap: () async {
//               final confirmed = await showDialog<bool>(context: context,
//                 builder: (_) => AlertDialog(
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
//                   content: Text('Are you sure you want to sign out?', style: GoogleFonts.dmSans()),
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(context, false),
//                       child: Text('Cancel', style: GoogleFonts.dmSans(color: kSubtext))),
//                     TextButton(onPressed: () => Navigator.pop(context, true),
//                       child: Text('Sign Out', style: GoogleFonts.dmSans(
//                         color: kError, fontWeight: FontWeight.w700))),
//                   ],
//                 ));
//               if (confirmed == true && context.mounted) {
//                 await logout(context);
//                 Navigator.pushAndRemoveUntil(context,
//                   MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
//               }
//             },
//           ),
//         ]),
//         const SizedBox(height: 40),
//         Center(child: Text('FinA v1.0.0', style: GoogleFonts.dmSans(
//           color: kSubtext.withOpacity(0.5), fontSize: 12))),
//       ]),
//     );
//   }
// }

// class _Section extends StatelessWidget {
//   final String title;
//   final List<Widget> tiles;
//   const _Section({required this.title, required this.tiles});
//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Padding(padding: const EdgeInsets.only(left: 4, bottom: 10),
//         child: Text(title, style: GoogleFonts.spaceGrotesk(
//           fontSize: 13, fontWeight: FontWeight.w700,
//           color: kSubtext, letterSpacing: 0.5))),
//       Container(
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
//             blurRadius: 8, offset: const Offset(0, 2))]),
//         child: Column(children: [
//           for (int i = 0; i < tiles.length; i++) ...[
//             tiles[i],
//             if (i < tiles.length - 1)
//               Divider(height: 1, color: kBorder.withOpacity(0.5),
//                 indent: 52, endIndent: 16),
//           ],
//         ]),
//       ),
//     ],
//   );
// }

// class _InfoTile extends StatelessWidget {
//   final IconData icon; final String label, value;
//   const _InfoTile({required this.icon, required this.label, required this.value});
//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//     child: Row(children: [
//       Icon(icon, size: 20, color: kPrimary),
//       const SizedBox(width: 14),
//       Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: kSubtext)),
//       const Spacer(),
//       Text(value, style: GoogleFonts.dmSans(
//         fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
//     ]),
//   );
// }

// class _ActionTile extends StatelessWidget {
//   final IconData icon; final String label; final Color color; final VoidCallback onTap;
//   const _ActionTile({required this.icon, required this.label,
//     required this.color, required this.onTap});
//   @override
//   Widget build(BuildContext context) => InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(16),
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       child: Row(children: [
//         Icon(icon, size: 20, color: color),
//         const SizedBox(width: 14),
//         Text(label, style: GoogleFonts.dmSans(
//           fontSize: 14, fontWeight: FontWeight.w600, color: color)),
//         const Spacer(),
//         Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
//       ]),
//     ),
//   );
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/locale_provider.dart';
import 'package:taexpense/services/auth_service.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/settings_service.dart';
import 'package:taexpense/session.dart';
import '../theme/app_theme.dart';
import '../utils/app_settings.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String locale = 'vi';
  String currency = 'VND';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    locale = await SettingsService.getLocale();
    currency = await SettingsService.getCurrency();
    setState(() {});
  }

  Future<void> _changeLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true, 
      isScrollControlled: true, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option('Tiếng Việt', 'vi'),
            _option('English', 'en'),
          ],
        ),
      ),
    );

    if (result != null) {
      await SettingsService.setLocale(result);
      await AppSettings.load();

      //Sync Master Data với locale mới
      await MasterDataStore().sync(await AuthStorage.getToken() ?? '', locale: result);

      await context.read<LocaleProvider>().setLocale(Locale(result));

      setState(() => locale = result); 
    }
  }

  Future<void> _changeCurrency() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true, 
      isScrollControlled: true, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option('VND (₫)', 'VND'),
            _option('USD (\$)', 'USD'),
          ],
        ),
      ),
    );

    if (result != null) {
      await SettingsService.setCurrency(result);
      await AppSettings.load();
      setState(() => currency = result);
    }
  }

  Widget _option(String text, String value) {
    return ListTile(
      title: Text(text, style: GoogleFonts.dmSans()),
      onTap: () => Navigator.pop(context, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        /// Avatar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName!.substring(0, 1).toUpperCase()
                      : '?',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.displayName ?? '—',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(user?.email ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.white70)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        /// Account Info
        _Section(title: 'Account Info', tiles: [
          _InfoTile(icon: Icons.badge_outlined, label: 'Name', value: user?.displayName ?? '—'),
          _InfoTile(icon: Icons.mail_outlined, label: 'Email', value: user?.email ?? '—'),
          _InfoTile(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: {'M': 'Male', 'F': 'Female', 'O': 'Other'}[user?.gender] ?? '—',
          ),
        ]),

        const SizedBox(height: 16),

        /// Preferences (NEW)
        _Section(title: 'Preferences', tiles: [
          _ActionTile(
            icon: Icons.language,
            label: 'Language',
            color: kText,
            value: locale == 'vi' ? 'Tiếng Việt' : 'English',
            onTap: _changeLanguage,
          ),
          _ActionTile(
            icon: Icons.attach_money,
            label: 'Currency',
            color: kText,
            value: currency,
            onTap: _changeCurrency,
          ),
        ]),

        const SizedBox(height: 16),

        /// Logout
        _Section(title: 'Account', tiles: [
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: kError,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                  content: Text('Are you sure?', style: GoogleFonts.dmSans()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await logout(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ]),

        const SizedBox(height: 40),
        Center(child: Text('FinA v1.0.0',
            style: GoogleFonts.dmSans(color: kSubtext.withOpacity(0.5), fontSize: 12))),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kSubtext)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: tiles),
          ),
        ],
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: kPrimary),
        title: Text(label, style: GoogleFonts.dmSans()),
        trailing: Text(value, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(label, style: GoogleFonts.dmSans()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(value!, style: GoogleFonts.dmSans(color: kSubtext)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: kSubtext),
          ],
        ),
      );
}