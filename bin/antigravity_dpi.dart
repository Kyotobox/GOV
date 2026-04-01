import 'package:antigravity_dpi/src/kernel/gov.dart' as kernel;

/// Entry point wrapper for the Antigravity DPI Governance Motor.
/// Delegates all logic to the kernel library to ensure SSoT.
void main(List<String> args) async {
  await kernel.main(args);
}
