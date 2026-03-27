import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final privKeyFile = File('C:\\Private Keys (IDE)\\private_key_gov.xml');
  
  if (!await privKeyFile.exists()) {
    print('Error: private key not found');
    return;
  }
  
  final rawXml = await privKeyFile.readAsString();
  final modulusMatch = RegExp(r'<Modulus>(.*?)</Modulus>', dotAll: true).firstMatch(rawXml);
  final exponentMatch = RegExp(r'<Exponent>(.*?)</Exponent>', dotAll: true).firstMatch(rawXml);
  
  if (modulusMatch == null || exponentMatch == null) {
    print('Error: Could not extract Modulus or Exponent from private key.');
    return;
  }
  
  final modulus = modulusMatch.group(1)!.trim();
  final exponent = exponentMatch.group(1)!.trim();
  
  final pubKeyFile = File(p.join(basePath, 'vault', 'po_public.xml'));
  final pubKeyXml = '''<RSAKeyValue>
  <Modulus>$modulus</Modulus>
  <Exponent>$exponent</Exponent>
</RSAKeyValue>''';

  await pubKeyFile.writeAsString(pubKeyXml);
  print('DONE: vault/po_public.xml synchronized with PRODUCTION KEY.');
}
