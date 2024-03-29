import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pottery_studio/common/HttpRetryDialog.dart';
import 'package:pottery_studio/common/TextStyles.dart';
import 'package:pottery_studio/interactors/CreateAccountInteractor.dart';
import 'package:pottery_studio/services/AuthService.dart';
import 'package:pottery_studio/views/EditablePhoto.dart';
import 'package:provider/provider.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _usersNameController = TextEditingController();
  final _studioCodeController = TextEditingController();
  final _studioNameController = TextEditingController();

  bool _createUserSelected;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      _fetchUsersName();
      _initProfileImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: InkResponse(
              onTap: _cancel,
              child: Icon(
                Icons.arrow_back,
                color: Colors.black,
              )),
          title: Text("Create account"),
        ),
        body: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<CreateAccountInteractor>(
                builder: (context, interactor, _) {
              return EditablePhoto(
                loading: interactor.uploadingImage,
                imageUrl: interactor.profileImageUrl,
                onChange: _onChangeImage,
                onDelete: interactor.removePhoto,
              );
            }),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  TextField(
                      controller: _usersNameController,
                      decoration: InputDecoration(labelText: "Display name")),
                  Container(height: 24.0),
                  _toggle(),
                  Container(height: 48.0),
                  _createUserWidget(),
                  _createStudioWidget()
                ],
              ),
            )
          ],
        )));
  }

  Widget _toggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FlatButton(
            color: _createUserSelected == true
                ? Theme.of(context).accentColor.withAlpha(100)
                : Colors.grey.withAlpha(100),
            child: Text("Join an existing studio"),
            onPressed: () {
              setState(() {
                _createUserSelected = true;
              });
            }),
        FlatButton(
            color: _createUserSelected == null
                ? Colors.grey.withAlpha(100)
                : (_createUserSelected == false
                    ? Theme.of(context).accentColor.withAlpha(100)
                    : Colors.grey.withAlpha(100)),
            child: Text("Create a new studio"),
            onPressed: () {
              setState(() {
                _createUserSelected = false;
              });
            }),
      ],
    );
  }

  Widget _createUserWidget() {
    return Visibility(
      visible: _createUserSelected == true,
      child: Column(
        children: <Widget>[
          Text(
            "To register with an existing studio, enter the studio code and click \"Create account\".",
            style: TextStyles.mediumRegularStyle,
          ),
          TextField(
            controller: _studioCodeController,
            decoration: InputDecoration(labelText: "Studio code"),
            enableSuggestions: false,
            textCapitalization: TextCapitalization.words,
          ),
          _createUserButton()
        ],
      ),
    );
  }

  Widget _createStudioWidget() {
    return Visibility(
      visible: _createUserSelected == false,
      child: Column(
        children: <Widget>[
          Text(
              "To create a new studio, enter your desired studio name and click \"Create studio\".",
              style: TextStyles.mediumRegularStyle),
          TextField(
            controller: _studioNameController,
            decoration: InputDecoration(labelText: "Studio name"),
            enableSuggestions: false,
            textCapitalization: TextCapitalization.words,
          ),
          _createStudioButton()
        ],
      ),
    );
  }

  Widget _createUserButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          Consumer<CreateAccountInteractor>(builder: (context, interactor, _) {
        return Visibility(
          visible: !interactor.loadingCreateUser,
          child: FlatButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Theme.of(context).accentColor)),
            onPressed: _createUser,
            child: Text(
              "Create account",
              style: TextStyles.mediumRegularStyle
                  .copyWith(color: Theme.of(context).accentColor),
            ),
          ),
          replacement: CircularProgressIndicator(),
        );
      }),
    );
  }

  Widget _createStudioButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          Consumer<CreateAccountInteractor>(builder: (context, interactor, _) {
        return Visibility(
          visible: !interactor.loadingCreateStudio,
          child: FlatButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Theme.of(context).accentColor)),
            onPressed: _createStudio,
            child: Text(
              "Create studio",
              style: TextStyles.mediumRegularStyle
                  .copyWith(color: Theme.of(context).accentColor),
            ),
          ),
          replacement: CircularProgressIndicator(),
        );
      }),
    );
  }

  void _cancel() async {
    var authService = Provider.of<AuthService>(context);
    await authService.signOut(context);
  }

  void _fetchUsersName() async {
    var authService = Provider.of<AuthService>(context);
    var currentUser = await authService.currentUser;

    _usersNameController.text = currentUser.displayName;
  }

  void _initProfileImage() async {
    var createAccountInteractor = Provider.of<CreateAccountInteractor>(context);
    createAccountInteractor.clear();
    createAccountInteractor.initFromFirebaseUser();
  }

  void _createUser() async {
    try {
      await Provider.of<CreateAccountInteractor>(context)
          .createUser(_studioCodeController.text, _usersNameController.text);
    } catch (e) {
      HttpRetryDialog().retry(context, _createUser);
    }
  }

  void _createStudio() async {
    try {
      await Provider.of<CreateAccountInteractor>(context)
          .createStudio(_usersNameController.text, _studioNameController.text);
    } catch (e) {
      HttpRetryDialog().retry(context, _createStudio);
    }
  }

  Future _onChangeImage(ImageSource source, String filePath) async {
    try {
      await Provider.of<CreateAccountInteractor>(context)
          .changeImage(source, filePath);
    } catch (e) {
      HttpRetryDialog().retry(context, () => _onChangeImage(source, filePath));
    }
  }
}
