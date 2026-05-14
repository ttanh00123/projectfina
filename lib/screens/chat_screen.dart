import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/services/prompt_service.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'create_transaction_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ── Message model ─────────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser;
  final PromptResult? result;
  final bool isLoading;
  _Msg(
      {required this.text,
      required this.isUser,
      this.result,
      this.isLoading = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _stt = SpeechToText();
  final List<_Msg> _msgs = [];
  // Sử dụng getter để truy cập localization thông qua context của State
  AppLocalizations get t => AppLocalizations.of(context)!;

  bool _sttReady = false, _listening = false;
  late AnimationController _micAnim;

  @override
  void initState() {
    super.initState();
    _micAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _initStt();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scroll.dispose();
    _micAnim.dispose();
    super.dispose();
  }

  Future<void> _initStt() async {
    _sttReady = await _stt.initialize(
        onError: (_) => setState(() => _listening = false));

    t.chatbotWelcomeMessage; // Truy cập để đảm bảo localization đã sẵn sàng
    _addBot(t.chatbotWelcomeMessage);

    setState(() {});
  }

  void _addBot(String text, {PromptResult? result}) {
    setState(() => _msgs.add(_Msg(text: text, isUser: false, result: result)));
    _scrollDown();
  }

  void _addUser(String text) {
    setState(() => _msgs.add(_Msg(text: text, isUser: true)));
    _scrollDown();
  }

  void _addLoading() {
    setState(() => _msgs.add(_Msg(text: '', isUser: false, isLoading: true)));
    _scrollDown();
  }

  void _removeLoading() {
    setState(() {
      _msgs.removeWhere((m) => m.isLoading);
    });
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _textCtrl.clear();
    _addUser(t);
    _addLoading();

    // final auth = context.read<AuthProvider>();
    final token = Session.token!;
    final userId = Session.user!.id;

    try {
      final result = await sendPrompt(t, userId!, token);
      _removeLoading();
      final d = result.data;
      // final amtFmt = NumberFormat('#,##0', 'vi_VN').format(d.amount);
      
      // // final dtFormatted = _formatDt(d.dateTime);
      // final botText = '${d.type == 0 ? '🛒 **Chi tiêu**' : '💰 **Thu nhập**'}\n'
      //     'Số tiền: **$amtFmt ${d.currency}**\n'
      //     '${d.address != null ? 'Địa điểm: **${d.address}**\n' : ''}';
      // 'Ví: ${d.wallet}\n'
      // 'Thời gian: $dtFormatted';

      final botText = formatTransactionText(d);
      _addBot(botText, result: result);
    } on ApiException catch (e) {
      _removeLoading();
      _addBot('❌ Error: ${e.message}');
    } catch (_) {
      _removeLoading();
      _addBot('❌ Cannot connect to server. Please try again.');
    }
  }

  String formatTransactionText(dynamic d) {
    // 2. Xác định symbol, nếu không có trong map thì dùng chính mã currency
    final symbol = kCurrencySymbols[d.currency] ?? d.currency;

    // 3. Logic định dạng số tiền
    String amtFmt;
    if (d.currency == 'VND') {
      // VND: Định dạng phân cách hàng ngàn, không có số thập phân
      amtFmt = NumberFormat('#,##0', 'vi_VN').format(d.amount);
    } else {
      // Các loại khác: Định dạng phân cách hàng ngàn và luôn có 2 số thập phân
      // Sử dụng 'en_US' làm locale để đảm bảo dấu phân cách thập phân là dấu chấm
      amtFmt = NumberFormat('#,##0.00', 'en_US').format(d.amount);
    }

    // 4. Xây dựng nội dung text
    final typeIcon = d.type == 0 ? '🛒 **Chi tiêu**' : '💰 **Thu nhập**';
    
    // Hiển thị dạng: 8.00 S$ hoặc 200,000 ₫
    final botText = '$typeIcon\n'
        'Số tiền: **$amtFmt $symbol**\n'
        '${d.address != null && d.address!.isNotEmpty ? 'Địa điểm: **${d.address}**\n' : ''}';
    
    return botText;
  }

  String _formatDt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm, dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _toggleMic() async {
    if (!_sttReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Microphone not available on this device')));
      return;
    }
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      await _stt.listen(
        onResult: (r) {
          _textCtrl.text = r.recognizedWords;
          if (r.finalResult) {
            setState(() => _listening = false);
            if (r.recognizedWords.trim().isNotEmpty) _send(r.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'vi_VN',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.chatbotName,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
              Text('AI powered',
                  style: GoogleFonts.dmSans(fontSize: 11, color: kPrimary)),
            ]),
          ]),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: kText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _msgs.length,
                itemBuilder: (_, i) => _BubbleWidget(
                    msg: _msgs[i],
                    onConfirm: (r) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CreateTransactionScreen(prefill: r.data)));
                    }),
              ),
            ),
            _InputBar(
              ctrl: _textCtrl,
              hint: t.chatInputHint,
              listeningText: t.listeningText,
              listening: _listening,
              micAnim: _micAnim,
              onSend: () => _send(_textCtrl.text),
              onMic: _toggleMic,
            ),
          ]),
        ),
      );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────
