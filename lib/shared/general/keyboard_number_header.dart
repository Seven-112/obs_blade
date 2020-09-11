import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class KeyboardNumberHeader extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;

  KeyboardNumberHeader({@required this.child, @required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Color.fromRGBO(45, 45, 45, 1.0),
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: this.focusNode,
          ),
        ],
      ),
      disableScroll: true,
      child: this.child,
    );
  }
}
