import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:munch_app/api/authentication.dart';
import 'package:munch_app/components/dialog.dart';
import 'package:munch_app/styles/colors.dart';
import 'package:munch_app/styles/icons.dart';
import 'package:munch_app/styles/texts.dart';

class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _OnBoardingInfo()),
          _OnBoardingBottom(),
        ],
      ),
    );
  }
}

class _OnBoardingInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(MunchColors.black40, BlendMode.srcOver),
          image: AssetImage('assets/img/tastebud_onboarding.jpg'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              alignment: Alignment.topRight,
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(MunchIcons.navigation_cancel),
                color: MunchColors.white,
                onPressed: () =>
                    Navigator.of(context).pop(AuthenticationState.cancel),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 64,
                    margin: EdgeInsets.only(top: 12),
                    child: Image(
                      image:
                          AssetImage('assets/img/munch_logo_titled_white.png'),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: 24, right: 24, top: 40, bottom: 40),
                    child: Column(
                      children: [
                        Text(
                          "Discover Delicious",
                          style:
                              MTextStyle.h1.copyWith(color: MunchColors.white),
                          textAlign: TextAlign.center,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Text(
                            "Whether you're looking for the perfect date spot or the hottest bar in town - Munch helps you answer the question:",
                            style: MTextStyle.h4.copyWith(
                              height: 1,
                              color: MunchColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          "'What do you want to eat?'",
                          style: MTextStyle.h4.copyWith(
                            height: 1,
                            color: MunchColors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnBoardingBottom extends StatelessWidget {
  void onLogin(BuildContext context) {
    FacebookLogin()
        .logInWithReadPermissions(['email', 'public_profile']).then((result) {
      switch (result.status) {
        case FacebookLoginStatus.loggedIn:
          return Authentication.instance
              .loginFacebook(result.accessToken.token)
              .then((state) {
            Navigator.of(context).pop(AuthenticationState.loggedIn);
            return state;
          }).catchError((error) {
            MunchDialog.showError(context, error);
          });

        case FacebookLoginStatus.error:
          return showDialog(
            context: context,
            builder: (context) => MunchDialog.error(context,
                title: 'Authentication Error', content: result.errorMessage),
          );

        case FacebookLoginStatus.cancelledByUser:
          return Future.value(AuthenticationState.cancel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, right: 24, top: 16),
          height: 44,
          width: double.infinity,
          child: MaterialButton(
            elevation: 0,
            onPressed: () => onLogin(context),
            color: const Color(0xFF4267b2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(MunchIcons.onboarding_facebook,
                    color: MunchColors.white),
                const Expanded(
                  child: Text(
                    "Continue with Facebook",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MunchColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          child: Text(
            "By signing up, you agree to Munch's terms of use and privacy policy.",
            style: MTextStyle.subtext.copyWith(height: 1.3),
            textAlign: TextAlign.center,
          ),
          margin:
              const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
        ),
      ],
    );
  }
}