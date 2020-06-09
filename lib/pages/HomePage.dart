import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pottery_studio/common/HttpRetryDialog.dart';
import 'package:pottery_studio/common/TextStyles.dart';
import 'package:pottery_studio/interactors/FiringListInteractor.dart';
import 'package:pottery_studio/pages/FiringsList.dart';
import 'package:pottery_studio/pages/ManageFiringPage.dart';
import 'package:pottery_studio/pages/ManageOpeningPage.dart';
import 'package:pottery_studio/pages/OpeningsList.dart';
import 'package:pottery_studio/pages/ProfilePage.dart';
import 'package:pottery_studio/services/AuthService.dart';
import 'package:pottery_studio/usecases/GetAllOpeningsUseCase.dart';
import 'package:pottery_studio/usecases/GetPresentUsersUseCase.dart';
import 'package:pottery_studio/usecases/GetUserUseCase.dart';
import 'package:pottery_studio/views/CheckedIn.dart';
import 'package:pottery_studio/views/FiringCard.dart';
import 'package:pottery_studio/views/HomePageSettings.dart';
import 'package:pottery_studio/views/OpeningCard.dart';
import 'package:pottery_studio/views/ProfileImage.dart';
import 'package:pottery_studio/views/UpcomingListPreview.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, _initWithContext);
  }

  _initWithContext() {
    _getOpenings();
    _getFirings();
    _getUser();
    _getPresentUsers();
  }

  _getOpenings() async {
    try {
      await Provider.of<GetAllOpeningsUseCase>(context, listen: false).invoke();
    } catch (e) {
      print(e);
    }
  }

  _getFirings() async {
    try {
      await Provider.of<FiringListInteractor>(context, listen: false).getAll();
    } catch (e) {
      HttpRetryDialog().retry(context, _getFirings);
    }
  }

  _getUser() async {
    try {
      await Provider.of<GetUserUseCase>(context, listen: false).getUser();
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("An error occurred while fetching your details."),
              actions: [
                FlatButton(
                  child: Text("Sign out"),
                  onPressed: () {
                    Provider.of<AuthService>(context, listen: false)
                        .signOut(context);
                  },
                ),
                FlatButton(
                  child: Text("Retry"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _getUser();
                  },
                ),
              ],
            );
          });
    }
  }

  void _refresh() {
    _refreshController.refreshCompleted();

    _getOpenings();
    _getFirings();
    _getPresentUsers();
  }

  Future _getPresentUsers() async {
    try {
      await Provider.of<GetPresentUsersUseCase>(context, listen: false)
          .invoke();
    } catch (e) {
      HttpRetryDialog().retry(context, _getPresentUsers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4.0,
        backgroundColor: Colors.white,
        title: Consumer<GetUserUseCase>(builder: (context, useCase, _) {
          return Text(useCase.user?.studioName ?? "Loading...",
              style: TextStyles().bigRegularStyle);
        }),
        actions: <Widget>[
          InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage())),
              child: Consumer<GetUserUseCase>(builder: (context, useCase, _) {
                return Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, top: 4.0, right: 16.0, bottom: 4.0),
                  child: ProfileImage(imageUri: useCase.user?.imageUrl),
                );
              })),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return SmartRefresher(
      onRefresh: _refresh,
      controller: _refreshController,
      child: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          _studioBanner(),
          CheckedIn(),
          _upcomingOpenings(),
          _upcomingFirings(),
          Divider(),
          HomePageSettings(),
        ],
      )),
    );
  }

  Widget _studioBanner() {
    return Consumer<GetUserUseCase>(
      builder: (context, useCase, _) {
        return Visibility(
            visible: useCase.user?.studioBanner != null,
            child: Container(
              width: double.infinity,
              child: Card(
                margin: EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Studio notes",
                            style: TextStyles().bigRegularStyle),
                        Container(height: 8),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(useCase.user?.studioBanner,
                                style: TextStyles().mediumRegularStyle,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }

  Widget _upcomingFirings() {
    return Consumer<FiringListInteractor>(builder: (context, interactor, _) {
      var upcomingFirings = interactor.firings
          .where((opening) =>
              !opening.cooldownEnd.difference(DateTime.now()).isNegative)
          .take(3);

      List<Widget> firingCards = upcomingFirings
          .map((firing) =>
              FiringCard(firing: firing, promptRefresh: _getFirings))
          .toList();

      return UpcomingListPreview(
        onPressedAdd: _addFiring,
        refreshList: _getFirings,
        itemType: "firings",
        children: firingCards,
        viewAll: FiringsList(),
        loading: interactor.loading,
      );
    });
  }

  Widget _upcomingOpenings() {
    return Consumer<GetAllOpeningsUseCase>(builder: (context, useCase, _) {
      var upcomingOpenings = useCase.openings
          .where(
              (opening) => !opening.end.difference(DateTime.now()).isNegative)
          .take(3);

      List<Widget> openingCards = upcomingOpenings
          .map(
              (opening) => OpeningCard(opening: opening, refresh: _getOpenings))
          .toList();

      return UpcomingListPreview(
        onPressedAdd: _addOpening,
        refreshList: _getOpenings,
        itemType: "openings",
        children: openingCards,
        viewAll: OpeningsList(),
        loading: useCase.loading,
      );
    });
  }

  void _addFiring() async {
    var shouldRefreshList = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => ManageFiringPage()));

    if (shouldRefreshList ?? false) {
      try {
        await _refreshFiringList();
      } catch (e) {
        HttpRetryDialog().retry(context, _refreshFiringList);
      }
    }
  }

  Future _refreshFiringList() async {
    return await Provider.of<FiringListInteractor>(context, listen: false)
        .getAll();
  }

  void _addOpening() async {
    var shouldRefreshList = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => ManageOpeningPage()));

    if (shouldRefreshList ?? false) {
      try {
        await _refreshOpeningList();
      } catch (e) {
        HttpRetryDialog().retry(context, _refreshOpeningList);
      }
    }
  }

  Future _refreshOpeningList() async {
    return await Provider.of<GetAllOpeningsUseCase>(context, listen: false)
        .invoke();
  }
}
