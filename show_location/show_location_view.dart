import 'package:adviser/adviser/fca/app/cell/modal_location/region_location.dart';
import 'package:adviser/adviser/fca/app/components/app_buttons/app_button.dart';
import 'package:adviser/adviser/fca/app/components/app_buttons/app_icon_button.dart';
import 'package:adviser/adviser/fca/app/pages/location/show_location/show_location_controller.dart';
import 'package:adviser/adviser/fca/app/styles/text_styles/app_text_style.dart';
import 'package:adviser/adviser/fca/app/styles/ui_style/appbar/appbar_presets_style.dart';
import 'package:adviser/adviser/fca/app/styles/ui_style/base_style.dart';
import 'package:adviser/adviser/fca/app/styles/ui_style/button/button_style.dart';
import 'package:adviser/adviser/fca/app/styles/ui_style/icon/icon.dart';
import 'package:adviser/adviser/fca/data/helpers/app_print.dart';
import 'package:adviser/adviser/resources/constants/colors.dart';
import 'package:adviser/adviser/resources/constants/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShowLocationPage extends View {
  ShowLocationPage({Key? key, required BuildContext context}) : super(key: key);

  @override
  _ShowLocationPageState createState() {
    return _ShowLocationPageState(ShowLocationController());
  }
}

