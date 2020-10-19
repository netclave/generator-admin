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
import 'dart:typed_data';

import 'package:nc_client/apis/generator/dart/api.pb.dart';
import 'package:cryptography/cryptography.dart';
//import 'package:otp/otp.dart';

class EncryptionHandler {
  String otpToken;
  String aesSecret;

  EncryptionHandler(this.aesSecret, this.otpToken);

  Future<List<int>> decryptBytes(List<int> encryptedContainerBytes) async {
    const cipher = AesGcm();
    BluetoothEncryptionContainer bluetoothEncryptionContainer = BluetoothEncryptionContainer.fromBuffer(encryptedContainerBytes);

//    int timeMilliseconds = DateTime.now().millisecondsSinceEpoch;
//    String passcode = OTP.generateTOTPCodeString(otpToken, timeMilliseconds, length: 10, interval: 60, algorithm: Algorithm.SHA512);
//    final decrypted = await cipher.decrypt(base64Decode(bluetoothEncryptionContainer.ciphertext), secretKey: SecretKey((aesSecret + passcode).codeUnits), nonce: Nonce(base64Decode(bluetoothEncryptionContainer.iv)));

    final decrypted = await cipher.decrypt(base64Decode(bluetoothEncryptionContainer.ciphertext), secretKey: SecretKey((aesSecret).codeUnits), nonce: Nonce(base64Decode(bluetoothEncryptionContainer.iv)));

    return decrypted;
  }

  String formatSecret(String secret){
    return secret.padRight(8 - (secret.length % 8), '=').toUpperCase();
  }

  Future<List<int>> encryptedBytes(List<int> plainText) async {
    const Cipher cipher = AesGcm();
    Nonce nonce = Nonce.randomBytes(12);

//    int timeMilliseconds = DateTime.now().millisecondsSinceEpoch;
//    String passcode = OTP.generateTOTPCodeString(otpToken, timeMilliseconds, length: 10, interval: 60, algorithm: Algorithm.SHA512);
//    Uint8List encrypted = await cipher.encrypt(plainText, secretKey: SecretKey((aesSecret + passcode).codeUnits), nonce: nonce);

    Uint8List encrypted = await cipher.encrypt(plainText, secretKey: SecretKey((aesSecret).codeUnits), nonce: nonce);

    BluetoothEncryptionContainer bluetoothEncryptionContainer = new BluetoothEncryptionContainer();
    bluetoothEncryptionContainer.iv = base64Encode(nonce.bytes);
    bluetoothEncryptionContainer.ciphertext = base64Encode(encrypted);

    return bluetoothEncryptionContainer.writeToBuffer();
  }
}