import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(const MyApp());
}

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/config.json');

    if (await file.exists()) {
      String strJson = await file.readAsString();
      return json.decode(strJson);
    } else {
      final defaultConfig = {
        "host": "",
        "port": 22,
        "username": "",
        "password": "",
        "path_to_directory": "",
        "open_name": "",
        "password_for_decrypt": "",
        "mount_directory": ""
      };

      await file.writeAsString(json.encode(defaultConfig));
      return defaultConfig;
    }
  } catch (e) {
    print('Error reading config file: $e');
    return {};
  }
}

Future<void> saveConfig(Map<String, dynamic> config) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/config.json');

    if (!(await file.exists())) {
      await file.create();
    }

    String strJson = json.encode(config);
    await file.writeAsString(strJson);
  } catch (e) {
    print('Error writing config file: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSH Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SSHScreen(),
    );
  }
}

class SSHScreen extends StatefulWidget {
  const SSHScreen({Key? key}) : super(key: key);

  @override
  _SSHScreenState createState() => _SSHScreenState();
}

class _SSHScreenState extends State<SSHScreen> {
  Map<String, dynamic>? config;
  String output = '';

  @override
  void initState() {
    super.initState();
    loadConfig().then((value) {
      setState(() {
        config = value;
      });
    });
  }

  void connectAndExecute() async {
    if (config == null) {
      setState(() {
        output = 'Config not loaded yet';
      });
      return;
    }

    final host = config!['host'];
    final port = config!['port'];
    final username = config!['username'];
    final password = config!['password'];
    final path_to_directory = config!['path_to_directory'];
    final open_name = config!['open_name'];
    final password_for_decrypt = config!['password_for_decrypt'];
    final mount_directory = config!['mount_directory'];

    print(host);

    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: username,
      onPasswordRequest: () => password,
    );

    try {
      final shell = await client.shell();
      final encoder = const Utf8Encoder();
      final open_directory = 'echo -n "$password_for_decrypt" | sudo cryptsetup luksOpen --key-file - $path_to_directory $open_name\n';
      final mount = 'sudo mount /dev/mapper/$open_name $mount_directory\n';
      shell.write(encoder.convert('echo $password | sudo -S clear\n'));
      shell.write(encoder.convert(open_directory));
      shell.write(encoder.convert(mount));
      shell.write(encoder.convert('exit\n'));

      final out = await shell.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .join();

      final error = await shell.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .join();

      print(out);
      print(error);

      setState(() {
        output = 'The directory is open and ready';
      });
    } catch (e) {
      setState(() {
        output = 'Failed to connect or execute command: $e';
      });
    }
  }

  Future<void> _editConfig() async {
    Map<String, dynamic>? updatedConfig = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return ConfigDialog(config: config ?? {});
      },
    );
    if (updatedConfig != null) {
      setState(() {
        config = updatedConfig;
      });
      await saveConfig(updatedConfig);
    }
  }

  Future<void> _scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        output = result.rawContent;
      });
    } catch (e) {
      setState(() {
        output = 'Failed to get QR code: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SSH Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: connectAndExecute,
                child: const Text('Connect and Execute'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _editConfig,
                child: const Text('Edit Config'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanQRCode,
                child: const Text('Scan QR Code'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(output),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ConfigDialog extends StatefulWidget {
  final Map<String, dynamic> config;

  const ConfigDialog({Key? key, required this.config}) : super(key: key);

  @override
  _ConfigDialogState createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late Map<String, dynamic> _updatedConfig;

  @override
  void initState() {
    super.initState();
    _updatedConfig = Map.from(widget.config);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure SSH Connection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Host'),
              onChanged: (value) => _updatedConfig['host'] = value,
              controller: TextEditingController(text: widget.config['host']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Port'),
              onChanged: (value) => _updatedConfig['port'] = int.parse(value),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: widget.config['port'].toString()),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Username'),
              onChanged: (value) => _updatedConfig['username'] = value,
              controller: TextEditingController(text: widget.config['username']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              onChanged: (value) => _updatedConfig['password'] = value,
              controller: TextEditingController(text: widget.config['password']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Path to directory'),
              onChanged: (value) => _updatedConfig['path_to_directory'] = value,
              controller: TextEditingController(text: widget.config['path_to_directory']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Open name'),
              onChanged: (value) => _updatedConfig['open_name'] = value,
              controller: TextEditingController(text: widget.config['open_name']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password for decrypt'),
              onChanged: (value) => _updatedConfig['password_for_decrypt'] = value,
              controller: TextEditingController(text: widget.config['password_for_decrypt']),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Mount directory'),
              onChanged: (value) => _updatedConfig['mount_directory'] = value,
              controller: TextEditingController(text: widget.config['mount_directory']),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(_updatedConfig);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}