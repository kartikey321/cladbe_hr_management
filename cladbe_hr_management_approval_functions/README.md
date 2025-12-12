# cladbe_hr_management_approval_functions

Template for building approval-function modules on top of `cladbe_approval_functions`.

## Structure
- `pubspec.yaml`: depends on `cladbe_approval_functions`, `cladbe_shared_models`, Shelf/CORS, hot reload.
- `lib/src/base.dart`: optional base class extending `BaseHandler` for your domain.
- `lib/src/handlers/`: put your handler implementations (`extends BaseHandler`), override `handleAction`.
- `lib/src/handler_map.dart`: map `SaleRequestTypes` to handler constructors.
- `lib/cladbe_hr_management_approval_functions.dart`: exports the handler map (and any other public API).
- `bin/cladbe_hr_management_approval_functions.dart`: starts the Shelf approval server via `serveApproval`, with hot reload.
- `test/`: add tests for your handlers.

## Getting started
1. `dart pub get`
2. Register handlers in `lib/src/handler_map.dart`, e.g.
   ```dart
   handlerMap[SaleRequestTypes.PROJECT_CREATE] = () => SampleHandler();
   ```
3. Run the server (enable VM service for hot reload):
   ```bash
   dart run bin/cladbe_hr_management_approval_functions.dart --enable-vm-service
   ```
4. POST approval requests to the server; dispatch is based on `request.approvalTypeId` -> `SaleRequestTypes` -> your handler.

## Notes
- Use `DataHelper`/`EntityAuditHelper` from `cladbe_approval_functions` for Firestore CRUD and audit logging.
- Update `config/config.dart` in the dependency if you need different Firestore settings (or override in your handlers).
