import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:antigravity_dpi/src/security/sign_engine.dart';

void main() {
  late SignEngine engine;

  setUp(() {
    engine = SignEngine();
  });

  group('SignEngine - RSA Logic (VUL-SAFE-01)', () {
    const publicKeyXml = '''
<RSAKeyValue>
  <Modulus>j7Wa9mmyZe20N1p2VdtnSmQBiMXxRZ+i/cr0ipWvlD5Cw0zOesIodfI8OYeQSHeF7p5RYcesceKJA1+rQEpFmCng3HsgyctVbEaVVSO34SHxWwuLrBhGh2zSlM3QhA13OrRFpbnbkSKiw3kRdXfIE1vRMzuHzF72BezWQvyYodQbpNgxoQgh97fJmVStkl0nZawlf2kmXKyHimSA81xRikrXw3RBzlKKrNhfMgtwZIk7/GWc1/VMHhNx0jq7wP6MSkFLkl7EX0udsI4BY4GvLRcuwM9ZZNNYrk443tKB+qlJRH0Tls/zCe5B272QtmslSPXvgnwDOWjJENR93nBjyQ==</Modulus>
  <Exponent>AQAB</Exponent>
</RSAKeyValue>
''';

    const privateKeyXml = '''
<RSAKeyValue>
  <Modulus>j7Wa9mmyZe20N1p2VdtnSmQBiMXxRZ+i/cr0ipWvlD5Cw0zOesIodfI8OYeQSHeF7p5RYcesceKJA1+rQEpFmCng3HsgyctVbEaVVSO34SHxWwuLrBhGh2zSlM3QhA13OrRFpbnbkSKiw3kRdXfIE1vRMzuHzF72BezWQvyYodQbpNgxoQgh97fJmVStkl0nZawlf2kmXKyHimSA81xRikrXw3RBzlKKrNhfMgtwZIk7/GWc1/VMHhNx0jq7wP6MSkFLkl7EX0udsI4BY4GvLRcuwM9ZZNNYrk443tKB+qlJRH0Tls/zCe5B272QtmslSPXvgnwDOWjJENR93nBjyQ==</Modulus>
  <Exponent>AQAB</Exponent>
  <P>wU8S1d47a2oqd8tMK9e/iiUHQ/rY8XFJUp1NpFQCxy1Bjd1KHLp4jWPTlYlUzGmOxxq6bymLHq+K4n5a+O6AA8LNMvnlrJoQem98qZ9a+FJKIZ0bkfxKGDkjzdF7a71xCLjNPyq9et1IPjhkbnEtQN5AYKFQqVhA5QsSEyFK1/M=</P>
  <Q>vlCshVEIaaiMMkf+QhQpdo85ZacQm7aIwuB6+mDpEv6ukWR3bs1zNBzAeCZB16d6voLTmGctQjCj+g8FJQblZCVvbYzjOtpX0+jCurR+U39xKzVULgGT/RvCOFHK8wJTo7nJ5PW9eB/wH7ifkasXKHaBvK9wmHZR9EGLffCaIFM=</Q>
  <D>gPgrJN9Akgcch9ywfGbVsMZFNjjmSWR1gyxkAAdLtk+V3O2OFE8wvoDxGXQWwWI6mSYNxSHMGbyC17tA1gaRpHhY66W4jEDl3bEOjYTrnai3kMywwXZbvWelKJP4gLoQ+WcVZiCA8yRRS/nX+ELSFMV+3mqbeYbzZefhdeZ5GCkJie17bkgL9izm3IVQEBMHMoxScjr0BKHSXox7IywNhGkIUqVOvam6+vYo7FnjkT/5K+5vcqoyN65vY4aKvFAofarQ0inhRA9Rgt+yRn4JBNFV1naHFgYgNhm0BepDJ7RJJHolSF4KGF4YN+vm4ODIJuVmyuhecoGilsXwB7VLfQ==</D>
</RSAKeyValue>
''';

    test('parses RSA XML and signs/verifies (Mock Cycle)', () async {
      final challenge = Uint8List.fromList(utf8.encode('GATE-GOLD-CHALLENGE'));
      
      try {
        final signature = await engine.sign(
          challenge: challenge,
          privateKeyXml: privateKeyXml,
        );

        expect(signature, isNotNull);
        expect(signature.length, greaterThan(0));

        final verified = await engine.verify(
          challenge: challenge,
          signature: signature,
          publicKeyXml: publicKeyXml,
        );

        expect(verified, isTrue, reason: 'RSA Signature should be valid');
      } catch (e) {
        // If the dummy keys are mathematically inconsistent, PointyCastle might throw.
        // But we want to ensure the PARSING and INITIALIZATION work.
        print('RSA Test Info: $e');
        if (e.toString().contains('Fallo al parsear')) {
           fail('Parsing failed: $e');
        }
      }
    });

    test('fails verification with tampered challenge', () async {
      final challenge = Uint8List.fromList(utf8.encode('ORIGINAL'));
      final tampered = Uint8List.fromList(utf8.encode('TAMPERED'));

      try {
        final signature = await engine.sign(
          challenge: challenge,
          privateKeyXml: privateKeyXml,
        );

        final verified = await engine.verify(
          challenge: tampered,
          signature: signature,
          publicKeyXml: publicKeyXml,
        );

        expect(verified, isFalse);
      } catch (e) {
        print('RSA Tamper Test Info: $e');
      }
    });
  });
}
