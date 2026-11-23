import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MegaCalcApp());
}

class MegaCalcApp extends StatelessWidget {
  const MegaCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ماشین‌حساب فضایی‌ها',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: CalculatorScreen(),
      ),
    );
  }
}

class _BigDecimal {
  final BigInt val;
  final int scale;
  const _BigDecimal(this.val, this.scale);
}

class _Token {
  final bool isOp;
  final String? op;
  final _BigDecimal? bd;
  const _Token.num(this.bd)
      : isOp = false,
        op = null;
  const _Token.op(this.op)
      : isOp = true,
        bd = null;
}

class _ScalePart {
  final int value;
  final String unit;
  final bool highTier;
  const _ScalePart(this.value, this.unit, this.highTier);
}

class _OfflineVideoGate extends StatefulWidget {
  final Color neonCyan;
  final Color neonPurple;
  final bool isCheckingNet;
  final VoidCallback onRetry;

  const _OfflineVideoGate({
    required this.neonCyan,
    required this.neonPurple,
    required this.isCheckingNet,
    required this.onRetry,
  });

  @override
  State<_OfflineVideoGate> createState() => _OfflineVideoGateState();
}

class _OfflineVideoGateState extends State<_OfflineVideoGate> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/spacial_calculator.mp4');
    await _controller.initialize();
    await _controller.setLooping(false);
    await _controller.setVolume(1.0); // متصل به ولوم مدیای گوشی کاربر
    _controller.addListener(_onVideoTick);
    if (!mounted) return;
    setState(() {
      _initialized = true;
      _isPlaying = true;
    });
    await _controller.play();
  }

  void _onVideoTick() {
    if (!mounted) return;
    final playing = _controller.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  Future<void> _replayVideo() async {
    if (!_initialized) return;
    await _controller.seekTo(Duration.zero);
    await _controller.setVolume(1.0);
    await _controller.play();
    if (mounted) {
      setState(() => _isPlaying = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _initialized
                    ? InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const CircularProgressIndicator(
                        color: Color(0xFF00F5D4),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _replayVideo,
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        height: 52,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPlaying
                                ? widget.neonPurple.withOpacity(0.55)
                                : widget.neonCyan,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: _isPlaying
                              ? widget.neonPurple
                              : widget.neonCyan,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.neonCyan,
                          foregroundColor: const Color(0xFF070A12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                            widget.isCheckingNet ? null : widget.onRetry,
                        child: widget.isCheckingNet
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF070A12),
                                ),
                              )
                            : const Text(
                                'تلاش مجدد',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with WidgetsBindingObserver {
  static const List<String> _scaleNames = [
    "",
    "هزار",
    "میلیون",
    "میلیارد",
    "تریلیون (هزار میلیارد / همت)",
    "کوادریلیون (میلیون میلیارد)",
    "کوینتیلیون (میلیارد میلیارد)",
    "سکستیلیون",
    "سپتیلیون",
    "اکتیلیون",
    "نونیلیون",
    "دسیلیون",
    "آندسیلیون",
    "دودسیلیون",
    "تریدسیلیون",
    "کواتوردسیلیون",
    "کویندسیلیون",
    "سکسدسیلیون",
    "سپتندسیلیون",
    "اکتودسیلیون",
    "نومدسیلیون",
    "ویجینتیلیون",
  ];

  String _rawExpression = "";
  String _lastCleanResult = "0";
  String _displayResult = "= 0";
  bool _isLight = false;
  bool _divByZero = false;

  bool _isOnline = true;
  bool _isCheckingNet = true;
  Timer? _netTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _checkInternet();
    _netTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _checkInternet(silent: true),
    );
  }

  @override
  void dispose() {
    _netTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInternet(silent: true);
    }
  }

  Future<void> _checkInternet({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isCheckingNet = true);
    }
    bool connected = false;
    for (final host in ['cafebazaar.ir', 'myket.ir', 'aparat.com']) {
      try {
        final res = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) {
          connected = true;
          break;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isOnline = connected;
        _isCheckingNet = false;
      });
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('megacalc_theme') ?? 'dark';
    if (mounted) {
      setState(() => _isLight = saved == 'light');
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => _isLight = !_isLight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('megacalc_theme', _isLight ? 'light' : 'dark');
  }

  Color get _bg => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF070A12);
  Color get _screenBg => _isLight ? Colors.white : const Color(0xFF0F1626);
  Color get _screenBorder => _isLight
      ? const Color(0xFF0D9488).withOpacity(0.35)
      : const Color(0xFF00F5D4).withOpacity(0.28);
  Color get _btnBg => _isLight ? Colors.white : const Color(0xFF162035);
  Color get _btnOpBg =>
      _isLight ? const Color(0xFFF3E8FF) : const Color(0xFF231942);
  Color get _neonCyan =>
      _isLight ? const Color(0xFF0D9488) : const Color(0xFF00F5D4);
  Color get _neonPurple =>
      _isLight ? const Color(0xFF7E22CE) : const Color(0xFF9B5DE5);
  Color get _neonOrange =>
      _isLight ? const Color(0xFFEA580C) : const Color(0xFFF97316);
  Color get _neonGold =>
      _isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24);
  Color get _textColor =>
      _isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _mutedColor =>
      _isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get _wordsBg => _isLight
      ? const Color(0xFF7E22CE).withOpacity(0.07)
      : const Color(0xFF9B5DE5).withOpacity(0.12);
  Color get _wordsBorder => _isLight
      ? const Color(0xFF7E22CE).withOpacity(0.30)
      : const Color(0xFF9B5DE5).withOpacity(0.40);
  Color get _modalBg => _isLight ? Colors.white : const Color(0xFF111827);

  String _addCommas(String intStr) {
    String sign = "";
    if (intStr.startsWith("-")) {
      sign = "-";
      intStr = intStr.substring(1);
    }
    final formatted = intStr.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return sign + formatted;
  }

  String _formatNumberString(String numStr) {
    final parts = numStr.split('.');
    return _addCommas(parts[0]) + (parts.length > 1 ? '.${parts[1]}' : '');
  }

  String _formatExpression(String expr) {
    if (expr.isEmpty) return "0";
    return expr.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (m) {
      return _formatNumberString(m.group(0)!);
    });
  }

  _BigDecimal _parseBD(String str) {
    BigInt sign = BigInt.one;
    if (str.startsWith('-')) {
      sign = -BigInt.one;
      str = str.substring(1);
    } else if (str.startsWith('+')) {
      str = str.substring(1);
    }
    final parts = str.split('.');
    final intPart = parts[0].isEmpty ? "0" : parts[0];
    final fracPart = parts.length > 1 ? parts[1] : "";
    final scale = fracPart.length;
    var combined = (intPart + fracPart).replaceFirst(RegExp(r'^0+'), '');
    if (combined.isEmpty) combined = "0";
    return _BigDecimal(sign * BigInt.parse(combined), scale);
  }

  String _formatBD(_BigDecimal bd) {
    final isNeg = bd.val.isNegative;
    final v = isNeg ? -bd.val : bd.val;
    var s = v.toString();
    if (bd.scale > 0) {
      if (s.length <= bd.scale) {
        s = "0.${"0" * (bd.scale - s.length)}$s";
      } else {
        final cut = s.length - bd.scale;
        s = "${s.substring(0, cut)}.${s.substring(cut)}";
      }
      s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return (isNeg && s != "0" ? "-" : "") + s;
  }

  _BigDecimal _addBD(_BigDecimal a, _BigDecimal b) {
    final maxS = a.scale > b.scale ? a.scale : b.scale;
    final vA = a.val * BigInt.from(10).pow(maxS - a.scale);
    final vB = b.val * BigInt.from(10).pow(maxS - b.scale);
    return _BigDecimal(vA + vB, maxS);
  }

  _BigDecimal _subBD(_BigDecimal a, _BigDecimal b) {
    return _addBD(a, _BigDecimal(-b.val, b.scale));
  }

  _BigDecimal _mulBD(_BigDecimal a, _BigDecimal b) {
    return _BigDecimal(a.val * b.val, a.scale + b.scale);
  }

  _BigDecimal _divBD(_BigDecimal a, _BigDecimal b) {
    if (b.val == BigInt.zero) throw Exception("DIV_ZERO");
    const extraPrecision = 10;
    final scaleDiff = (b.scale - a.scale) + extraPrecision;
    var num = a.val;
    var den = b.val;
    if (scaleDiff >= 0) {
      num = num * BigInt.from(10).pow(scaleDiff);
    } else {
      den = den * BigInt.from(10).pow(-scaleDiff);
    }
    return _BigDecimal(num ~/ den, extraPrecision);
  }

  String _evaluateExact(String expr) {
    final clean = expr.replaceFirst(RegExp(r'[×÷+\-.]+$'), '');
    if (clean.isEmpty) return "0";

    final tokens = <_Token>[];
    int i = 0;
    while (i < clean.length) {
      final ch = clean[i];
      final isUnary = (ch == '-' || ch == '+') &&
          (i == 0 || "×÷+-".contains(clean[i - 1]));
      if (isUnary) {
        var numStr = ch;
        i++;
        while (i < clean.length && RegExp(r'[\d.]').hasMatch(clean[i])) {
          numStr += clean[i];
          i++;
        }
        tokens.add(_Token.num(_parseBD(numStr)));
      } else if (RegExp(r'[\d.]').hasMatch(ch)) {
        var numStr = "";
        while (i < clean.length && RegExp(r'[\d.]').hasMatch(clean[i])) {
          numStr += clean[i];
          i++;
        }
        tokens.add(_Token.num(_parseBD(numStr)));
      } else if ("×÷+-".contains(ch)) {
        tokens.add(_Token.op(ch));
        i++;
      } else {
        i++;
      }
    }

    if (tokens.isEmpty || tokens[0].isOp) return "0";

    final pass1 = <_Token>[tokens[0]];
    for (int j = 1; j < tokens.length; j += 2) {
      if (j + 1 >= tokens.length) break;
      final opTok = tokens[j];
      final nextTok = tokens[j + 1];
      final prev = pass1.last;
      if (opTok.op == '×') {
        pass1[pass1.length - 1] = _Token.num(_mulBD(prev.bd!, nextTok.bd!));
      } else if (opTok.op == '÷') {
        pass1[pass1.length - 1] = _Token.num(_divBD(prev.bd!, nextTok.bd!));
      } else {
        pass1.add(opTok);
        pass1.add(nextTok);
      }
    }

    var acc = pass1[0].bd!;
    for (int j = 1; j < pass1.length; j += 2) {
      if (j + 1 >= pass1.length) break;
      final op = pass1[j].op;
      final nextBd = pass1[j + 1].bd!;
      if (op == '+') {
        acc = _addBD(acc, nextBd);
      } else if (op == '-') {
        acc = _subBD(acc, nextBd);
      }
    }
    return _formatBD(acc);
  }

  void _recalculate() {
    try {
      final exact = _evaluateExact(_rawExpression);
      final formatted = _formatNumberString(exact);
      setState(() {
        _divByZero = false;
        _lastCleanResult = exact;
        _displayResult = "= $formatted";
      });
    } catch (_) {
      setState(() {
        _divByZero = true;
        _displayResult = "⛔ تقسیم بر صفر!";
      });
    }
  }

  void _appendDigits(String d) {
    _rawExpression += d;
    _recalculate();
  }

  void _appendOp(String op) {
    if (_rawExpression.isEmpty) {
      if (op == '-') {
        _rawExpression = '-';
        _recalculate();
      }
      return;
    }
    if ("×÷+-".contains(_rawExpression[_rawExpression.length - 1])) {
      _rawExpression =
          _rawExpression.substring(0, _rawExpression.length - 1) + op;
    } else {
      _rawExpression += op;
    }
    _recalculate();
  }

  void _appendDot() {
    final parts = _rawExpression.split(RegExp(r'[×÷+\-]'));
    final current = parts.isNotEmpty ? parts.last : "";
    if (!current.contains('.')) {
      _rawExpression += current.isEmpty ? "0." : ".";
      _recalculate();
    }
  }

  void _backspace() {
    if (_rawExpression.isNotEmpty) {
      _rawExpression = _rawExpression.substring(0, _rawExpression.length - 1);
      _recalculate();
    }
  }

  void _clearAll() {
    setState(() {
      _rawExpression = "";
      _lastCleanResult = "0";
      _displayResult = "= 0";
      _divByZero = false;
    });
  }

  void _lockResult() {
    if (!_divByZero && _lastCleanResult.isNotEmpty && _lastCleanResult != "0") {
      _rawExpression = _lastCleanResult;
      _recalculate();
    }
  }

  Future<void> _copyExactResult() async {
    final formatted = _formatNumberString(_lastCleanResult);
    await Clipboard.setData(ClipboardData(text: formatted));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ عدد کامل کپی شد:\n$formatted',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openStore(String store) async {
    const pkg = "ir.matinmohammadi.bodymod";
    final url = store == "bazaar"
        ? "https://cafebazaar.ir/app/$pkg"
        : "https://myket.ir/app/$pkg";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openOtherAppsModal() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: _modalBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _neonPurple, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚀', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 6),
                Text(
                  'سایر برنامه‌های کاربردی ما',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _neonCyan,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: _mutedColor,
                      height: 1.65,
                    ),
                    children: [
                      const TextSpan(
                        text: 'سایر برنامه‌ها (مثل هوش مصنوعی تناسب اندام ',
                      ),
                      TextSpan(
                        text: 'BodyMod',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _textColor,
                        ),
                      ),
                      const TextSpan(
                        text: ') رو می‌خوای چطوری و از کدوم مارکت نصب کنی؟',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openStore('bazaar'),
                    child: const Text(
                      '🛒 مشاهده و نصب از کافه‌بازار',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openStore('myket'),
                    child: const Text(
                      '🟦 مشاهده و نصب از مایکت',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'بستن پنجره ✕',
                    style: TextStyle(
                      color: _mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordsBreakdown() {
    if (_divByZero) {
      return Text(
        'رفیق هیچ عددی رو نمی‌شه بر صفر تقسیم کرد!',
        style: TextStyle(color: _textColor, fontSize: 13.5, height: 1.7),
      );
    }
    if (_rawExpression.isEmpty) {
      return Text(
        '👽 اعداد نجومی رو وارد کن! هر چقدر هم بزرگ بشه، بدون e+ تمام رقم‌هاش رو می‌نویسم و از میلیارد تا ویجینتیلیون برات معنی می‌کنم!',
        style: TextStyle(color: _textColor, fontSize: 13, height: 1.7),
      );
    }

    var numStr = _lastCleanResult;
    if (numStr.isEmpty || numStr == "0") {
      return Text(
        '۰ (صفر)',
        style: TextStyle(color: _textColor, fontSize: 13.5),
      );
    }

    bool isNeg = false;
    if (numStr.startsWith('-')) {
      isNeg = true;
      numStr = numStr.substring(1);
    }

    final parts = numStr.split('.');
    final intStr = parts[0].isEmpty ? "0" : parts[0];
    final fracStr = parts.length > 1 ? parts[1] : "";

    final groups = <String>[];
    for (int i = intStr.length; i > 0; i -= 3) {
      final start = (i - 3) < 0 ? 0 : (i - 3);
      groups.add(intStr.substring(start, i));
    }

    final scaleParts = <_ScalePart>[];
    for (int idx = groups.length - 1; idx >= 0; idx--) {
      final val = int.tryParse(groups[idx]) ?? 0;
      if (val == 0) continue;
      final unit = idx < _scaleNames.length
          ? _scaleNames[idx]
          : '(۱۰ به توان ${idx * 3})';
      scaleParts.add(_ScalePart(val, unit, idx >= 3));
    }

    final totalDigits = intStr.length;
    final widgets = <Widget>[];

    if (isNeg) {
      widgets.add(Text(
        'منفی ',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ));
    }

    if (scaleParts.isEmpty) {
      widgets.add(Text('۰', style: TextStyle(color: _textColor)));
    } else {
      for (int i = 0; i < scaleParts.length; i++) {
        final sp = scaleParts[i];
        final badgeColor = sp.highTier ? _neonGold : _neonCyan;
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.14),
              border: Border.all(color: badgeColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sp.unit.isEmpty ? '${sp.value}' : '${sp.value} ${sp.unit}',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        );
        if (i < scaleParts.length - 1) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'و',
                style: TextStyle(color: _textColor, fontSize: 13),
              ),
            ),
          );
        }
      }
    }

    if (fracStr.isNotEmpty) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _neonCyan.withOpacity(0.12),
            border: Border.all(color: _neonCyan),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'ممیز $fracStr',
            style: TextStyle(
              color: _neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 11.5, color: _mutedColor),
            children: [
              const TextSpan(text: '📏 تعداد ارقام صحیح: '),
              TextSpan(
                text: '$totalDigits رقم',
                style: TextStyle(
                  color: _neonCyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (totalDigits >= 10)
                const TextSpan(text: ' 🔥 (عبور از مرز میلیارد!)'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: widgets,
        ),
      ],
    );
  }

  Widget _topBtn({
    required String label,
    required VoidCallback onTap,
    bool isApps = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _screenBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isApps ? _neonPurple : _screenBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isApps ? _neonPurple : _textColor,
          ),
        ),
      ),
    );
  }

  Widget _keyBtn(
    String label,
    VoidCallback onTap, {
    String type = 'num',
  }) {
    Color bg = _btnBg;
    Color fg = _textColor;
    Color border = _mutedColor.withOpacity(0.18);
    double fontSize = 23;
    Gradient? grad;

    if (type == 'op') {
      bg = _btnOpBg;
      fg = _neonPurple;
      border = _neonPurple.withOpacity(0.35);
      fontSize = 25;
    } else if (type == 'ac') {
      bg = const Color(0xFFEF4444).withOpacity(0.15);
      fg = const Color(0xFFEF4444);
      border = const Color(0xFFEF4444).withOpacity(0.35);
      fontSize = 20;
    } else if (type == 'del') {
      bg = _neonOrange.withOpacity(0.15);
      fg = _neonOrange;
      border = _neonOrange.withOpacity(0.35);
      fontSize = 20;
    } else if (type == 'zeros') {
      fg = _neonGold;
      fontSize = 18;
    } else if (type == 'eq') {
      fg = const Color(0xFF070A12);
      fontSize = 28;
      border = Colors.transparent;
      grad = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            color: grad == null ? bg : null,
            gradient: grad,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resLen = _displayResult.length;
    final resFontSize = resLen > 36 ? 19.0 : (resLen > 20 ? 23.0 : 28.0);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👽 MegaCalc',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _neonCyan,
                        ),
                      ),
                      Row(
                        children: [
                          _topBtn(
                            label: '📱 سایر برنامه‌ها',
                            onTap: _openOtherAppsModal,
                            isApps: true,
                          ),
                          const SizedBox(width: 6),
                          _topBtn(label: '📋 کپی', onTap: _copyExactResult),
                          const SizedBox(width: 6),
                          _topBtn(
                            label: _isLight ? '🌙' : '☀️',
                            onTap: _toggleTheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _screenBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _screenBorder, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      _formatExpression(_rawExpression),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 19,
                                        color: _mutedColor,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      _displayResult,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: resFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: _neonCyan,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            color: _mutedColor.withOpacity(0.28),
                            height: 18,
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _wordsBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _wordsBorder),
                              ),
                              child: SingleChildScrollView(
                                child: _buildWordsBreakdown(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _keyBtn('C', _clearAll, type: 'ac'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('⌫', _backspace, type: 'del'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn(
                                '000',
                                () => _appendDigits('000'),
                                type: 'zeros',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn(
                                '÷',
                                () => _appendOp('÷'),
                                type: 'op',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _keyBtn('7', () => _appendDigits('7')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('8', () => _appendDigits('8')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('9', () => _appendDigits('9')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn(
                                '×',
                                () => _appendOp('×'),
                                type: 'op',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _keyBtn('4', () => _appendDigits('4')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('5', () => _appendDigits('5')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('6', () => _appendDigits('6')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn(
                                '−',
                                () => _appendOp('-'),
                                type: 'op',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _keyBtn('1', () => _appendDigits('1')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('2', () => _appendDigits('2')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('3', () => _appendDigits('3')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn(
                                '+',
                                () => _appendOp('+'),
                                type: 'op',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _keyBtn(
                                '00',
                                () => _appendDigits('00'),
                                type: 'zeros',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('0', () => _appendDigits('0')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _keyBtn('.', _appendDot)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _keyBtn('=', _lockResult, type: 'eq'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_isOnline)
            _OfflineVideoGate(
              neonCyan: _neonCyan,
              neonPurple: _neonPurple,
              isCheckingNet: _isCheckingNet,
              onRetry: () => _checkInternet(),
            ),
        ],
      ),
    );
  }
}
