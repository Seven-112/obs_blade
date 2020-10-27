import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/past_stream_data.dart';
import '../../../utils/routing_helper.dart';

import '../../../types/extensions/int.dart';

class StreamEntry extends StatelessWidget {
  final PastStreamData pastStreamData;

  StreamEntry({@required this.pastStreamData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        this.pastStreamData.starred != null &&
                                this.pastStreamData.starred
                            ? Icons.star
                            : Icons.star_border,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        this.pastStreamData.name ?? 'Unnamed stream',
                        style: Theme.of(context).textTheme.button.copyWith(
                              fontSize: 18.0,
                            ),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                StaticticsTabRoutingKeys.Detail.route,
                arguments: this.pastStreamData,
              ),
              subtitle: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 45.0,
                        child: Text('From: '),
                      ),
                      Text(
                          '${(this.pastStreamData.listEntryDateMS.last - this.pastStreamData.totalStreamTime * 1000).millisecondsToFormattedDateString()}'),
                      Text(' - '),
                      Text(
                          '${(this.pastStreamData.listEntryDateMS.last - this.pastStreamData.totalStreamTime * 1000).millisecondsToFormattedTimeString()}'),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 45.0,
                        child: Text('To: '),
                      ),
                      Text(
                          '${(this.pastStreamData.listEntryDateMS.last).millisecondsToFormattedDateString()}'),
                      Text(' - '),
                      Text(
                          '${(this.pastStreamData.listEntryDateMS.last).millisecondsToFormattedTimeString()}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
