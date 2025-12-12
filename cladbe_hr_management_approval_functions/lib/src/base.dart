import 'package:cladbe_approval_functions/cladbe_approval_functions.dart';
import 'package:cladbe_shared_models/cladbe_shared_models.dart';

/// Extend this for your domain-specific handlers if you need shared helpers.
/// You can also use [BaseHandler] directly.
abstract class HrBaseHandler extends BaseHandler<EmployeeLeaveModel> {
  @override
  String? getName() => 'TemplateHandler';
}
