import 'package:cladbe_approval_functions/cladbe_approval_functions.dart';
import 'package:cladbe_shared_models/cladbe_shared_models.dart';
import 'package:dart_firebase_admin/firestore.dart';

/// Sample handler to demonstrate wiring. Replace with your real handlers.
class SampleHandler extends BaseHandler<void> {
  @override
  String? getName() => 'SampleHandler';

  @override
  Future<void> handleAction(
    RequestModel request,
    Transaction transaction,
    String empId,
    String id,
    Feedbacks feedback,
    RequestStatusEnum status,
  ) async {
    // Implement your business logic here.
    // Example: log the request status.
    print(
      'Handled ${status.name} for request ${request.id} by empId=$empId id=$id',
    );
  }
}
