import 'package:adviser/adviser/fca/data/helpers/app_print.dart';
import 'package:adviser/adviser/fca/domain/app_entity/map_entity.dart';
import 'package:adviser/adviser/fca/domain/use_cases/map/get_directions_use_case.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:adviser/adviser/fca/domain/app_entity/user_profile_entity.dart';
import 'package:adviser/adviser/fca/domain/use_cases/app_use_case.dart';
import 'package:adviser/adviser/fca/domain/use_cases/user/update_profile_public_use_case.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LoadDirectionDelegate {

  void onLoadDirection(MapEntity? data);

  void onLoadDirectionError(AppCaseError message);

}

class ShowLocationPresenter extends Presenter
    implements Observer<AppCaseResponse> {
  final MapDirectionsCase _mapDirectionsCase = MapDirectionsCase();

  final LoadDirectionDelegate delegate;

  ShowLocationPresenter(LoadDirectionDelegate delegate) : delegate = delegate;

  void createRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    _mapDirectionsCase.execute(
        this,
        MapParams(origin: origin, destination: destination,
        )
    );
  }

  @override
  void dispose() {
    _mapDirectionsCase.dispose();
  }

  @override
  void onComplete() {}

  @override
  void onError(e) {
    if (e is AppCaseError && e.caseTag == UpdateProfilePublicCase.tag) {
      delegate.onLoadDirectionError(e);
    }
  }

  @override
  void onNext(AppCaseResponse? response) {
    if (response is AppCaseResponse<MapEntity>) {
      delegate.onLoadDirection(response.data);
    }
  }
}
