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

import 'AddIdentityProvider.dart';
import 'ConfirmIdentityProvider.dart';

class IdentityProvidersPage extends StatefulWidget{
  IdentityProvidersPage({Key key, this.title, this.endpoints, this.uuidToCharacteristic}) : super(key: key);

  final String title;
  final GetBluetoothEndpointsDescriptorsResponse endpoints;
  final Map<String, BluetoothCharacteristic> uuidToCharacteristic;

  @override
  _IdentityProvidersPageState createState() => _IdentityProvidersPageState();

}


class _IdentityProvidersPageState extends State<IdentityProvidersPage> {
  ListIdentityProvidersResponse response;
  Map<String, ConfirmIdentityProviderRequest> unconfirmedIdps = Map<String, ConfirmIdentityProviderRequest>();

  @override
  void dispose(){
    WriteNotifyHandler.removeCallback(Guid(widget.endpoints.endpoints['listIdentityProvidersNotifyHandlerUUID']), this.updateState);
    WriteNotifyHandler.removeCallback(Guid(widget.endpoints.endpoints['addIdentityProviderNotifyHandlerUUID']), this.updateUnconfirmedIdps);
    super.dispose();
  }

  void updateState(GeneratedMessage message) {
    setState(() {
      response = message;
      for (IdentityProvider idp in response.identityProviders) {
        if (unconfirmedIdps.containsKey(idp.id)) {
          unconfirmedIdps.remove(idp.id);
        }
      }
    });
  }

  void updateUnconfirmedIdps(GeneratedMessage message) {
    setState((){
      AddIdentityProviderResponse response = message;
      ConfirmIdentityProviderRequest confirmIdpRequest = new ConfirmIdentityProviderRequest();
      confirmIdpRequest.identityProviderId = response.identityProviderId;
      confirmIdpRequest.identityProviderUrl = response.identityProviderUrl;
      unconfirmedIdps[response.identityProviderId] = confirmIdpRequest;
    });
  }

  @override
  void initState() {
    WriteNotifyHandler.writeAndNotify(widget.uuidToCharacteristic[widget.endpoints.endpoints['listIdentityProvidersWriteHandlerUUID']], widget.uuidToCharacteristic[widget.endpoints.endpoints['listIdentityProvidersNotifyHandlerUUID']], new ListIdentityProvidersRequest(), ListIdentityProvidersResponse(), this.updateState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('build idp page');
    if (response == null) {
      WriteNotifyHandler.write(widget.uuidToCharacteristic[widget.endpoints.endpoints['listIdentityProvidersWriteHandlerUUID']], new ListIdentityProvidersRequest());
      return Scaffold(
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          child: Column (
            children: <Widget>[
              Expanded(
                child: _buildListViewOfIdp(),
              ),
              Expanded(
                child: _buildListViewOfUnconfirmedIdp(),
              ),
            ],
          )
      ),
      floatingActionButton:  FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => AddIdentityProviderPage(endpoints: widget.endpoints, uuidToCharacteristic: widget.uuidToCharacteristic, title: 'Add Identity Provider', unconfirmedIdps: unconfirmedIdps, addToUnconfirmedIdpsCallback: this.updateUnconfirmedIdps)
          )
          );
        },
        child: Icon(Icons.add),
      ),

    );
  }

  ListView _buildListViewOfIdp() {
    print('build idp view');
    List<Container> containers = new List<Container>();
    for (IdentityProvider idp in response.identityProviders) {
      print('current idp ' + idp.toString());
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(idp.id),
                    Text(idp.url),
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

  ListView _buildListViewOfUnconfirmedIdp() {
    print('build idp view');
    List<Container> containers = new List<Container>();
    for (ConfirmIdentityProviderRequest confirmIdpRequest in unconfirmedIdps.values) {
      print('current idp ' + confirmIdpRequest.toString());
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(confirmIdpRequest.identityProviderId),
                    Text(confirmIdpRequest.identityProviderUrl),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: ()  {
                  Navigator.push(context, MaterialPageRoute(

                      builder: (context) => ConfirmIdentityProviderPage(confirmIdpRequest: confirmIdpRequest, title: "NetClave", uuidToCharacteristic: widget.uuidToCharacteristic, endpoints: widget.endpoints)
                  ));
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

