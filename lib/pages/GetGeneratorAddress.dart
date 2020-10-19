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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:nc_client/pages/ListBLEDevices.dart';
import 'package:nc_client/utils/QRData.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class GetGeneratorAddressPage extends StatefulWidget{
  GetGeneratorAddressPage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  _GetGeneratorAddressPageState createState() => _GetGeneratorAddressPageState();

}


class _GetGeneratorAddressPageState extends State<GetGeneratorAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController qrController;
  TextEditingController generatorUUID = new TextEditingController();
  QRData qrData;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: _buildView(),
  );

  Form _buildView(){
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: generatorUUID,
            decoration: const InputDecoration(
              hintText: 'Generator UUID',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter the UUID';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ListBLEDevices(title: "NetClave", generatorUUID: generatorUUID.text, qrData: qrData)
                ));

                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState.validate()) {
                  // Process data.
                }
              },
              child: Text('Scan'),
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
    );

  }

  void _onQRViewCreated(QRViewController controller) {
    this.qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      QRData scannedData =  new QRData(json.decode(scanData));
      setState(() {
        generatorUUID.text = scannedData.deviceAddress;
        qrData = scannedData;
      });
    });
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

}
