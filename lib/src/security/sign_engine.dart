import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:path/path.dart' as p;

/// SignEngine: Native RSA signing and verification (replaces sign_challenge.ps1).
/// Supports .NET RSA XML key format.
class SignEngine {
  /// Signs a challenge using a private key from an XML file.
  Future<String> sign({
    required String challenge,
    required String files,
    required String privateKeyXmlPath,
  }) async {
    final xml = await File(privateKeyXmlPath).readAsString();
    final privateKey = _parsePrivateKeyXml(xml);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201'); // OID for SHA-256
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final contextString = '$challenge:$files';
    final data = utf8.encode(contextString);
    final signature = signer.generateSignature(Uint8List.fromList(data));

    return base64Encode(signature.bytes);
  }

  /// Verifies a signature using a public key from an XML file.
  Future<bool> verify({
    required String challenge,
    required String files,
    required String signatureBase64,
    required String publicKeyXmlPath,
  }) async {
    final xml = await File(publicKeyXmlPath).readAsString();
    final publicKey = _parsePublicKeyXml(xml);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    final contextString = '$challenge:$files';
    final data = utf8.encode(contextString);
    final signatureBytes = base64Decode(signatureBase64);

    try {
      return signer.verifySignature(
        Uint8List.fromList(data),
        RSASignature(Uint8List.fromList(signatureBytes)),
      );
    } catch (_) {
      return false;
    }
  }

  RSAPrivateKey _parsePrivateKeyXml(String xml) {
    BigInt modulus = _getXmlBigInt(xml, 'Modulus');
    BigInt exponent = _getXmlBigInt(xml, 'Exponent');
    BigInt p = _getXmlBigInt(xml, 'P');
    BigInt q = _getXmlBigInt(xml, 'Q');
    BigInt d = _getXmlBigInt(xml, 'D');

    return RSAPrivateKey(modulus, d, p, q);
  }

  RSAPublicKey _parsePublicKeyXml(String xml) {
    BigInt modulus = _getXmlBigInt(xml, 'Modulus');
    BigInt exponent = _getXmlBigInt(xml, 'Exponent');

    return RSAPublicKey(modulus, exponent);
  }

  BigInt _getXmlBigInt(String xml, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(xml);
    if (match == null) throw Exception('RSA XML missing tag: $tag');
    final b64 = match.group(1)!.trim();
    final bytes = base64Decode(b64);
    return _decodeBigInt(bytes);
  }

  BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int byte in bytes) {
      result = (result << 8) | BigInt.from(byte & 0xff);
    }
    return result;
  }
}