class _ShowLocationPageState
    extends ViewState<ShowLocationPage, ShowLocationController> {
  final ShowLocationController controller;

  _ShowLocationPageState(this.controller) : super(controller);

  @override
  Widget get view {
    return body(
      content: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          mapContainer(),
          getBackButton(),
          animateContainer(),
        ],
      ),
    );
  }

  Widget body({
    required Widget content,
  }) {
    controller.initState(context);
    return Scaffold(
        backgroundColor: AppColors.primaryExtraDark,
        body: BlocProvider(
          create: (BuildContext context) {
            controller.context = context;
            return controller.cubit;
          },
          child: SafeArea(
            top: true,
            bottom: true,
            child: Column(
              children: [
                Expanded(
                  child: content,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget animateContainer({
    margins,
  }) {
    return BlocBuilder<LocationCubit, LocationState>(
        buildWhen: (prev, curr) => prev != curr,
        builder: (context, state) {
          return AnimatedPositioned(
            bottom: state.hideBot ? -200 : 20,
            right: 20,
            left: 20,
            duration: const Duration(milliseconds: 800),
            child: Column(
              children: [
                Visibility(
                  visible: !state.hideTop,
                  child: informationContainer(
                    paddings: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  height: state.hideBot ? 20 : 10,
                ),
                bottomContainer(),
              ],
            ),
          );
        }
    );
  }

  Widget informationContainer({
    margins,
    paddings,
  }) {
    return BlocBuilder<LocationCubit, LocationState>(
        buildWhen: (prev, curr) => prev != curr,
      builder: (context, state) {
        return Container(
            margin: margins,
            padding: paddings,
            decoration: BoxDecoration(
              color: AppColors.primaryExtraDark,
              borderRadius: BorderRadius.all(Radius.circular(BaseStyle.defaultRadiusCard)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIconButton(
                  margin: EdgeInsets.only(left: 12),
                  style: AppButtonIconSuperUltraSmallTransparentStyle(),
                  iconStyle: AppIconStyle(
                    width: 10.5,
                    height: 15,
                    path: 'assets/icons/point.svg',
                    color: AppTheme.colorAccept,
                  ),
                  onPressed: () {
                    controller.onPressPoint();
                  },
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (state.roadItem != null)
                      Text(
                        controller.formatTimeArrive(int.parse(state.roadItem!.totalDuration)),
                      ),
                    Text(
                      'Прибытие',
                      style: AppTextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    )
                  ],
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: AppColors.primary,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (state.roadItem != null)
                      Text(
                        controller.formatKm(int.parse(state.roadItem!.totalDistance)),
                        style: AppTextStyle(
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    Text(
                      'Км',
                      style: AppTextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    )
                  ],
                ),
                if (state.button == buttonStatus.closeRoad)
                  Container(
                    height: 36,
                    width: 1,
                    color: AppColors.primary,
                  ),
                if (state.button == buttonStatus.closeRoad)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (state.roadItem != null)
                        Text(
                          controller.formatTime(int.parse(state.roadItem!.totalDuration)),
                        ),
                      Text(
                        'Мин',
                        style: AppTextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      )
                    ],
                  ),
                Container(
                  margin: EdgeInsets.only(left: 15, right: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                  child: AppIconButton(
                    style: AppButtonIconSuperUltraSmallTransparentStyle(),
                    iconStyle: AppIconStyle(
                      width: 12,
                      height: 7,
                      path: !state.hideBot ? 'assets/icons/arrow_down_stroke.svg' : 'assets/icons/arrow_up_stroke.svg',
                      color: AppTheme.colorAccept,
                      // path: 'assets/icons/arrow_up.svg',
                    ),
                    onPressed: () {
                      controller.onHide();
                    },
                  ),
                )
              ],
            ),
          );
      }
    );
  }

  Widget bottomContainer({
    margins,
  }) {
    return BlocBuilder<LocationCubit, LocationState>(
        buildWhen: (prev, curr) => prev != curr,
      builder: (context, state) {
        return Container(
            margin: margins,
            padding: EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              color: AppColors.primaryExtraDark,
              borderRadius: BorderRadius.all(Radius.circular(BaseStyle.defaultRadiusCard)),
            ),
            child: Column(
              children: [
                _getOrganizationName(
                  name: state.item!.title,
                ),
                Container(
                  child: ModalRegionLocationCell(
                    text: state.item!.subTitle,
                    flex: MainAxisAlignment.center,
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
                    child: GestureDetector(
                      onTap: () => controller.buttonRoute(),
                      child: AppButton(
                        text: controller.returnTextButton(),
                        style: state.button == buttonStatus.closeRoad ? AppButtonDeleteStyle() : AppButtonStyle(),
                      ),
                    )
                ),
              ],
            ),
          );
      }
    );
  }

  Container _getOrganizationName({name: String}) {
    final dotHeight = 8.0;

    final text1 = Text(
      name,
      textAlign: TextAlign.left,
      style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.white),
    );

    final statusImage = Container(
      width: dotHeight,
      height: dotHeight,
      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(dotHeight / 2)),
          color: AppColors.blue),
    );

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [text1, statusImage],
    );

    final result = Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: row,
    );

    return result;
  }

  Widget getBackButton() {
    return Positioned(
      top: 0,
      left: 20,
      child: getNavButton(
        iconStyle: AppBarStyles.category.buttonLeftIconStyle,
        onPressed: () => controller.goBack(),
        backgroundColor: AppBarStyles.category.backgroundButtonColor,
      ),
    );
  }

  Widget getNavButton({
    Key? key,
    required AppIconStyle iconStyle,
    required VoidCallback onPressed,
    required Color? backgroundColor,
  }) {
    return AppIconButton(
      key: key,
      style: AppButtonColoredIconStyle(
        color: backgroundColor,
        iconStyle: iconStyle,
      ),
      margin: EdgeInsets.symmetric(vertical: 13),
      onPressed: onPressed,
    );
  }

  Widget mapContainer() {
    return BlocBuilder<LocationCubit, LocationState>(
    buildWhen: (prev, curr) => prev != curr,
      builder: (context, state) {
      printAlert(state.startPosition);
        return Column(
          children: [
            if (state.startPosition != null)
              Expanded(
                child:
                  Container(
                    child: GoogleMap(
                      myLocationEnabled: state.userPosition != null,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      initialCameraPosition: CameraPosition(
                        zoom: 12.5,
                        target: state.startPosition ?? LatLng(0,0),
                      ),
                      markers: {
                        if (state.destinationPosition != null && state.icon != null)
                          _destination(
                            position: state.destinationPosition ?? LatLng(0,0),
                            icon: state.icon,
                          ),
                      },
                      polylines: {
                        if (state.roadItem != null && state.button == buttonStatus.destination)
                          Polyline(
                            polylineId: const PolylineId('road'),
                            color: AppColors.alphaLightBlue50,
                            width: 10,
                            points: state.roadItem!.polylinePoints
                                .map((e) => LatLng(e.latitude, e.longitude))
                                .toList(),
                          ),
                        if (state.roadItem != null  && state.button == buttonStatus.closeRoad)
                          Polyline(
                            polylineId: const PolylineId('road'),
                            color: AppColors.alphaLightBlue,
                            width: 5,
                            points: state.roadItem!.polylinePoints
                                .map((e) => LatLng(e.latitude, e.longitude))
                                .toList(),
                          ),
                      },
                      onMapCreated: (GoogleMapController controllers) {
                          controller.googleMapController = controllers;
                          controller.googleMapStyleController.complete(controllers);
                      }),
                    ),
                ),
          ],
        );
      }
    );
  }

  Marker _destination({
    required LatLng position,
    icon
  }) {
    return Marker(
      markerId: const MarkerId('destination'),
      infoWindow: const InfoWindow(title: 'destination'),
      icon: icon,

      position: position,
    );
  }
}