class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  final ValueChanged<PromptResult> onConfirm;
  const _BubbleWidget({required this.msg, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    if (msg.isLoading) return _LoadingBubble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Column(
            crossAxisAlignment:
                msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: _BubbleText(text: msg.text, isUser: msg.isUser),
              ),
              if (msg.result != null) ...[
                const SizedBox(height: 8),
                _ConfirmButton(onTap: () => onConfirm(msg.result!)),
              ],
            ],
          )),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _BubbleText extends StatelessWidget {
  final String text;
  final bool isUser;
  const _BubbleText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // Parse simple **bold** markdown
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style:
            TextStyle(fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400),
      ));
    }
    return RichText(
        text: TextSpan(
      style: GoogleFonts.dmSans(
          fontSize: 14.5, color: isUser ? Colors.white : kText, height: 1.55),
      children: spans,
    ));
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text('Xác nhận & Lưu',
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ]),
        ),
      );
}

class _LoadingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: kPrimary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < 3; i++) ...[
                _Dot(delay: i * 200),
                if (i < 2) const SizedBox(width: 4),
              ],
            ]),
          ),
        ]),
      );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -6.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anim.value),
          child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.6), shape: BoxShape.circle)),
        ),
      );
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool listening;
  final String hint, listeningText;
  final AnimationController micAnim;
  final VoidCallback onSend, onMic;
  const _InputBar(
      {required this.ctrl,
      required this.listening,
      required this.micAnim,
      required this.onSend,
      required this.onMic, 
      required this.hint,
      required this.listeningText});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(children: [
          if (listening)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: micAnim,
                builder: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: kError.withOpacity(0.08 + micAnim.value * 0.07),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.mic, color: kError, size: 16),
                    const SizedBox(width: 6),
                    Text(listeningText,
                        style: GoogleFonts.dmSans(
                            color: kError,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: TextField(
              controller: ctrl,
              minLines: 1,
              maxLines: 4,
              style: GoogleFonts.dmSans(fontSize: 15, color: kText),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(color: kSubtext, fontSize: 15),
                filled: true,
                fillColor: kBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kPrimary, width: 1.5)),
              ),
              onSubmitted: (_) => onSend(),
            )),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: onSend,
              child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: kPrimary, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18)),
            ),
            const SizedBox(width: 10),
            // Mic button
            GestureDetector(
              onTap: onMic,
              child: AnimatedBuilder(
                animation: micAnim,
                builder: (_, __) => Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: listening
                        ? Color.lerp(
                            kError, const Color(0xFFFF6B6B), micAnim.value)!
                        : kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: listening
                        ? [
                            BoxShadow(
                                color: kError
                                    .withOpacity(0.3 + micAnim.value * 0.2),
                                blurRadius: 12 + micAnim.value * 8,
                                spreadRadius: 2)
                          ]
                        : [],
                  ),
                  child: Icon(
                      listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: listening ? Colors.white : kPrimary,
                      size: 24),
                ),
              ),
            ),
          ]),
        ]),
      );
}
