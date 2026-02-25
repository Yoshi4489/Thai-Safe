import 'package:flutter/material.dart';

class BootLoadingPage extends StatelessWidget {
  const BootLoadingPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children:[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังตรวจสอบบัญชี...'),
          ]
        )
      )
    );
  }
}
