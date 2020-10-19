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

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:nc_client/apis/generator/dart/api.pb.dart';
import 'package:nc_client/utils/WriteNotifyHandler.dart';
import 'package:protobuf/protobuf.dart';

class DevicesPage extends StatefulWidget{
  DevicesPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic}) : super(key: key);

  final String title;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;

  @override
  _DevicesPageState createState() => _DevicesPageState();

}


class _DevicesPageState extends State<DevicesPage> {
  ListNonRegisteredDevicesResponse nonRegisteredDevices;

  @override
  void dispose(){
    WriteNotifyHandler.removeCallback(Guid(widget.endpoints.endpoints['listNonRegisteredDevicesNotifyHandlerUUID']), this.updateState);
    super.dispose();
  }

  void updateState(GeneratedMessage message) {
    setState(() {
      nonRegisteredDevices = message;
    });
  }


  @override
  void initState() {
    WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['listNonRegisteredDevicesWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['listNonRegisteredDevicesNotifyHandlerUUID']], new ListNonRegisteredDevicesRequest(), ListNonRegisteredDevicesResponse(), this.updateState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (nonRegisteredDevices == null) {
      WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listNonRegisteredDevicesWriteHandlerUUID']], new ListNonRegisteredDevicesRequest());
      return Scaffold(
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: _buildDevicesList(),
      ),
    );

  }


  ListView _buildDevicesList() {
    List<Container> containers = new List<Container>();
    for (String device in nonRegisteredDevices.devices) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Register',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  RegisterDeviceRequest registerDeviceRequest = new RegisterDeviceRequest();
                  registerDeviceRequest.devID = device.split(" ")[0];
                  await WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['registerDeviceWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['registerDeviceNotifyHandlerUUID']], registerDeviceRequest, RegisterDeviceResponse(), (){});
                  await WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listNonRegisteredDevicesWriteHandlerUUID']], new ListNonRegisteredDevicesRequest());
                },
              ),
            ],
          ),
        ),
      );
    }


    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }


}

