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
    final file = File(privateKeyXmlPath);
    if (!await file.exists()) throw Exception('Private key not found at $privateKeyXmlPath');
    
    final xml = await file.readAsString();
    final privateKey = _parsePrivateKeyXml(xml);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201'); // OID for SHA-256
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final contextString = '$challenge:$files';
    final data = Uint8List.fromList(utf8.encode(contextString));
    
    try {
      final signature = signer.generateSignature(data);
      return base64Encode(signature.bytes);
    } finally {
      _zeroOut(data);
    }
  }

  /// Verifies a signature using a public key from an XML file.
  Future<bool> verify({
    required String challenge,
    required String files,
    required String signatureBase64,
    required String publicKeyXmlPath,
  }) async {
    final file = File(publicKeyXmlPath);
    if (!await file.exists()) return false;

    final xml = await file.readAsString();
    final publicKey = _parsePublicKeyXml(xml);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    final contextString = '$challenge:$files';
    final data = Uint8List.fromList(utf8.encode(contextString));
    final signatureBytes = Uint8List.fromList(base64Decode(signatureBase64));

    try {
      final isValid = signer.verifySignature(
        data,
        RSASignature(signatureBytes),
      );
      return isValid;
    } on ArgumentError catch (e) {
      print('[SIGN-ENGINE] Error de formato en firma: $e');
      return false;
    } catch (e) {
      print('[SIGN-ENGINE] Error inesperado en verificación: $e');
      rethrow;
    } finally {
      _zeroOut(data);
      _zeroOut(signatureBytes);
    }
  }

  void _zeroOut(Uint8List? list) {
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        list[i] = 0;
      }
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
    // Mejora de robustez: Soporte multi-línea y espacios
    final match = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml);
    if (match == null) throw Exception('RSA XML missing tag: $tag');
    final b64 = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
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
