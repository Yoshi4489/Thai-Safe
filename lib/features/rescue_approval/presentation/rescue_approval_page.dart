import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';
import 'package:thai_safe/features/rescue_approval/provider/rescue_approval_provider.dart';

class RescueApprovalPage extends ConsumerStatefulWidget {
  const RescueApprovalPage({super.key});

  @override
  ConsumerState<RescueApprovalPage> createState() => _RescueApprovalPageState();
}

class _RescueApprovalPageState extends ConsumerState<RescueApprovalPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rescueApprovalControllerProvider);
    final controller = ref.read(rescueApprovalControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Rescue Team Approval")),

      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadRescurerList();
        },

        child: Builder(
          builder: (context) {
            /// Loading
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            /// Error
            if (state.error != null && state.error!.isNotEmpty) {
              return Center(child: Text(state.error!));
            }

            /// Empty
            if (state.rescurerList.isEmpty) {
              return const Center(child: Text("No rescue requests"));
            }

            /// List
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.rescurerList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = state.rescurerList[index];
                return _approvalCard(request);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _approvalCard(RescueRequestModel request) {
    final service = ref.read(rescueApprovalService);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Name
          Text(
            request.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 6),

          /// Phone
          Text("Phone: ${request.phone}"),

          const SizedBox(height: 6),

          /// Date
          Text(
            "Requested: ${request.createdAt.toLocal()}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          /// Buttons
          Row(
            children: [
              /// APPROVE
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await service.approveRescueRequest(request.id, "admin", request.userId);

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Rescue team approved")),
                    );

                    ref
                        .read(rescueApprovalControllerProvider.notifier)
                        .loadRescurerList();
                  },
                ),
              ),

              const SizedBox(width: 10),

              /// REJECT
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await service.rejectRescueRequest(request.id, "admin");

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Rescue team rejected")),
                    );

                    ref
                        .read(rescueApprovalControllerProvider.notifier)
                        .loadRescurerList();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
