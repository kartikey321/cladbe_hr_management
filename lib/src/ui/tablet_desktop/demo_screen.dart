import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDefault.backgroundColor,
      body: Center(
        child: Text('Hello World'),
      ),
    );
  }
}
