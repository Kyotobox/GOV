import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:pointycastle/export.dart';

/// SignEngine: Manages RSA signing and verification for governance events.
/// (S12-01: Hardened with package:xml for VUL-01 and PointyCastle for RSA)
class SignEngine {
  /// Signs a challenge using a private key (XML format).
  Future<Uint8List> sign({
    required Uint8List challenge,
    required String privateKeyXml,
  }) async {
    final params = _parseRsaXml(privateKeyXml);
    final n = _bytesToBigInt(params['Modulus']!);
    final d = _bytesToBigInt(params['D']!);
    
    final pBytes = params['P'];
    final p = pBytes != null ? _bytesToBigInt(pBytes) : null;
    
    final qBytes = params['Q'];
    final q = qBytes != null ? _bytesToBigInt(qBytes) : null;

    final privateKey = RSAPrivateKey(n, d, p, q);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201'); // OID for SHA-256
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signature = signer.generateSignature(challenge);
    
    // VUL-03: Zero out ALL sensitive buffers after use
    params.values.forEach(_zeroOut);
    
    return signature.bytes;
  }

  /// Verifies a signature against a challenge using a public key (XML format).
  Future<bool> verify({
    required Uint8List challenge,
    required Uint8List signature,
    required String publicKeyXml,
  }) async {
    try {
      final params = _parseRsaXml(publicKeyXml);
      final n = _bytesToBigInt(params['Modulus']!);
      final e = _bytesToBigInt(params['Exponent']!);

      final publicKey = RSAPublicKey(n, e);
      final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      try {
        final isValid = verifier.verifySignature(challenge, RSASignature(signature));
        // VUL-03: Clean up public params too (good hygiene)
        params.values.forEach(_zeroOut);
        return isValid;
      } catch (e) {
        // VUL-04: Specific handling for verification failure vs system error
        stderr.writeln('[DEBUG] SignEngine.verify: Signature check rejected ($e)');
        return false;
      }
    } catch (e) {
      // VUL-04: Critical error during parsing or engine init
      stderr.writeln('[ERROR] SignEngine.verify: Critical failure in verification pipeline.');
      stderr.writeln('  Detail: $e');
      rethrow;
    }
  }

  /// Converts Uint8List to BigInt (unsigned).
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Robust RSA XML Parser using package:xml (VUL-01).
  Map<String, Uint8List> _parseRsaXml(String xmlData) {
    final Map<String, Uint8List> params = {};
    try {
      final document = XmlDocument.parse(xmlData);
      final root = document.rootElement;
      
      for (final node in root.children) {
        if (node is XmlElement) {
          final name = node.name.local;
          final value = node.innerText.trim()
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll(' ', '');
          params[name] = base64Decode(value);
        }
      }
    } catch (e) {
      throw Exception('Fallo al parsear clave RSA XML: Formato inválido o corrupto ($e)');
    }
    
    // Ensure critical components exist
    if (!params.containsKey('Modulus')) throw Exception('Clave RSA inválida: Falta Modulus');
    
    // S19-FORTRESS: Enforce 2048-bit minimum bit-depth (VUL-PRO-01)
    final modulus = params['Modulus']!;
    if (modulus.length < 256) {
      throw Exception('DEBILIDAD DETECTADA: La clave RSA es inferior a 2048 bits (${modulus.length * 8} bits). El sistema requiere grado de seguridad FORTRESS.');
    }

    return params;
  }

  /// Cleanly zeroes out memory for sensitive data (VUL-03).
  void _zeroOut(Uint8List buffer) {
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = 0;
    }
  }
}
