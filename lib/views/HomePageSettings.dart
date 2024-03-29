import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pottery_studio/pages/AboutPage.dart';
import 'package:pottery_studio/pages/RegisterAsAdminPage.dart';
import 'package:pottery_studio/services/AuthService.dart';
import 'package:pottery_studio/usecases/GetUserUseCase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class HomePageSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var authService = Provider.of<AuthService>(context, listen: false);

    return Column(
      children: <Widget>[
        Consumer<GetUserUseCase>(
          builder: (context, useCase, _) {
            return Visibility(
              visible: useCase.user?.isAdmin != true,
              child: ListTile(
                  leading:
                      Icon(Icons.person, color: Theme.of(context).accentColor),
                  title: Text("Register as admin"),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegisterAsAdminPage()))),
            );
          },
        ),
        Consumer<GetUserUseCase>(builder: (context, getUserUseCase, _) {
          return Visibility(
            visible: getUserUseCase.user?.isAdmin ?? false,
            child: ListTile(
                leading: Icon(Icons.home, color: Theme.of(context).accentColor),
                title: Text(
                    "Studio code: ${getUserUseCase.user?.studioCode} (tap to copy)"),
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: getUserUseCase.user?.studioCode));

                  final snackBar =
                      SnackBar(content: Text('Copied to Clipboard'));

                  Scaffold.of(context).showSnackBar(snackBar);
                }),
          );
        }),
        Consumer<GetUserUseCase>(builder: (context, getUserUseCase, _) {
          return Visibility(
            visible: getUserUseCase.user?.isAdmin ?? false,
            child: ListTile(
                leading: Icon(Icons.book, color: Theme.of(context).accentColor),
                title: Text(
                    "Admin code: ${getUserUseCase.user?.studioAdminCode} (tap to copy)"),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(
                      text: getUserUseCase.user?.studioAdminCode));

                  final snackBar =
                      SnackBar(content: Text('Copied to Clipboard'));

                  Scaffold.of(context).showSnackBar(snackBar);
                }),
          );
        }),
        ListTile(
            leading:
                Icon(Icons.exit_to_app, color: Theme.of(context).accentColor),
            title: Text("Sign out"),
            onTap: () => authService.signOut(context)),
        Divider(),
        ListTile(
          leading: Icon(Icons.info, color: Theme.of(context).accentColor),
          title: Text("About"),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => AboutPage())),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ListTile(
            leading: Icon(Icons.email, color: Theme.of(context).accentColor),
            title: Text("Bugs and feature requests"),
            onTap: () => _bugsAndFeatureRequests(context),
          ),
        )
      ],
    );
  }

  void _bugsAndFeatureRequests(BuildContext context) {
    showDialog(
        context: context,
        child: Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.bug_report),
                title: Text("Report a bug"),
                onTap: () => _email("Bug report"),
              ),
              ListTile(
                leading: Icon(Icons.new_releases),
                title: Text("Request a feature"),
                onTap: () => _email("Feature request"),
              ),
            ],
          ),
        ));
  }

  void _email(String subject) async {
    final uri = Uri(
      scheme: "mailto",
      path: "potterystudioapp@gmail.com",
      queryParameters: {
        "subject": subject
      }
    );

    if (await launcher.canLaunch(uri.toString())) {
      await launcher.launch(uri.toString());
    } else {
      print("Could not launch email app");
    }
  }
}
