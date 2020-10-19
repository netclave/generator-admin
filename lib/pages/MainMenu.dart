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
import 'package:nc_client/pages/Devices.dart';
import 'package:nc_client/pages/Wallet/Wallets.dart';
import 'package:nc_client/utils/EncryptionHandler.dart';
import 'package:nc_client/utils/WriteNotifyHandler.dart';
import 'package:protobuf/protobuf.dart';

import 'IdentityProvider/IdentityProviders.dart';


class MainMenuPage extends StatefulWidget{
  final List<BluetoothService> btServices;
  final BluetoothDevice connectedDevice;
  final String listEndpointsWriteUuid;
  final String listEndpointsNotifyUuid;
  final String serviceUuid;
  final String otpToken;
  final String aesSecret;


  MainMenuPage({Key key, this.title, this.btServices, this.connectedDevice, this.listEndpointsNotifyUuid, this.listEndpointsWriteUuid, this.serviceUuid, this.otpToken, this.aesSecret}) : super(key: key);
  final String title;

  @override
  _MainMenuPageState createState() => _MainMenuPageState();

}
class _MainMenuPageState extends State<MainMenuPage> {
  GetBluetoothEndpointsDescriptorsResponse endpoints;
  Map<String, BluetoothCharacteristic> uuidToCharacteristic;
  BluetoothService btService;

  @override
  void dispose() {
    WriteNotifyHandler.removeCallback(
        Guid(widget.listEndpointsNotifyUuid), this.updateState);
    widget.connectedDevice.disconnect();
    WriteNotifyHandler.teardown();
    super.dispose();
  }

  void updateState(GeneratedMessage message) {
    setState(() {
      endpoints = message;
    });
  }


  @override
  void initState() {
    for (BluetoothService service in widget.btServices) {
      if (service.uuid == Guid(widget.serviceUuid)) {
        btService = service;
      }
      //else - error
    }

    uuidToCharacteristic = new Map<
        String,
        BluetoothCharacteristic>();

    for (BluetoothCharacteristic bc in btService.characteristics) {
      uuidToCharacteristic[bc.uuid.toString()] = bc;
    }
    BluetoothCharacteristic listEndpointsWrite = uuidToCharacteristic[widget.listEndpointsWriteUuid];
    BluetoothCharacteristic listEndpointsNotify = uuidToCharacteristic[widget.listEndpointsNotifyUuid];

    WriteNotifyHandler.enableEncryption(EncryptionHandler(widget.aesSecret, widget.otpToken));
    WriteNotifyHandler.writeAndNotify(listEndpointsWrite, listEndpointsNotify,
        new GetBluetoothEndpointsDescriptorsRequest(),
        GetBluetoothEndpointsDescriptorsResponse(), this.updateState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (endpoints == null) {
      BluetoothCharacteristic listEndpointsWrite = uuidToCharacteristic[widget.listEndpointsWriteUuid];
      WriteNotifyHandler.write(
          listEndpointsWrite, new GetBluetoothEndpointsDescriptorsRequest());
      return Scaffold(
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            ListTile(
                title: Text('Identity Providers'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          IdentityProvidersPage(title: "Identity Providers",
                              endpoints: endpoints,
                              uuidToCharacteristic: uuidToCharacteristic)
                  ));
                }
            ),
            ListTile(
                title: Text('Devices'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          DevicesPage(title: "Devices",
                              endpoints: endpoints,
                              uuidToCharacteristic: uuidToCharacteristic)
                  ));
                }
            ),
            ListTile(
                title: Text('Wallets'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          WalletsPage(title: "Wallets",
                              endpoints: endpoints,
                              uuidToCharacteristic: uuidToCharacteristic)
                  ));
                }

            ),
          ],
        )
    );
  }
}


