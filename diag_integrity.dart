import 'package:antigravity_dpi/src/security/integrity_engine.dart';

void main() async {
  final integrity = IntegrityEngine();
  final results = await integrity.verifyAll(basePath: 'c:\\Users\\Ruben\\Documents\\Base2');
  
  results.forEach((file, ok) {
    print('FILE: $file | OK: $ok');
  });
}
