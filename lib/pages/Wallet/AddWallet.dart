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
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddWalletPage extends StatefulWidget{
  final String title;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Map<String, String> idpIdToUrl;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;
  AddWalletPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic, this.idpIdToUrl}) : super(key: key);

  @override
  _AddWalletPageState createState() => _AddWalletPageState();
}

class _AddWalletPageState extends State<AddWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final qrCodeController = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController qrController;


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
              controller: qrCodeController,
              decoration: InputDecoration(
                  hintText: 'QR Code'
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
                    AddWalletRequest addWalletRequest = new AddWalletRequest();
                    addWalletRequest.qRcode = qrCodeController.text;
                    await WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['addWalletWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['addWalletNotifyHandlerUUID']], addWalletRequest, AddWalletResponse(), (){});
                    await WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listWalletsWriteHandlerUUID']], addWalletRequest);
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ),
            Expanded (
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                )
            )
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrCodeController.text = scanData;
      });
    });
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }
}

