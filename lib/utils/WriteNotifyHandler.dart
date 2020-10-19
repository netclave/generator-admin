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

import 'dart:math';

import 'package:nc_client/utils/EncryptionHandler.dart';
import 'package:protobuf/protobuf.dart';
import '../apis/generator/dart/api.pb.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:typed_data';

class WriteNotifyHandler {
  static Map<Guid, BluetoothCharacteristic> registeredHandlers = Map<Guid, BluetoothCharacteristic>();
  static Map<Guid, Set<Function>> callbacks = new Map<Guid, Set<Function>>();
  static bool useEncryption = false;
  static EncryptionHandler encryptionHandler;

  static void enableEncryption(EncryptionHandler encryptionHandler) {
    WriteNotifyHandler.encryptionHandler = encryptionHandler;
    WriteNotifyHandler.useEncryption = true;
  }

  static void disableEncryption() {
    WriteNotifyHandler.useEncryption = false;
  }

  static addCallback(Guid characteristicUuid, Function callback) {
    print('add calback' + callback.toString() + " to " + characteristicUuid.toString());
    if (!WriteNotifyHandler.callbacks.containsKey(characteristicUuid)) {
      WriteNotifyHandler.callbacks[characteristicUuid] = Set<Function>();
    }
    WriteNotifyHandler.callbacks[characteristicUuid].add(callback);
  }

  static removeCallback(Guid characteristicUuid, Function callback){
    print('remove calback' + callback.toString() + " from " + characteristicUuid.toString());
    if (WriteNotifyHandler.callbacks.containsKey(characteristicUuid)) {
      WriteNotifyHandler.callbacks[characteristicUuid].remove(callback);
    }
  }

  static removeHandlers() {
    for (Guid bcGuid in WriteNotifyHandler.registeredHandlers.keys) {
      WriteNotifyHandler.registeredHandlers[bcGuid].setNotifyValue(false);
      WriteNotifyHandler.registeredHandlers = Map<Guid, BluetoothCharacteristic>();
    }

  }

  static removeCallbacks() {
    WriteNotifyHandler.callbacks = new Map<Guid, Set<Function>>();
  }

  static teardown() {
    WriteNotifyHandler.removeHandlers();
    WriteNotifyHandler.removeCallbacks();
    WriteNotifyHandler.disableEncryption();
  }

  static GeneratedMessage deserialize(GeneratedMessage response,
      List<int> rawResponse) {
    switch (response.runtimeType) {
      case AddIdentityProviderResponse:
        return new AddIdentityProviderResponse.fromBuffer(rawResponse);
      case ListIdentityProvidersResponse:
        return new ListIdentityProvidersResponse.fromBuffer(rawResponse);
      case ConfirmIdentityProviderResponse:
        return new ConfirmIdentityProviderResponse.fromBuffer(rawResponse);
      case RegisterDeviceResponse:
        return new RegisterDeviceResponse.fromBuffer(rawResponse);
      case ListNonRegisteredDevicesResponse:
        return new ListNonRegisteredDevicesResponse.fromBuffer(rawResponse);
      case AddWalletResponse:
        return new AddWalletResponse.fromBuffer(rawResponse);
      case ListWalletsResponse:
        return new ListWalletsResponse.fromBuffer(rawResponse);
      case ApproveWalletSharingRequestResponse:
        return new ApproveWalletSharingRequestResponse.fromBuffer(rawResponse);
      case DeleteWalletSharingRequestResponse:
        return new DeleteWalletSharingRequestResponse.fromBuffer(rawResponse);
      case GetWalletSharingRequestsResponse:
        return new GetWalletSharingRequestsResponse.fromBuffer(rawResponse);
      case GetBluetoothEndpointsDescriptorsResponse:
        return new GetBluetoothEndpointsDescriptorsResponse.fromBuffer(rawResponse);
      default:
        return null;
    }
  }


  static Future<void> writeAndNotify(BluetoothCharacteristic writeEndpoint,
      BluetoothCharacteristic notifyEndpoint,
      GeneratedMessage requestMessage, GeneratedMessage responseMessageType, Function callback) async {
    int handlerId = new Random().nextInt(100);

    WriteNotifyHandler.addCallback(notifyEndpoint.uuid, callback);

    if (!WriteNotifyHandler.registeredHandlers.containsKey(notifyEndpoint.uuid)) {
      List<int> message = [];
      bool buffering = false;
      GeneratedMessage response;
      notifyEndpoint.value.listen((value) async {
        print('handler ' + handlerId.toString() + ' value:' + value.toString());

        if (value.length == 5 && String.fromCharCodes(value) == "START") {
          print('START');
          message = [];
          buffering = true;
          return;
        }
        if (buffering) {
          if (value.length == 4 && String.fromCharCodes(value) == "STOP") {
            print('STOP');
            buffering = false;

            if (WriteNotifyHandler.useEncryption) {
              message = await WriteNotifyHandler.encryptionHandler.decryptBytes(message);
            }

            response = deserialize(responseMessageType, message);
            message = [];

            if (WriteNotifyHandler.callbacks.containsKey(notifyEndpoint.uuid)) {
              for (Function cb in WriteNotifyHandler.callbacks[notifyEndpoint.uuid]) {
                print('handler ' + handlerId.toString() + ' calling callback ' + cb.toString());
                cb(response);
              }
            }

          } else {
            message.addAll(value);
          }
        }
      });

      WriteNotifyHandler.registeredHandlers[notifyEndpoint.uuid] = notifyEndpoint;
    }

    await write(writeEndpoint, requestMessage);
    await notifyEndpoint.setNotifyValue(true);
  }


  static write(BluetoothCharacteristic writeEndpoint, GeneratedMessage requestMessage, {int chunkSize = 20}) async {
    Uint8List bytes = requestMessage.writeToBuffer();

    if (WriteNotifyHandler.useEncryption) {
      bytes = await WriteNotifyHandler.encryptionHandler.encryptedBytes(bytes);
    }

    List<Uint8List> chunks = [];

    for (var i = 0; i < bytes.length; i += chunkSize) {
      chunks.add(bytes.sublist(i, i + chunkSize > bytes.length ? bytes.length : i + chunkSize));
    }

    await writeEndpoint.write(new Uint8List.fromList("START".codeUnits), withoutResponse: false);

    for (Uint8List chunk in chunks) {
      await writeEndpoint.write(chunk, withoutResponse: false);
    }
    await writeEndpoint.write(new Uint8List.fromList("STOP".codeUnits), withoutResponse: false);
  }
}

