import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'pack_scan_repository.dart';

/// Packing by scan (Sribees Supply phase E): pick a line, scan the QR label on each unit
/// (camera, or a Bluetooth/USB scanner that types into the focused field). Sribees Supply
/// checks every label at once; the order can be marked packed once every line is done.
class PackScanPage extends ConsumerStatefulWidget {
  const PackScanPage({super.key, required this.orderId, required this.orderNumber});
  final String orderId;
  final String orderNumber;

  @override
  ConsumerState<PackScanPage> createState() => _PackScanPageState();
}

class _PackScanPageState extends ConsumerState<PackScanPage> {
  PackProgress? _p;
  Object? _error;
  String? _selected;
  bool _busy = false;
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _take(PackProgress p) {
    _p = p;
    final current = p.lines.where((l) => l.itemId == _selected).firstOrNull;
    if (current == null || current.done) {
      _selected = p.lines.where((l) => !l.done).firstOrNull?.itemId ?? _selected;
    }
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(packScanRepositoryProvider).progress(widget.orderId);
      if (mounted) setState(() => _take(p));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _say(String text, {bool bad = false}) {
    final m = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: bad ? AppColors.error : AppColors.success,
        duration: Duration(seconds: bad ? 5 : 1)));
  }

  Future<String?> _askWeight(PackLine line) async {
    final c = TextEditingController();
    final t = AppLocalizations.of(context);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.packWeightTitle),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: t.packWeightKg,
              helperText: t.packWeightNeed(line.needKg!.toStringAsFixed(3),
                  line.scannedKg.toStringAsFixed(3))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(t.packAdd)),
        ],
      ),
    );
    c.dispose();
    if (v == null || !RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(v) || double.parse(v) <= 0) return null;
    return v;
  }

  /// Returns null when accepted, else the message shown.
  Future<String?> _scan(String raw) async {
    final t = AppLocalizations.of(context);
    final label = parseLabel(raw);
    if (label == null) return t.packNotLabel;
    final line = _p?.lines.where((l) => l.itemId == _selected).firstOrNull;
    if (line == null) return t.packPickLine;
    String? kg;
    if (line.byWeight) {
      kg = await _askWeight(line);
      if (kg == null) return t.packWeightMissing;
    }
    setState(() => _busy = true);
    try {
      final p = await ref
          .read(packScanRepositoryProvider)
          .scan(widget.orderId, line.itemId, label, weightKg: kg);
      if (!mounted) return null;
      setState(() => _take(p));
      HapticFeedback.selectionClick();
      return null;
    } on ApiException catch (e) {
      HapticFeedback.heavyImpact();
      return e.kind == ApiErrorKind.conflict || e.kind == ApiErrorKind.notFound ||
              e.kind == ApiErrorKind.server
          ? e.message
          : t.packFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitText(String raw) async {
    if (raw.trim().isEmpty) return;
    final err = await _scan(raw.trim());
    if (!mounted) return;
    if (err != null) _say(err, bad: true);
    _text.clear();
    _focus.requestFocus();
  }

  Future<void> _undo(String label) async {
    try {
      final p = await ref.read(packScanRepositoryProvider).undo(widget.orderId, label);
      if (mounted) setState(() => _take(p));
    } on ApiException catch (e) {
      if (mounted) _say(e.message, bad: true);
    }
  }

  Future<void> _camera() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _CameraPage(onScan: _scan, counter: () {
              final l = _p?.lines.where((x) => x.itemId == _selected).firstOrNull;
              if (l == null) return '';
              return l.byWeight
                  ? '${l.name}: ${l.scannedKg.toStringAsFixed(3)} / ${l.needKg!.toStringAsFixed(3)} kg'
                  : '${l.name}: ${l.scannedUnits} / ${l.quantity}';
            })));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = _p;
    Widget body;
    if (_error != null) {
      body = Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error is ApiException ? (_error as ApiException).message : t.packFailed,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () {
              setState(() => _error = null);
              _load();
            },
            child: Text(t.retry)),
      ]));
    } else if (p == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!p.enabled) {
      body = Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(t.packOff, textAlign: TextAlign.center)));
    } else {
      body = ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _text,
              focusNode: _focus,
              autofocus: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: t.packScanHere, prefixIcon: const Icon(Icons.qr_code_2)),
              onSubmitted: _submitText,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
                onPressed: _busy ? null : _camera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(t.packCamera)),
          ),
        ]),
        const SizedBox(height: 12),
        for (final l in p.lines)
          Card(
            color: l.itemId == _selected ? AppColors.primary.withValues(alpha: 0.06) : null,
            child: ListTile(
              selected: l.itemId == _selected,
              onTap: () => setState(() => _selected = l.itemId),
              leading: Icon(l.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: l.done ? AppColors.success : null),
              title: Text([l.name, if (l.variant != null) l.variant].join(' · ')),
              subtitle: Text(l.byWeight
                  ? '${l.scannedKg.toStringAsFixed(3)} / ${l.needKg!.toStringAsFixed(3)} kg'
                  : '${l.scannedUnits} / ${l.quantity}'),
              trailing: l.labels.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t.packUndo,
                      icon: const Icon(Icons.undo),
                      onPressed: () => _undo(l.labels.last)),
            ),
          ),
        const SizedBox(height: 12),
        if (p.complete)
          Text(t.packAllDone,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
      ]);
    }
    return Scaffold(
      appBar: AppBar(title: Text('${t.packTitle} · ${widget.orderNumber}')),
      body: body,
      bottomNavigationBar: p != null && p.enabled
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(p.complete),
                    child: Text(p.complete ? t.packDoneButton : t.packLater),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _CameraPage extends StatefulWidget {
  const _CameraPage({required this.onScan, required this.counter});
  final Future<String?> Function(String raw) onScan;
  final String Function() counter;

  @override
  State<_CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<_CameraPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  final Map<String, DateTime> _seen = {};
  String? _last;
  bool _ok = true;
  bool _working = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detect(BarcodeCapture capture) async {
    if (_working) return;
    final now = DateTime.now();
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      final at = _seen[raw];
      if (at != null && now.difference(at) < const Duration(seconds: 3)) continue;
      _seen[raw] = now;
      _working = true;
      final err = await widget.onScan(raw);
      _working = false;
      if (!mounted) return;
      setState(() {
        _last = err ?? raw;
        _ok = err == null;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.packCamera), actions: [
        IconButton(onPressed: () => _controller.toggleTorch(), icon: const Icon(Icons.flash_on_outlined)),
      ]),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _detect,
          errorBuilder: (context, error) => Center(
              child: Padding(padding: const EdgeInsets.all(24), child: Text(t.packNoCamera))),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.counter(), style: Theme.of(context).textTheme.titleMedium),
                if (_last != null)
                  Text(_last!, style: TextStyle(color: _ok ? AppColors.success : AppColors.error)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(), child: Text(t.packDone)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
