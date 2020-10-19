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

class AddIdentityProviderPage extends StatefulWidget{
  final String title;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Function addToUnconfirmedIdpsCallback;
  final Map<String, ConfirmIdentityProviderRequest> unconfirmedIdps;
  final Map<String, String> idpIdToUrl;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;

  AddIdentityProviderPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic, this.unconfirmedIdps, this.addToUnconfirmedIdpsCallback, this.idpIdToUrl}) : super(key: key);

  @override
  _AddIdentityProviderPageState createState() => _AddIdentityProviderPageState();
}

class _AddIdentityProviderPageState extends State<AddIdentityProviderPage> {
  final _formKey = GlobalKey<FormState>();
  final urlFieldController = TextEditingController();
  final emailFieldController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: urlFieldController,
              decoration: InputDecoration(
                  hintText: 'URL'
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            TextFormField(
              controller: emailFieldController,
              decoration: InputDecoration(
                  hintText: 'email or phone'
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
                  if (_formKey.currentState.validate()) {
                    AddIdentityProviderRequest request = new AddIdentityProviderRequest();
                      request.identityProviderUrl = urlFieldController.text;
                      request.emailOrPhone = emailFieldController.text;
                    await WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['addIdentityProviderWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['addIdentityProviderNotifyHandlerUUID']], request, AddIdentityProviderResponse(), widget.addToUnconfirmedIdpsCallback);
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

