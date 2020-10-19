/*
 * Copyright @ 2020 - present Blackvisor Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:nc_client/apis/generator/dart/api.pb.dart';
import 'package:nc_client/utils/WriteNotifyHandler.dart';

class ConfirmIdentityProviderPage extends StatefulWidget{
  final String title;
  final ConfirmIdentityProviderRequest confirmIdpRequest;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;

  ConfirmIdentityProviderPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic, this.confirmIdpRequest}) : super(key: key);

  @override
  _ConfirmIdentityProviderPageState createState() => _ConfirmIdentityProviderPageState();
}

class _ConfirmIdentityProviderPageState extends State<ConfirmIdentityProviderPage> {
  final _formKey = GlobalKey<FormState>();
  final confirmationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Identity Provider'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: confirmationCodeController,
              decoration: InputDecoration(
                  hintText: 'Confirmation Code'
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                onPressed: () async {
                  // Validate returns true if the form is valid, or false
                  // otherwise.
                  if (_formKey.currentState.validate()) {
                    widget.confirmIdpRequest.confirmationCode = confirmationCodeController.text;
                    await WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['confirmIdentityProviderWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['confirmIdentityProviderNotifyHandlerUUID']], widget.confirmIdpRequest, ConfirmIdentityProviderResponse(), (message){print(message);});
                    await WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listIdentityProvidersWriteHandlerUUID']], new ListIdentityProvidersRequest());
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


