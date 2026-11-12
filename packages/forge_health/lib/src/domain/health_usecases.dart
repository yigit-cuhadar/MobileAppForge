import 'package:forge_core/forge_core.dart';

import 'health_models.dart';
import 'health_steps.dart';

class GetHealthAvailability implements UseCase<HealthAvailability, NoParams> {
  const GetHealthAvailability(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<HealthAvailability>> call([
    NoParams params = const NoParams(),
  ]) => _repository.availability();
}

class GetStepsPermission implements UseCase<HealthPermission, NoParams> {
  const GetStepsPermission(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<HealthPermission>> call([NoParams params = const NoParams()]) =>
      _repository.permission();
}

class RequestStepsPermission implements UseCase<HealthPermission, NoParams> {
  const RequestStepsPermission(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<HealthPermission>> call([NoParams params = const NoParams()]) =>
      _repository.requestPermission();
}

class GetStepsOn implements UseCase<int, DateTime> {
  const GetStepsOn(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<int>> call(DateTime params) => _repository.stepsOn(params);
}

class GetDailySteps
    implements UseCase<List<DailySteps>, ({DateTime first, DateTime last})> {
  const GetDailySteps(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<List<DailySteps>>> call(
    ({DateTime first, DateTime last}) params,
  ) => _repository.dailySteps(params.first, params.last);
}

class OpenHealthSettings implements UseCase<void, NoParams> {
  const OpenHealthSettings(this._repository);
  final HealthSteps _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.openSettings();
}
