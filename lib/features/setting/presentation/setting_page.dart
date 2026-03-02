import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ElevatedButton(onPressed: () async{
        await ref.read(authControllerProvider.notifier).logout();
      }, child: Text("Log Out")),
    );
  }
}
