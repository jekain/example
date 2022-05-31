import 'dart:async';
import 'dart:typed_data';

import 'package:adviser/adviser/fca/app/components/app_toast/app_toast.dart';
import 'package:adviser/adviser/fca/app/fragments/fragment.dart';
import 'package:adviser/adviser/fca/app/navigator/base_route.dart';
import 'package:adviser/adviser/fca/app/pages/base/controller.dart';
import 'package:adviser/adviser/fca/app/pages/location/show_location/show_location_presenter.dart';
import 'package:adviser/adviser/fca/data/cell_data/category_group/item.dart';
import 'package:adviser/adviser/fca/data/helpers/app_print.dart';
import 'package:adviser/adviser/fca/domain/app_entity/map_entity.dart';
import 'package:adviser/adviser/fca/domain/use_cases/app_use_case.dart';
import 'package:adviser/adviser/resources/constants/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

enum buttonStatus {
  road,
  closeRoad,
  destination,
  user,
}

class LocationState {
  final bool isLoading;
  final String title;
  final CategoryGroupItem? item;
  final bool isRoad;
  final MapEntity? roadItem;
  final LatLng? userPosition;
  final LatLng? startPosition;
  final LatLng? destinationPosition;
  final buttonStatus button;
  final icon;
  final bool hideBot;
  final bool hideTop;

  LocationState({
    this.isLoading = false,
    this.title = '',
    this.item,
    this.isRoad = false,
    this.roadItem,
    this.userPosition,
    this.startPosition,
    this.destinationPosition,
    this.button = buttonStatus.road,
    this.icon,
    this.hideBot = false,
    this.hideTop = true,
  });

  LocationState change({
    bool? isLoading,
    String? title,
    CategoryGroupItem? item,
    bool? isRoad,
    MapEntity? roadItem,
    LatLng? userPosition,
    LatLng? startPosition,
    LatLng? destinationPosition,
    buttonStatus? button,
    icon,
    hideBot,
    hideTop,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      title: title ?? this.title,
      item: item ?? this.item,
      isRoad: isRoad ?? this.isRoad,
      roadItem: roadItem ?? this.roadItem,
      userPosition: userPosition ?? this.userPosition,
      startPosition: startPosition ?? this.startPosition,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      button: button ?? this.button,
      icon: icon ?? this.icon,
      hideBot: hideBot ?? this.hideBot,
      hideTop: hideTop ?? this.hideTop,
    );
  }
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationState());

  onChangeLoading(bool isLoading) =>
      emit(state.change(isLoading: isLoading));

  onChangeRoad(bool isRoad) =>
      emit(state.change(isRoad: isRoad));

  onChangeTitle(String title) {
    emit(state.change(title: title));
  }

  onChangeItem(CategoryGroupItem item) {
    emit(state.change(item: item));
  }

  onChangeRoadItem(MapEntity roadItem) {
    emit(state.change(roadItem: roadItem));
  }

  onChangeUserPosition(LatLng userPosition) {
    emit(state.change(userPosition: userPosition));
  }

  onChangeDestinationPosition(LatLng destinationPosition) {
    emit(state.change(destinationPosition: destinationPosition));
  }

  onChangeStartPosition(LatLng startPosition) {
    emit(state.change(startPosition: startPosition));
  }

  onChangeButtonStatus(buttonStatus button) {
    emit(state.change(button: button));
  }

  onChangeIcon(icon) {
    emit(state.change(icon: icon));
  }

  onChangeBot(bool hideBot) {
    emit(state.change(hideBot: hideBot));
  }
  onChangeTop(bool hideTop) {
    emit(state.change(hideTop: hideTop));
  }
}

