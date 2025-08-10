import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannerResult extends StatefulWidget {
  final String code;

  const ScannerResult({super.key, required this.code});

  @override
  State<ScannerResult> createState() => _ScannerResultState();
}

class _ScannerResultState extends State<ScannerResult> {
  bool _showPassword = false;
  late Map<String, String>? _wifiData;

  @override
  void initState() {
    super.initState();
    _wifiData = _parseWifiQr(widget.code);
  }

  bool get _isUrl {
    try {
      final uri = Uri.parse(_ensureUrlScheme(widget.code));
      return uri.hasAbsolutePath &&
          (uri.scheme == 'http' ||
              uri.scheme == 'https' ||
              uri.scheme == 'mailto' ||
              uri.scheme == 'tel');
    } catch (e) {
      return false;
    }
  }

  Map<String, String>? _parseWifiQr(String code) {
    if (!code.startsWith('WIFI:')) return null;

    final data = <String, String>{};
    final parts = code.split(';');

    for (final part in parts) {
      if (part.contains(':')) {
        final keyValue = part.split(':');
        if (keyValue.length >= 2) {
          data[keyValue[0]] = keyValue.sublist(1).join(':');
        }
      }
    }

    return data;
  }

  String _ensureUrlScheme(String url) {
    if (url.startsWith('www.')) {
      return 'https://$url';
    }
    if (RegExp(r'^[\d\+][\d\s\-]+$').hasMatch(url)) {
      return 'tel:$url';
    }
    if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(url)) {
      return 'mailto:$url';
    }
    return url;
  }

  Future<void> _launchUrl() async {
    try {
      final uri = Uri.parse(_ensureUrlScheme(widget.code));

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: widget.code)),
          ),
        ),
      );
    }
  }

  Widget _buildWifiInfo() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.wifi),
          title: const Text('Network Name (SSID)'),
          subtitle: Text(_wifiData!['S'] ?? 'Unknown'),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security Type'),
          subtitle: Text(_wifiData!['T'] ?? 'Unknown'),
        ),
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('Password'),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                    _showPassword ? _wifiData!['P'] ?? '' : '•' * 8),
              ),
              IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, // Make button full width
          child: ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _wifiData!['P'] ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password copied!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy Password'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            widget.code,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 30),
        if (_isUrl) ...[
          SizedBox(
            width: double.infinity, // Make button full width
            child: ElevatedButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Link'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
        ],
        SizedBox(
          width: double.infinity, // Make button full width
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isUrl ? 'Link copied!' : 'Text copied!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: Text(_isUrl ? 'Copy Link' : 'Copy Text'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(
                widget.code,
                subject: _isUrl ? 'Shared Link' : 'Shared Content',
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _wifiData != null
                          ? Icons.wifi
                          : _isUrl
                          ? Icons.link
                          : Icons.text_snippet,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _wifiData != null
                          ? 'WiFi Network'
                          : _isUrl
                          ? 'Scanned Link'
                          : 'Scanned Content',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _wifiData != null ? _buildWifiInfo() : _buildRegularContent(),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Scanned at: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}