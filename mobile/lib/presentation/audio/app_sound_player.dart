import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Bunyi pendek layar kamera: tick countdown 3-2-1 dan rana saat foto diambil.
///
/// Interface dipisah dari implementasi supaya layar bisa memakai player palsu
/// saat test — pola sama seperti `MlPredictor` di `data/services/ml`.
abstract interface class AppSoundPlayer {
  /// Memuat aset dan menyiapkan audio context. Cukup sekali, di `initState`.
  Future<void> prepare();

  /// Bunyi "tik" untuk tiap angka countdown (3, 2, 1).
  Future<void> playTick();

  /// Bunyi rana kamera saat foto diambil.
  Future<void> playShutter();

  Future<void> dispose();
}

/// Implementasi aset MP3 di `assets/audio/`.
///
/// Tick dipanggil per detik (bukan satu file berisi 3 dentuman) supaya
/// countdown yang dibatalkan di tengah langsung diam tanpa sisa bunyi.
///
/// Semua method menelan galat: audio yang gagal dimuat tidak boleh
/// menggagalkan pengambilan foto.
class AssetSoundPlayer implements AppSoundPlayer {
  /// Tanpa prefix `assets/`: `AudioCache.prefix` bawaan sudah `assets/`.
  static const tickAsset = 'audio/countdown_tick.mp3';
  static const shutterAsset = 'audio/shutter.mp3';

  final AudioPlayer _tick = AudioPlayer(playerId: 'countdown_tick');
  final AudioPlayer _shutter = AudioPlayer(playerId: 'shutter');

  bool _prepared = false;
  bool _disposed = false;

  /// Android: `gainTransientMayDuck` supaya TTS panduan sudut hanya mengecil
  /// sesaat, bukan berhenti. iOS: `playback` agar suara tetap terdengar walau
  /// tombol silent aktif, ditambah `mixWithOthers` agar audio lain tidak putus.
  ///
  /// Catatan: `defaultToSpeaker` sengaja tidak dipakai — package ini hanya
  /// mengizinkannya untuk kategori `playAndRecord` (lihat assert di
  /// `AudioContextIOS`).
  static final _audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  @override
  Future<void> prepare() async {
    if (_prepared || _disposed) return;
    _prepared = true;
    try {
      await _load(_tick, tickAsset);
      await _load(_shutter, shutterAsset);
    } on Object catch (error) {
      _warn('prepare', error);
    }
  }

  @override
  Future<void> playTick() => _replay(_tick, 'playTick');

  @override
  Future<void> playShutter() => _replay(_shutter, 'playShutter');

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _tick.dispose();
      await _shutter.dispose();
    } on Object catch (error) {
      _warn('dispose', error);
    }
  }

  Future<void> _load(AudioPlayer player, String asset) async {
    await player.setAudioContext(_audioContext);
    // lowLatency = SoundPool di Android, jauh lebih responsif untuk file pendek.
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
  }

  /// `stop()` mereset posisi ke awal, jadi `resume()` selalu memutar dari 0 —
  /// penting agar tick beruntun tiap detik tidak terpotong di tengah.
  Future<void> _replay(AudioPlayer player, String label) async {
    if (!_prepared || _disposed) return;
    try {
      await player.stop();
      await player.resume();
    } on Object catch (error) {
      _warn(label, error);
    }
  }

  void _warn(String label, Object error) {
    debugPrint('AppSoundPlayer.$label gagal: $error');
  }
}