class ShowLocationController extends BaseController
    implements LoadDirectionDelegate{
  late final ShowLocationPresenter presenter;
  var pageFragment = Fragment();
  var confirmButtonTitle = "Включить GPS";
  final LocationCubit cubit = LocationCubit();

  final Completer<GoogleMapController> googleMapStyleController = Completer();

  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
  );

  LatLng start = LatLng(46.64121030721283, 32.61315717181116);
  LatLng destination = LatLng(46.67368818931371, 32.64299147601802);
  late GoogleMapController googleMapController;

  String? darkMapStyle;
  String? lightMapStyle;

  ShowLocationController()
      : super();

  void initState(BuildContext context) {
    this.context = context;
    var args = ModalRoute.of(context)!.settings.arguments;
    cubit.onChangeItem(args as CategoryGroupItem);
    _loadMapStyles();
    initGeoPositionUser();
    loadIcon();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  loadIcon() async {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(32, 40)), 'assets/images/map/marker.png')
        .then((onValue) {

      cubit.onChangeIcon(onValue);
      printAlert('icon = ${onValue.toJson()}');
    });
  }

  loadData () {
    presenter = ShowLocationPresenter(this);
    cubit.onChangeDestinationPosition(LatLng(46.67368818931371, 32.64299147601802));
  }

  initGeoPositionUser() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission;
    printAlert('serviceEnabled = $serviceEnabled');

    if (!serviceEnabled) {
      cubit.onChangeStartPosition(LatLng(46.67368818931371, 32.64299147601802));
      printAlert('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        cubit.onChangeStartPosition(LatLng(46.67368818931371, 32.64299147601802));
        printAlert('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      cubit.onChangeStartPosition(LatLng(46.67368818931371, 32.64299147601802));
      printAlert('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }
    _getCurrentLocation();
    _getCurrentStreamLocation();
  }

  _getCurrentStreamLocation() {
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
      cubit.onChangeUserPosition(LatLng(position!.latitude, position.longitude));
      cubit.onChangeStartPosition(LatLng(position.latitude, position.longitude));
      if (cubit.state.button == buttonStatus.closeRoad) {
        createRoute();
        onUser();
      }
    });
  }

  _getCurrentLocation() {
    Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      cubit.onChangeStartPosition(LatLng(position.latitude, position.longitude));
      cubit.onChangeButtonStatus(buttonStatus.road);
      createRoute();
    }).catchError((e) {
      print(e);
    });
  }

  returnTextButton() {
    switch (cubit.state.button) {
      case buttonStatus.road:
        return 'Включить GPS';
      case buttonStatus.closeRoad:
        return 'Отменить маршрут';
      case buttonStatus.destination:
        return 'В путь';
      default:
        return 'Включить GPS';
    }
  }

  @override
  void onDisposed() {
    presenter.dispose(); // don't forget to dispose of the presenter
    googleMapController.dispose();
    super.onDisposed();
  }

  Future _loadMapStyles() async {
    darkMapStyle = await rootBundle.loadString('assets/map/dark.json');
    lightMapStyle = await rootBundle.loadString('assets/map/light.json');
    _setMapStyle();
  }

  Future _setMapStyle() async {
    final controllerStyle = await googleMapStyleController.future;
    if (AppTheme.theme == AppThemes.dark) {
      controllerStyle.setMapStyle(darkMapStyle);
    }
    else {
      controllerStyle.setMapStyle(lightMapStyle);
    }
  }

  void goBack() {
    printAlert('goBack');
    NavigationRoutes.back(context: context);
  }

  void onPressPoint() {
    printAlert('onPressPoint');
    onDestination();
  }

  void onHide() {
    printAlert('onHide');
    cubit.onChangeBot(!cubit.state.hideBot);
  }

  String formatTime(int seconds) {
    String getParsedTime(String time) {
      if (time.length <= 1) return "0$time";
      return time;
    }


    int min = seconds ~/ 60;
    int hour = min ~/ 60;
    //int sec = seconds % 60;

    String parsedTime =
        getParsedTime(hour.toString()) + ":" + getParsedTime(min.toString());

    return parsedTime;
  }

  String formatTimeArrive(int seconds) {
    String getParsedTime(String time) {
      if (time.length <= 1) return "0$time";
      return time;
    }

    final now = DateTime.now();

    int min = seconds ~/ 60;
    int hour = min ~/ 60;
    var fiftyDaysFromNow = now.add(new Duration(hours: hour, minutes: min));
    String parsedTime =
        getParsedTime(fiftyDaysFromNow.hour.toString()) + ":" + getParsedTime(fiftyDaysFromNow.minute.toString());

    return parsedTime;
  }

  String formatKm(int value) {
    var km = (value ~/ 1000).toString();
    var m = (value % 1000).toString();
    return km + ',' + m[0];
  }

  buttonRoute() {
    switch (cubit.state.button) {
      case buttonStatus.road:
        createRoute();
        return;
      case buttonStatus.closeRoad:
        closeRoad();
        return;
      case buttonStatus.destination:
        startRoad();
        return;
    }
  }

  onUser() {
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
              target: cubit.state.userPosition ?? LatLng(0,0),
              zoom: 15,
            )
        )
    );
  }

  closeRoad() {
    printAlert('closeRoad');
    cubit.onChangeButtonStatus(buttonStatus.destination);
  }

  startRoad() {
    printAlert('startRoad');
    cubit.onChangeButtonStatus(buttonStatus.closeRoad);
    onHide();
  }

  onDestination() {
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: cubit.state.destinationPosition ?? LatLng(0,0),
          zoom: 12.5,
        )
      )
    );
    if (cubit.state.button == buttonStatus.destination)
      cubit.onChangeButtonStatus(buttonStatus.user);
  }

  Future<void> createRoute() async {
    printAlert('createRoute');
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission;
    printAlert('serviceEnabled = $serviceEnabled');

    if (!serviceEnabled) {
      AppToast.show(
        context: context,
        text: 'Нужно включить локацию.',
        type: AppToastType.negative,
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppToast.show(
          context: context,
          text: 'К сожалению мы не можем постоить марштур без вашей локации.',
          type: AppToastType.negative,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppToast.show(
        context: context,
        text: 'К сожалению мы не можем постоить марштур без вашей локации.',
        type: AppToastType.negative,
      );
      return;
    }
    Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      cubit.onChangeUserPosition(LatLng(position.latitude, position.longitude));
      presenter.createRoute(origin: LatLng(position.latitude, position.longitude), destination: destination);
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void onLoadDirection(MapEntity? data) {
    printAlert('Data = $data');
    cubit.onChangeRoad(true);
    cubit.onChangeRoadItem(data!);
    if (cubit.state.button != buttonStatus.closeRoad)
      cubit.onChangeButtonStatus(buttonStatus.destination);
    cubit.onChangeTop(false);
  }

  @override
  void onLoadDirectionError(AppCaseError<Object?> message) {
    printAlert('Data = $message');
  }

}
