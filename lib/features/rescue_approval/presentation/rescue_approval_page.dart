import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';
import 'package:thai_safe/features/rescue_approval/provider/rescue_approval_provider.dart';

class RescueApprovalPage extends ConsumerWidget {
  const RescueApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rescueApprovalControllerProvider);
    final controller = ref.read(rescueApprovalControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Responder verification'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadRescurerList,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error?.isNotEmpty == true
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(state.error!)),
                ],
              )
            : state.rescurerList.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No pending applications')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.rescurerList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _ApplicationCard(
                  request: state.rescurerList[index],
                  onChanged: controller.loadRescurerList,
                ),
              ),
      ),
    );
  }
}

class _ApplicationCard extends ConsumerStatefulWidget {
  const _ApplicationCard({required this.request, required this.onChanged});

  final RescueRequestModel request;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _busy = false;
  String? _error;

  Future<void> _review(String action) async {
    final service = ref.read(rescueApprovalService);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (action == 'approve') {
        await service.approveRescueRequest(
          widget.request.id,
          'custom-claim-admin',
          widget.request.userId,
        );
      } else {
        await service.rejectRescueRequest(
          widget.request.userId,
          'custom-claim-admin',
        );
      }
      await widget.onChanged();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _showEvidence() async {
    final urls = await ref
        .read(rescueApprovalService)
        .evidenceUrls(widget.request);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Protected verification evidence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...urls.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.network(url),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.organization,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text('Applicant UID: ${request.userId}'),
            Text(
              'Identity document ending: ••••${request.identityNumberLast4}',
            ),
            Text('Submitted: ${request.createdAt.toLocal()}'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _showEvidence,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(
                'Review ${request.evidencePaths.length} evidence file(s)',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _review('approve'),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _review('reject'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
