import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:pottery_studio/common/HttpRetryDialog.dart';
import 'package:pottery_studio/common/TextStyles.dart';
import 'package:pottery_studio/interactors/FiringListInteractor.dart';
import 'package:pottery_studio/pages/FiringsList.dart';
import 'package:pottery_studio/pages/ManageFiringPage.dart';
import 'package:pottery_studio/pages/ManageOpeningPage.dart';
import 'package:pottery_studio/pages/OpeningsList.dart';
import 'package:pottery_studio/pages/ProfilePage.dart';
import 'package:pottery_studio/pages/StudioNotesPage.dart';
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
import 'package:url_launcher/url_launcher.dart' as launcher;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _studioBannerVisible = false;

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
              style: TextStyles.bigRegularStyle);
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
        return Container(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _studioBannerVisible = !_studioBannerVisible;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Studio notes", style: TextStyles.bigRegularStyle),
                        Icon(
                            _studioBannerVisible
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Theme.of(context).accentColor)
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _studioBannerVisible,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, top: 16, right: 8, bottom: 8),
                              child: Linkify(
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                text: useCase.user?.studioBanner ?? "",
                                style: TextStyles.mediumRegularStyle,
                                onOpen: (link) => launch(link.url),
                              )),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: BorderSide(
                                        color: Theme.of(context).accentColor)),
                                child: Text(
                                  "More",
                                  style: TextStyles.mediumRegularStyle.copyWith(
                                      color: Theme.of(context).accentColor),
                                ),
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => StudioNotesPage())))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future launch(String url) async {
    if (await launcher.canLaunch(url)) {
      await launcher.launch(url);
    }
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
