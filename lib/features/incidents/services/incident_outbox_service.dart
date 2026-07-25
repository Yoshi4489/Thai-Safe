import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/incidents/data/incident_outbox.dart';
import 'package:thai_safe/firebase_options.dart';
import 'package:workmanager/workmanager.dart';

const incidentOutboxTask = 'retry-incident-outbox';

enum QuickSubmissionState { sent, queued }

class QuickSubmission {
  const QuickSubmission.sent(this.incidentId)
    : state = QuickSubmissionState.sent;
  const QuickSubmission.queued()
    : state = QuickSubmissionState.queued,
      incidentId = null;

  final QuickSubmissionState state;
  final String? incidentId;
}

class IncidentOutboxService {
  IncidentOutboxService({
    SafetyFunctionsRepository? repository,
    IncidentOutbox? outbox,
  }) : _repository = repository ?? SafetyFunctionsRepository(),
       _outbox = outbox ?? IncidentOutbox.instance;

  final SafetyFunctionsRepository _repository;
  final IncidentOutbox _outbox;

  Future<QuickSubmission> submitOrQueue(QuickIncidentRequest request) async {
    try {
      final result = await _repository.submitQuickIncident(request);
      await _outbox.markSent(request.clientRequestId);
      return QuickSubmission.sent(result.incidentId);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRetryableCode(error.code)) rethrow;
      await _queue(request, error);
      return const QuickSubmission.queued();
    } on SocketException catch (error) {
      await _queue(request, error);
      return const QuickSubmission.queued();
    }
  }

  Future<bool> retryPending() async {
    var allSent = true;
    for (final item in await _outbox.pending()) {
      try {
        await _repository.submitQuickIncident(item.request);
        await _outbox.markSent(item.clientRequestId);
      } catch (error) {
        allSent = false;
        await _outbox.markFailed(item.clientRequestId, error);
      }
    }
    return allSent;
  }

  Future<int> pendingCount() => _outbox.count();

  Future<void> _queue(QuickIncidentRequest request, Object error) async {
    await _outbox.put(request, error: error.toString());
    await Workmanager().registerOneOffTask(
      'incident-${request.clientRequestId}',
      incidentOutboxTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  bool _isRetryableCode(String code) => const {
    'unavailable',
    'deadline-exceeded',
    'internal',
    'unknown',
  }.contains(code);
}

@pragma('vm:entry-point')
void incidentOutboxCallbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != incidentOutboxTask) return true;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestProvider()
          : const AppleDebugProvider(),
    );
    return IncidentOutboxService().retryPending();
  });
}
