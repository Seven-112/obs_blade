import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info/package_info.dart';

import '../../shared/general/themed_cupertino_switch.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/action_block.dart/action_block.dart';
import 'widgets/action_block.dart/block_entry.dart';
import 'widgets/support_dialog/support_dialog.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: ModalRoute.of(context).settings.arguments,
        physics: StylingHelper.platformAwareScrollPhysics,
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          ValueListenableBuilder(
            valueListenable: Hive.box(HiveKeys.Settings.name).listenable(),
            builder: (context, Box settingsBox, child) => SliverList(
              delegate: SliverChildListDelegate(
                [
                  ActionBlock(
                    title: 'Theme',
                    blockEntries: [
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_THEME_ICON,
                        leadingSize: 36.0,
                        title: 'True Dark Mode',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(SettingsKeys.TrueDark.name,
                              defaultValue: false),
                          activeColor: StylingHelper.MAIN_RED,
                          onChanged: (trueDark) {
                            settingsBox.put(
                                SettingsKeys.TrueDark.name, trueDark);
                          },
                        ),
                      ),
                      if (settingsBox.get(SettingsKeys.TrueDark.name,
                          defaultValue: false))
                        BlockEntry(
                          leading: StylingHelper.CUPERTINO_REDUCE_SMEARING_ICON,
                          leadingSize: 28.0,
                          title: 'Reduce smearing',
                          help:
                              'Only relevant for OLED displays. Using a fully black background might cause smearing while scrolling so this option will apply a slightly lighter background color.\n\nCAUTION: Might drain "more" battery!',
                          trailing: ThemedCupertinoSwitch(
                            value: settingsBox.get(
                                SettingsKeys.ReduceSmearing.name,
                                defaultValue: false),
                            activeColor: StylingHelper.MAIN_RED,
                            onChanged: (reduceSmearing) {
                              settingsBox.put(SettingsKeys.ReduceSmearing.name,
                                  reduceSmearing);
                            },
                          ),
                        ),
                    ],
                  ),
                  ActionBlock(
                    title: 'Layout',
                    blockEntries: [
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_LOCK_CLOSED_ICON,
                        leadingSize: 30.0,
                        title: 'Enforce Tablet Mode',
                        help:
                            'Elements in the Dashboard View will be displayed next to each other instead of being in tabs if the screen is big enough. If you want to you can set this manually.\n\nCAUTION: Will probably not fit your screen!',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(
                              SettingsKeys.EnforceTabletMode.name,
                              defaultValue: false),
                          activeColor: StylingHelper.MAIN_RED,
                          onChanged: (enforceTabletMode) {
                            settingsBox.put(SettingsKeys.EnforceTabletMode.name,
                                enforceTabletMode);
                          },
                        ),
                      ),
                    ],
                  ),
                  ActionBlock(
                    title: 'Misc.',
                    blockEntries: [
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_INFO_ICON,
                        leadingSize: 28.0,
                        title: 'About',
                        navigateTo: SettingsTabRoutingKeys.About.route,
                      ),
                      BlockEntry(
                        leading: CupertinoIcons.book_solid,
                        leadingSize: 28.0,
                        title: 'Privacy Policy',
                        navigateTo: SettingsTabRoutingKeys.PrivacyPolicy.route,
                      ),
                      BlockEntry(
                        leading: CupertinoIcons.heart_solid,
                        leadingSize: 28.0,
                        title: 'Support Me',
                        heroPlaceholder: CupertinoIcons.heart,
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierDismissible: true,
                            transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) =>
                                DecoratedBoxTransition(
                              decoration: DecorationTween(
                                begin: BoxDecoration(color: Colors.transparent),
                                end: BoxDecoration(color: Colors.black54),
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                            pageBuilder: (BuildContext context, _, __) =>
                                SupportDialog(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 7.0, left: 14.0),
                    child: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        return Row(
                          children: [
                            Text(
                              'Version ',
                              style: Theme.of(context).textTheme.caption,
                            ),
                            if (snapshot.hasData)
                              Text(
                                snapshot.data.version,
                                style: Theme.of(context).textTheme.caption,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
