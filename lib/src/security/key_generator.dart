import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'dart:math';

/// KeyGenerator: Generates RSA 2048-bit keys in XML format for Antigravity DPI.
class KeyGenerator {
  /// Generates a new 2048-bit RSA key pair.
  Map<String, String> generate2048() {
    final rsapars = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12);
    final params = ParametersWithRandom(rsapars, _getSecureRandom());
    final keyGen = RSAKeyGenerator();
    keyGen.init(params);

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey;
    final privateKey = pair.privateKey;

    final publicXml = '''
<RSAKeyValue>
  <Modulus>${base64Encode(_bigIntToBytes(publicKey.modulus!))}</Modulus>
  <Exponent>${base64Encode(_bigIntToBytes(publicKey.exponent!))}</Exponent>
</RSAKeyValue>''';

    final privateXml = '''
<RSAKeyValue>
  <Modulus>${base64Encode(_bigIntToBytes(privateKey.modulus!))}</Modulus>
  <Exponent>${base64Encode(_bigIntToBytes(publicKey.exponent!))}</Exponent>
  <P>${base64Encode(_bigIntToBytes(privateKey.p!))}</P>
  <Q>${base64Encode(_bigIntToBytes(privateKey.q!))}</Q>
  <D>${base64Encode(_bigIntToBytes(privateKey.privateExponent!))}</D>
</RSAKeyValue>''';

    return {
      'public': publicXml,
      'private': privateXml,
    };
  }

  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (i) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Uint8List _bigIntToBytes(BigInt number) {
    var b256 = BigInt.from(256);
    var result = <int>[];
    while (number > BigInt.zero) {
      result.add(number.remainder(b256).toInt());
      number = number ~/ b256;
    }
    return Uint8List.fromList(result.reversed.toList());
  }
}
