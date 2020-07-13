import 'package:flutter_svg/flutter_svg.dart';
import 'package:digitalrand/redux/actions/user_actions.dart';
import 'package:digitalrand/screens/misc/pincode.dart';
import 'package:digitalrand/utils/biometric_local_auth.dart';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:digitalrand/generated/i18n.dart';
import 'package:digitalrand/models/app_state.dart';
import 'package:digitalrand/screens/routes.gr.dart';
import 'package:digitalrand/widgets/main_scaffold.dart';
import 'package:digitalrand/models/views/onboard.dart';

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  BiometricAuth _biometricType;

  Future<void> _checkBiometricable() async {
    _biometricType = await BiometricUtils.getAvailableBiometrics();
    if (_biometricType != BiometricAuth.none) {
      setState(() {
        _biometricType = _biometricType;
      });
    }
  }

  @override
  void initState() {
    _checkBiometricable();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OnboardViewModel>(
        distinct: true,
        converter: OnboardViewModel.fromStore,
        builder: (_, viewModel) {
          return MainScaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              withPadding: true,
              title: I18n.of(context).protect_wallet,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                      left: 40.0, right: 20.0, bottom: 20.0, top: 0.0),
                  child: Text(I18n.of(context).choose_lock_method,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      )),
                )
              ],
              footer: StoreConnector<AppState, _SecurityViewModel>(
                  distinct: true,
                  converter: _SecurityViewModel.fromStore,
                  builder: (_, viewModel) {
                    return Container(
                      padding: EdgeInsets.only(top: 20, bottom: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(height: 20.0),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              InkWell(
                                child: Container(
                                    height: 45,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    width:
                                        MediaQuery.of(context).size.width * .8,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Color(0xFFDEDEDE), width: 1),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30.0)),
                                      color: Theme.of(context).splashColor,
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        SvgPicture.asset(
                                            'assets/images/${BiometricAuth.faceID == _biometricType ? 'face_id' : 'fingerprint'}.svg'),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          BiometricUtils.getBiometricString(
                                              _biometricType),
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black),
                                        )
                                      ],
                                    )),
                                onTap: () async {
                                  final String biometric =
                                      BiometricUtils.getBiometricString(
                                          _biometricType);

                                  await BiometricUtils
                                      .showDefaultPopupCheckBiometricAuth(
                                    message: 'Please use $biometric to unlock!',
                                    callback: (bool result) {
                                      if (result) {
                                        viewModel
                                            .setSecurityType(_biometricType);
                                        Router.navigator
                                            .pushNamedAndRemoveUntil(
                                                Router.cashHomeScreen,
                                                (Route<dynamic> route) =>
                                                    false);
                                      }
                                    },
                                  );
                                },
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              InkWell(
                                child: Container(
                                  height: 45,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  width: MediaQuery.of(context).size.width * .8,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Color(0xFFDEDEDE), width: 1),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                    color: Theme.of(context).splashColor,
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Row(children: [
                                    SvgPicture.asset(
                                        'assets/images/pincode.svg',
                                        color: Colors.black),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(I18n.of(context).pincode,
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black))
                                  ]),
                                ),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PincodeScreen()));
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  }));
        });
  }
}

class _SecurityViewModel {
  final Function(BiometricAuth) setSecurityType;
  _SecurityViewModel({this.setSecurityType});

  static _SecurityViewModel fromStore(Store<AppState> store) {
    return _SecurityViewModel(setSecurityType: (biometricAuth) {
      store.dispatch(SetSecurityType(biometricAuth: biometricAuth));
    });
  }
}