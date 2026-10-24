import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // needed for auto-close
import 'package:pink_data_mobile/app_theme.dart';
import 'package:pink_data_mobile/auth_service.dart';
import 'package:pink_data_mobile/spinning_logo.dart';
import 'package:pink_data_mobile/api_service.dart';
import 'package:pink_data_mobile/share_service.dart';

class _ShareEntry {
  _ShareEntry(this.url, {this.sending = true, this.ok = false, this.message = 'Sending...'})
      : at = DateTime.now();

  final String url;
  final DateTime at;
  bool sending;
  bool ok;
  String message;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, required this.theme});

  final AuthService auth;
  final ThemeController theme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService _api = ApiService(widget.auth);
  late final ShareService _share;
  final List<_ShareEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _share = ShareService(
      api: _api,
      onUrlReceived: (url) {
        if (!mounted) return;
        setState(() => _history.insert(0, _ShareEntry(url)));
      },
      onUploadComplete: (url, result) {
        if (!mounted) return;
        setState(() {
          final entry = _history.cast<_ShareEntry?>().firstWhere(
                (e) => e!.url == url && e.sending,
                orElse: () => null,
              );
          if (entry != null) {
            entry.sending = false;
            entry.ok = result.ok;
            entry.message = result.ok ? 'Saved! Closing app...' : result.message;
          } else {
            _history.insert(
              0,
              _ShareEntry(url,
                  sending: false,
                  ok: result.ok,
                  message: result.ok ? 'Saved! Closing app...' : result.message),
            );
          }
        });

        // Auto-close after a successful share so you go straight back to Instagram.
        if (result.ok) {
          Future.delayed(const Duration(milliseconds: 500), () {
            SystemNavigator.pop();
          });
        }
      },
    )..init();
  }

  @override
  void dispose() {
    _share.dispose();
    super.dispose();
  }

  Future<void> _retry(_ShareEntry entry) async {
    setState(() {
      entry.sending = true;
      entry.message = 'Sending...';
    });
    final result = await _api.sendUrlToBackend(entry.url);
    if (!mounted) return;
    setState(() {
      entry.sending = false;
      entry.ok = result.ok;
      entry.message = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = Theme.of(context).extension<StatusColors>()!;
    final auth = widget.auth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CreatorLens', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: widget.theme.isDark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: widget.theme.toggle,
            icon: Icon(widget.theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SpinningLogo(size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.name ?? 'Signed in',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        if (auth.email != null)
                          Text(auth.email!, style: TextStyle(color: status.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How to use', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Open a reel in Instagram, tap Share, then choose CreatorLens. '
                    'The link goes to your Staging Queue on the website.',
                    style: TextStyle(color: status.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Recent shares',
              style: TextStyle(
                  color: status.muted, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nothing shared yet.', style: TextStyle(color: status.muted))),
            )
          else
            for (final entry in _history.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: entry.sending
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(entry.ok ? Icons.check_circle_outline : Icons.error_outline,
                            color: entry.ok ? status.success : scheme.error),
                    title: Text(entry.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(entry.message,
                        style: TextStyle(color: entry.ok || entry.sending ? status.muted : scheme.error)),
                    trailing: (!entry.sending && !entry.ok)
                        ? TextButton(onPressed: () => _retry(entry), child: const Text('Retry'))
                        : null,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}