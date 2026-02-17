import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:thai_safe/features/authetication/providers/auth_state_provider.dart";

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${ref.read(authControllerProvider).user!.firstName} ${ref.read(authControllerProvider).user!.lastName}"),
        leading: Icon(Icons.person),
      ),
    );
  }
}