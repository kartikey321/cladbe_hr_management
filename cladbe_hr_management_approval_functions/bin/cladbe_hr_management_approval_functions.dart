import 'package:cladbe_approval_functions/cladbe_approval_functions.dart';
import 'package:cladbe_hr_management_approval_functions/cladbe_hr_management_approval_functions.dart';

Future<void> main(List<String> arguments) async {
  // Example registration: wire up handlers per SaleRequestTypes in handlerMap.
  // handlerMap[SaleRequestTypes.PROJECT_CREATE] = () => SampleHandler();

  await withHotreload(() async {
    final server = await serveApproval(handlerMap: handlerMap, port: 8156);
    print('Template approval server listening on port ${server.port}');
    return server;
  });
}
