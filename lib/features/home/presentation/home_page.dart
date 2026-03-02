import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/incidents/controllers/incident_controller.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/incident_details_page.dart';
import 'package:thai_safe/features/maps_alert/presentation/pages/report_incident_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<Position> _getUserLocation() async {
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isServiceEnabled) {
      return Future.error("Location Services disable");
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location Service denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location denied needed to allow in setting");
    }

    return await Geolocator.getCurrentPosition();
  }

  void _initGetNearbyIncident() async {
    Position? currentPosition = await _getUserLocation();
    if (!currentPosition.latitude.isNaN && !currentPosition.longitude.isNaN) {
      await ref
          .read(incidentControllerProvider.notifier)
          .getIncidentsNearby(
            currentPosition.latitude,
            currentPosition.longitude,
            5,
          );
    }
  }

  @override
  void initState() {
    super.initState();
    _initGetNearbyIncident();
  }

  @override
  Widget build(BuildContext context) {
    final incidentController = ref.watch(incidentControllerProvider);
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
          ),
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
            _sosButton(ref),

            const SizedBox(height: 24),

            /// ⚠️ RISK AREA
            if (incidentController.isRiskNearby) _riskAreaBanner(),

            const SizedBox(height: 24),

            /// NEAR INCIDENT
            const Text(
              "เหตุการณ์ ใกล้เคียงคุณ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            incidentController.isLoading
                ? Center(child: CircularProgressIndicator())
                : _nearIncident(incidentController.nearbyIncidents),

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
          ),
        ],
      ),
    );
  }

  Widget _sosButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          ref.context,
          MaterialPageRoute(builder: (context) => const ReportIncidentPage()),
        );
      },
      child: Center(
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
            ),
          ],
        ),
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
          ),
        ],
      ),
    );
  }

  Widget _nearIncident(List<IncidentModel> nearByIncidents) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nearByIncidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final incident = nearByIncidents[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (BuildContext context) => IncidentDetailsPage(incident: incident)
            ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${incident.title}\nสถานะ: ${incident.status.toLowerCase()}",
            ),
          ),
        );
      },
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
