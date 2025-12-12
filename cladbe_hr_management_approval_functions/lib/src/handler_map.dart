import 'package:cladbe_approval_functions/cladbe_approval_functions.dart';
import 'package:cladbe_hr_management_approval_functions/src/handlers/leave_approval_handler.dart';
import 'package:cladbe_shared_models/cladbe_shared_models.dart';

// ignore: unused_import
import 'handlers/sample_handler.dart';

/// Map SaleRequestTypes to handler constructors.
/// Add your module handlers here.
final Map<SaleRequestTypes, HandlingClass Function()> handlerMap = {
  // Example:
  SaleRequestTypes.ADD_EMPLOYEE_LEAVE: () => LeaveApprovalHandler(),
};
