import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../add_edit_theme/add_edit_theme.dart';
import 'theme_colors_row.dart';

class ThemeEntry extends StatelessWidget {
  final CustomTheme customTheme;

  ThemeEntry({@required this.customTheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.ActiveCustomThemeUUID.name,
        this.customTheme.uuid,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                  width: 64.0,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    ),
                    child: Hive.box(HiveKeys.Settings.name).get(
                                SettingsKeys.ActiveCustomThemeUUID.name,
                                defaultValue: '') ==
                            this.customTheme.uuid
                        ? Icon(
                            CupertinoIcons.check_mark,
                            size: 42.0,
                            color: Theme.of(context).accentColor,
                          )
                        : Container(),
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(this.customTheme.name ?? 'Unnamed theme'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                    ),
                    child: ThemeColorsRow(
                      customTheme: this.customTheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(right: 24.0),
            child: Text('Edit'),
            onPressed: () => ModalHandler.showBaseCupertinoBottomSheet(
              context: context,
              modalWidgetBuilder: (context, scrollController) => AddEditTheme(
                customTheme: this.customTheme,
                scrollController: scrollController,
              ),
            ),
          )
        ],
      ),
    );
  }
}
