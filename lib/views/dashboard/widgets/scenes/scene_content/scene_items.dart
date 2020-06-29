import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class SceneItems extends StatefulWidget {
  @override
  _SceneItemsState createState() => _SceneItemsState();
}

class _SceneItemsState extends State<SceneItems> {
  ScrollController _controller = ScrollController();

  _manageInnerScrollingActive() {
    print(
        '${_controller.position.pixels} + ${_controller.position.userScrollDirection}');
    print((_controller.position.pixels <=
                _controller.position.minScrollExtent &&
            _controller.position.userScrollDirection ==
                ScrollDirection.forward) ||
        (_controller.position.pixels >= _controller.position.maxScrollExtent &&
            _controller.position.userScrollDirection ==
                ScrollDirection.reverse));

    if ((_controller.position.pixels <= _controller.position.minScrollExtent &&
            _controller.position.userScrollDirection ==
                ScrollDirection.forward) ||
        (_controller.position.pixels >= _controller.position.maxScrollExtent &&
            _controller.position.userScrollDirection ==
                ScrollDirection.reverse)) {
    } else {}
    // print(_absorb);
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      dashboardStore.currentSceneItems
          ?.forEach((element) => print(element.type));
      return Scrollbar(
        child: ListView(
          padding: EdgeInsets.all(0.0),
          controller: _controller..addListener(_manageInnerScrollingActive),
          itemExtent: 50.0,
          children: [
            ...dashboardStore.currentSceneItems != null
                ? dashboardStore.currentSceneItems.map(
                    (sceneItem) => ListTile(
                      leading: Icon(Icons.filter),
                      title: Text(
                        sceneItem.name,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          sceneItem.render
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: sceneItem.render ? Colors.white : Colors.red,
                        ),
                        onPressed: () => NetworkHelper.makeRequest(
                            dashboardStore.activeSession.socket.sink,
                            RequestType.SetSceneItemProperties, {
                          'item': sceneItem.name,
                          'visible': !sceneItem.render
                        }),
                      ),
                    ),
                  )
                : [Text('No Scene Items available')]
          ],
        ),
      );
    });
  }
}
