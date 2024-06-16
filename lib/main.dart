import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

void main() {
  runApp(const MyApp());
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
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String output = '';

  void connectAndExecute() async {
    final host = hostController.text;
    final port = int.tryParse(portController.text) ?? 22;
    final username = usernameController.text;
    final password = passwordController.text;

    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: username,
      onPasswordRequest: () => password,
    );

    try {
      final result = await client.run('ls');
      setState(() {
        output = utf8.decode(result);
      });
    } catch (e) {
      setState(() {
        output = 'Failed to connect or execute command: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: hostController,
              decoration: const InputDecoration(labelText: 'Host'),
            ),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: connectAndExecute,
              child: const Text('Connect and Execute'),
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