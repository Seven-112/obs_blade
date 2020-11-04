import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:provider/provider.dart';

class ExcludeUnnamedCheckbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Transform.translate(
      offset: Offset(-12.0, 0.0),
      child: Row(
        children: [
          Observer(
            builder: (_) => Checkbox(
              // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: statisticsStore.excludeUnnamedStreams,
              onChanged: (excludeUnnamedStreams) => statisticsStore
                  .setExcludeUnnamedStreams(excludeUnnamedStreams),
            ),
          ),
          Text(
            'Exclude unnamed streams',
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ],
      ),
    );
  }
}
