import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

class SyncButton extends StatefulWidget {
  final Future<void> Function()? onSync;
  final Color color;
  final double size;

  const SyncButton({
    super.key,
    this.onSync,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    _controller.repeat();

    try {
      await OfflineSyncService.syncAll(context: context);
      if (widget.onSync != null && mounted) {
        await widget.onSync!();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: RotationTransition(
        turns: _controller,
        child: Icon(
          Icons.sync,
          color: widget.color,
          size: widget.size,
        ),
      ),
      tooltip: "Sync",
      onPressed: _isSyncing ? null : _handleSync,
    );
  }
}
