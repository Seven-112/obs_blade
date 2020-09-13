import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/general/keyboard_number_header.dart';
import 'package:obs_blade/shared/general/validation_cupertino_textfield.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/validation_helper.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';

class EditConnectionDialog extends StatefulWidget {
  final Connection connection;

  EditConnectionDialog({@required this.connection});

  @override
  _EditConnectionDialogState createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  TextEditingController _name;
  TextEditingController _ip;
  TextEditingController _port;
  TextEditingController _pw;

  GlobalKey<ValidationCupertinoTextfieldState> _nameValidator = GlobalKey();
  GlobalKey<ValidationCupertinoTextfieldState> _ipValidator = GlobalKey();
  GlobalKey<ValidationCupertinoTextfieldState> _portValidator = GlobalKey();

  FocusNode _portFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.connection.name);
    _ip = TextEditingController(text: widget.connection.ip);
    _port = TextEditingController(text: widget.connection.port.toString());
    _pw = TextEditingController(text: widget.connection.pw);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Row(
        children: [
          Text('Edit Connection'),
          CupertinoButton(
            child: Text(
              'Delete',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (context) => ConfirmationDialog(
                  title: 'Delete Connection',
                  body:
                      'Are you sure you want to delete this connection? This action can\'t be undone!',
                  isYesDestructive: true,
                  onOk: () {
                    Navigator.of(context).pop();
                    widget.connection.delete();
                  },
                ),
              );
            },
          ),
        ],
      ),
      content: Column(
        children: [
          Text(
              'Change the following information to change your saved connection'),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: ValidationCupertinoTextfield(
              key: _nameValidator,
              controller: _name..addListener(() => setState(() {})),
              placeholder: 'Name',
              autocorrect: true,
              check: (name) => name.trim().length == 0
                  ? 'Please provide a name!'
                  : name.trim() != widget.connection.name &&
                          Hive.box<Connection>(HiveKeys.SavedConnections.name)
                              .values
                              .any((connection) => connection.name == name)
                      ? 'Name already in use!'
                      : '',
            ),
          ),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: ValidationCupertinoTextfield(
                  key: _ipValidator,
                  controller: _ip..addListener(() => setState(() {})),
                  placeholder: 'IP',
                  check: (ip) => ValidationHelper.ipValidation(ip),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: KeyboardNumberHeader(
                    focusNode: _portFocusNode,
                    child: ValidationCupertinoTextfield(
                      key: _portValidator,
                      controller: _port..addListener(() => setState(() {})),
                      focusNode: _portFocusNode,
                      placeholder: 'Port',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      check: (port) => ValidationHelper.portValidation(port),
                    ),
                  ),
                ),
              ),
            ],
          ),
          CupertinoTextField(
            controller: _pw,
            placeholder: 'Password',
            autocorrect: false,
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('Cancel'),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        Builder(
          builder: (context) => CupertinoDialogAction(
            child: Text('Save'),
            onPressed: _nameValidator.currentState.isValid &&
                    _ipValidator.currentState.isValid &&
                    _portValidator.currentState.isValid
                ? () {
                    Navigator.of(context).pop();
                    widget.connection.name = _name.text.trim();
                    widget.connection.ip = _ip.text;
                    widget.connection.port = int.parse(_port.text);
                    widget.connection.pw = _pw.text;
                    widget.connection.save();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
