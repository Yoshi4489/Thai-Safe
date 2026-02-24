import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "สวัสดี ${user?.firstName ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🟦 WELCOME CARD
            _welcomeCard(),

            const SizedBox(height: 24),

            /// 🚨 SOS BUTTON
            _sosButton(),

            const SizedBox(height: 24),

            /// ⚠️ RISK AREA
            _riskAreaBanner(),

            const SizedBox(height: 24),

            /// 🕘 LATEST INCIDENT
            _latestIncident(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.shield_outlined, size: 36, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "คุณอยู่ในระบบ ThaiSafe\nพร้อมช่วยเหลือคุณตลอดเวลา",
              style: TextStyle(fontSize: 14),
            ),
          )
        ],
      ),
    );
  }

  Widget _sosButton() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "SOS",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "กดเพื่อขอความช่วยเหลือทันที",
            style: TextStyle(color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _riskAreaBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "ขณะนี้คุณอยู่ในพื้นที่เฝ้าระวัง\nกรุณาติดตามประกาศจากเจ้าหน้าที่",
              style: TextStyle(fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _latestIncident() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "เหตุการณ์ล่าสุด",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.history, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "น้ำท่วมในพื้นที่บ้าน\nสถานะ: กำลังดำเนินการ",
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }

}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}