// 小 wrapper：將你的 `AccountingAPP.dart` 作為實際的 entry point
import 'AccountingAPP.dart' as app;

Future<void> main() async {
  // 呼叫你的 AccountingAPP 裡的 main
  await app.main();
}
