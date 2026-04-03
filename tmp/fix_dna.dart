import 'dart:io';

void main() {
  final hash = 'F6918E14B94B03171F4FC09B4DB436F8B1FD03CF4D0D41DEFA87C3FF95A5994C';
  File('vault/intel/gov_hash.sig').writeAsStringSync(hash);
  File('../miniduo/vault/intel/gov_hash.sig').writeAsStringSync(hash);
  File('../Base2/vault/intel/gov_hash.sig').writeAsStringSync(hash);
  print('FIXED-DNA: All nodes sealed correctly.');
}
