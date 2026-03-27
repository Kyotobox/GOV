import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
  final pubFile = File(p.join(basePath, 'vault', 'po_public.xml'));

  final sigData = jsonDecode(await sigFile.readAsString());
  final challenge = sigData['challenge'] as String;
  final signatureBase64 = sigData['signature'] as String;
  final publicKeyXml = await pubFile.readAsString();

  final signature = base64Decode(signatureBase64.trim());
  final challengeBytes = Uint8List.fromList(utf8.encode(challenge));

  final document = XmlDocument.parse(publicKeyXml);
  final root = document.rootElement;
  final nStr = root.findElements('Modulus').first.innerText;
  final eStr = root.findElements('Exponent').first.innerText;

  final n = _bytesToBigInt(base64Decode(nStr.trim().replaceAll('\n', '').replaceAll(' ', '')));
  final e = _bytesToBigInt(base64Decode(eStr.trim().replaceAll('\n', '').replaceAll(' ', '')));

  final publicKey = RSAPublicKey(n, e);
  final rsa = RSAEngine();
  rsa.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
  
  try {
    final decrypted = rsa.process(signature);
    final hexStr = hex(decrypted);
    print('TAIL_HEX_DPI_GOLD:');
    final tail = hexStr.substring(hexStr.length - 120);
    print(tail.substring(0, 40));
    print(tail.substring(40, 80));
    print(tail.substring(80));
    
    final sha256 = SHA256Digest().process(challengeBytes);
    print('SHA256_TARGET: ${hex(sha256)}');
  } catch (e) {
    print('ERROR: $e');
  }
}

String hex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

BigInt _bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}
