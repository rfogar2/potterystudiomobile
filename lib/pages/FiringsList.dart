import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:pottery_studio/common/DateFormatter.dart';
import 'package:pottery_studio/common/FiringTypeFormatter.dart';
import 'package:pottery_studio/common/HttpRetryDialog.dart';
import 'package:pottery_studio/common/TextStyles.dart';
import 'package:pottery_studio/interactors/FiringListInteractor.dart';
import 'package:pottery_studio/models/Firing.dart';
import 'package:pottery_studio/pages/FiringPage.dart';
import 'package:pottery_studio/views/ToggleButtonView.dart';

class FiringsList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FiringListState();
}

class _FiringListState extends State<FiringsList> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    try {
      await Provider.of<FiringListInteractor>(context, listen: false).getAll();
    } catch (e) {
      HttpRetryDialog().retry(context, _refreshController.requestRefresh);
    } finally {
      _refreshController.refreshCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firings"),
        backgroundColor: Colors.white,
      ),
      body: Consumer<FiringListInteractor>(
        builder: (context, interactor, _) {
          return SmartRefresher(
            onRefresh: _onRefresh,
            controller: _refreshController,
            child: ListView.builder(
                itemBuilder: (buildContext, index) {
                  if (index == 0) {
                    return Consumer<FiringListInteractor>(
                      builder: (context, useCase, _) {
                        return ToggleButtonView(
                          title: "firings",
                          toggleOn: useCase.includePast,
                          onToggle: _togglePastFiringsShown,
                        );
                      },
                    );
                  } else if (interactor.firings.length == 0 && index == 1) {
                    return Center(child: Text("No firings to show"));
                  } else if (index < interactor.firings.length + 1) {
                    var firing = interactor.firings.elementAt(index - 1);

                    return _firingCard(firing);
                  } else {
                    return Container(
                        height: 72.0); // padding for bottom of list
                  }
                },
                itemCount: interactor.firings.length == 0
                    ? 3
                    : interactor.firings.length + 2),
          );
        },
      ),
    );
  }

  void _togglePastFiringsShown() {
    var interactor = Provider.of<FiringListInteractor>(context, listen: false);

    interactor.setIncludePast(!interactor.includePast);
    _refreshController.requestRefresh();
  }

  Widget _firingCard(Firing firing) {
    return Card(
      elevation: 2.0,
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          var shouldRefreshList = await Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => FiringPage(firingId: firing.id)));

          if (shouldRefreshList ?? false) {
            _refreshController.requestRefresh();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      DateFormatter()
                          .formatDateTimeRange(firing.start, firing.end),
                      style: TextStyles.mediumRegularStyle),
                  Text(
                      "Done cooling down: ${DateFormatter().dd_MMMM.format(firing.cooldownEnd)} ${DateFormatter().HH_mm.format(firing.cooldownEnd)}",
                      style: TextStyles.mediumRegularStyle),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(FiringTypeFormatter().format(firing.type),
                  style: TextStyles.mediumBoldStyle),
            ),
          ],
        ),
      ),
    );
  }
}
