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
import 'package:nc_client/pages/Wallet/AddWallet.dart';
import 'package:nc_client/utils/WriteNotifyHandler.dart';
import 'package:protobuf/protobuf.dart';

class WalletsPage extends StatefulWidget{
  WalletsPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic}) : super(key: key);

  final String title;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;

  @override
  _WalletsPageState createState() => _WalletsPageState();

}


class _WalletsPageState extends State<WalletsPage> {
  ListWalletsResponse listWalletsResponse;

  @override
  void dispose(){
    WriteNotifyHandler.removeCallback(Guid(widget.endpoints.endpoints['listWalletsNotifyHandlerUUID']), this.updateState);
    super.dispose();
  }

  void updateState(GeneratedMessage message) {
    setState(() {
      listWalletsResponse = message;
    });
  }


  @override
  void initState() {
    WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['listWalletsWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['listWalletsNotifyHandlerUUID']], new ListWalletsRequest(), ListWalletsResponse(), this.updateState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (listWalletsResponse == null) {
      WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listWalletsWriteHandlerUUID']], new ListWalletsRequest());
      return Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          child: _buildWalletsList(),
      ),
      floatingActionButton:  FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => AddWalletPage(endpoints: widget.endpoints, uuidToCharacteristic: widget.uuidToCharacteristic, title: 'Add Wallet')
          )
          );
        },
        child: Icon(Icons.add),
      )
    );


  }


  ListView _buildWalletsList() {
    List<Container> containers = new List<Container>();
    for (String wallet in listWalletsResponse.wallets) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(wallet),
                  ],
                ),
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

