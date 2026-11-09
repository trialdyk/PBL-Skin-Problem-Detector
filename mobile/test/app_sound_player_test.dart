import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/presentation/audio/app_sound_player.dart';

/// Player palsu: membuktikan interface cukup kecil untuk di-fake di test layar
/// kamera tanpa menyentuh plugin audio.
class _FakeSoundPlayer implements AppSoundPlayer {
  int tickCount = 0;
  int shutterCount = 0;
  bool prepared = false;
  bool disposed = false;

  @override
  Future<void> prepare() async => prepared = true;

  @override
  Future<void> playTick() async => tickCount++;

  @override
  Future<void> playShutter() async => shutterCount++;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Tanpa plugin asli, method channel audioplayers akan melempar
    // MissingPluginException di konstruktor AudioPlayer. Balas sukses saja
    // supaya test fokus ke perilaku AssetSoundPlayer.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  test('aset audio terdaftar di pubspec dan bisa dimuat', () async {
    // AssetSource memakai prefix 'assets/' bawaan AudioCache.
    final tick = await rootBundle.load('assets/${AssetSoundPlayer.tickAsset}');
    final shutter = await rootBundle.load(
      'assets/${AssetSoundPlayer.shutterAsset}',
    );

    expect(tick.lengthInBytes, greaterThan(0));
    expect(shutter.lengthInBytes, greaterThan(0));
  });

  test('path aset memakai format AudioCache (tanpa prefix assets/)', () {
    expect(AssetSoundPlayer.tickAsset, 'audio/countdown_tick.mp3');
    expect(AssetSoundPlayer.shutterAsset, 'audio/shutter.mp3');
  });

  test('playTick sebelum prepare tidak melempar galat', () async {
    final player = AssetSoundPlayer();
    addTearDown(player.dispose);

    await expectLater(player.playTick(), completes);
    await expectLater(player.playShutter(), completes);
  });

  test('prepare lalu playTick berulang tidak melempar galat', () async {
    final player = AssetSoundPlayer();
    addTearDown(player.dispose);

    await expectLater(player.prepare(), completes);

    // Countdown 3-2-1: tiga tick beruntun tiap detik.
    for (var i = 0; i < 3; i++) {
      await expectLater(player.playTick(), completes);
    }
    await expectLater(player.playShutter(), completes);
  });

  test('dispose aman dipanggil dua kali', () async {
    final player = AssetSoundPlayer();

    await expectLater(player.dispose(), completes);
    await expectLater(player.dispose(), completes);
  });

  test('kontrak layar kamera: 3 tick lalu 1 shutter', () async {
    final player = _FakeSoundPlayer();
    await player.prepare();

    for (var i = 0; i < 3; i++) {
      await player.playTick();
    }
    await player.playShutter();
    await player.dispose();

    expect(player.prepared, isTrue);
    expect(player.tickCount, 3);
    expect(player.shutterCount, 1);
    expect(player.disposed, isTrue);
  });
}
