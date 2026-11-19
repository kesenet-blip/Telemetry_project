import 'package:flutter/material.dart';

class BridgeConnectionSettings {
  const BridgeConnectionSettings({required this.host, required this.port});

  final String host;
  final int port;
}

class BridgeConnectionPanel extends StatefulWidget {
  const BridgeConnectionPanel({
    super.key,
    required this.initialHost,
    required this.initialPort,
    required this.onConnect,
  });

  final String initialHost;
  final int initialPort;
  final ValueChanged<BridgeConnectionSettings> onConnect;

  @override
  State<BridgeConnectionPanel> createState() => _BridgeConnectionPanelState();
}

class _BridgeConnectionPanelState extends State<BridgeConnectionPanel> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  String? _error;

  @override
  void initState() {
    super.initState();

    _hostController = TextEditingController(text: widget.initialHost);

    _portController = TextEditingController(
      text: widget.initialPort.toString(),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    var host = _hostController.text.trim();
    host = host
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^wss?://'), '');

    if (host.contains('/')) {
      host = host.split('/').first;
    }

    if (host.contains(':')) {
      host = host.split(':').first;
    }
    final port = int.tryParse(_portController.text.trim());

    if (host.isEmpty) {
      setState(() {
        _error = 'Add meg a Bridge IP-címét vagy hostnevét.';
      });
      return;
    }

    if (port == null || port < 1 || port > 65535) {
      setState(() {
        _error = 'A port 1 és 65535 közötti szám legyen.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    widget.onConnect(BridgeConnectionSettings(host: host, port: port));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LMU Bridge', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host / IP',
                      hintText: '192.168.1.50',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _connect(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.lan),
                  label: const Text('Connect'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
