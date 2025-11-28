import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

class MobileDemoScreen extends StatefulWidget {
  const MobileDemoScreen({super.key});

  @override
  State<MobileDemoScreen> createState() => _MobileDemoScreenState();
}

class _MobileDemoScreenState extends State<MobileDemoScreen> {
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
