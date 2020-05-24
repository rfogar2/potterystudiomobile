import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:seven_spot_mobile/common/SupportsAppleLogin.dart';
import 'package:seven_spot_mobile/common/TextStyles.dart';
import 'package:seven_spot_mobile/services/AuthService.dart';
import 'package:seven_spot_mobile/views/ThirdPartySignInButton.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
            child: Stack(
          children: <Widget>[
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Column(
                children: <Widget>[
                  Text(
                    "Pottery Studio",
                    style: TextStyles().bigBoldStyle.copyWith(fontSize: 24.0),
                  ),
                  Text("(Beta)", style: TextStyles().smallRegularStyle)
                ],
              ),
            ),
            Positioned(
                top: 0,
                bottom: 0,
                left: 64,
                right: 64,
                child: Image(
                    image: AssetImage("assets/ic_launcher.png"),
                    width: 128.0,
                    color: Theme.of(context).primaryColor)),
            Positioned(
                bottom: 32, left: 16, right: 16, child: _loginOrAutoLogin())
          ],
        )),
      ),
    );
  }

  Widget _loginOrAutoLogin() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Visibility(
          visible: authService.authenticating,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
            ],
          ),
          replacement: Column(
            children: <Widget>[
              ThirdPartySignInButton(
                logoUri: "assets/google_logo.png",
                thirdPartyProvider: "Google",
                onPressed: _continueWithGoogle,
                borderColor: Theme.of(context).accentColor,
              ),
              _appleSignInButton()
            ],
          ),
        );
      },
    );
  }

  Widget _appleSignInButton() {
    return Visibility(
        visible: SupportsAppleLogin().supported,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ThirdPartySignInButton(
            logoUri: "assets/apple_logo.png",
            thirdPartyProvider: "Apple",
            onPressed: _continueWithApple,
            borderColor: Colors.black,
          ),
        ));
  }

  Future<void> _continueWithGoogle() async {
    try {
      final authService = Provider.of<AuthService>(context);
      await authService.continueWithGoogle();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _continueWithApple() async {
    try {
      final authService = Provider.of<AuthService>(context);
      await authService.continueWithApple();
    } catch (e) {
      print(e.toString());
    }
  }
}
