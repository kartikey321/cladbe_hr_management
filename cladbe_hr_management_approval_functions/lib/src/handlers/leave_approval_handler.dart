import 'package:cladbe_approval_functions/cladbe_approval_functions.dart';
import 'package:cladbe_approval_functions/src/utils/request_status.dart';
import 'package:cladbe_hr_management_approval_functions/src/base.dart';
import 'package:cladbe_shared_models/cladbe_shared_models.dart';
import 'package:cladbe_shared_models/src/models/approval_flow_item/request_model.dart';
import 'package:dart_firebase_admin/src/google_cloud_firestore/firestore.dart';

class LeaveApprovalHandler extends HrBaseHandler {
  @override
  Future<void> handleAction(
    RequestModel request,
    Transaction transaction,
    String empId,
    String id,
    Feedbacks feedback,
    RequestStatusEnum status,
  ) async {
    print(request.data);
    EmployeeLeaveModel employeeLeaveRequest = EmployeeLeaveModel.fromMap(
      request.data['data'],
    );

    var data =
        await PathHelper.getEmployeeLeavePath(
              request.companyId,
              request.data['empId'],
            )
            .getSingleDocument(
              employeeLeaveRequest.id,
              transaction: transaction,
            )
            .then((val) => val?.let((val) => EmployeeLeaveModel.fromMap(val)));
    if (data == null) {
      //
      throw AppError("Employee Leave  is not found  ");
    }

    validateTyped(employeeLeaveRequest, data);
    await getHandlerMethod(status)(
      request,
      transaction,
      empId,
      id,
      feedback,
      status,
      null,
    );
    await PathHelper.getEmployeeLeavePath(
      request.companyId,
      request.data['empId'],
    ).updateField(
      employeeLeaveRequest.id,
      employeeLeaveRequest.copyWith(leaveStatus: status.name).toMap(),
      transaction: transaction,
    );
  }
}
