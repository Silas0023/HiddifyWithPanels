import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/gen/singbox_generated_bindings.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';
import 'package:hiddify/singbox/model/singbox_stats.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/model/warp_account.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:watcher/watcher.dart';

final _logger = Loggy('FFISingboxService');

// Isolate entry point for FFI operations
@pragma('vm:entry-point')
void _singboxIsolateEntry(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final box = _createSingboxLibrary();

  receivePort.listen((message) {
    if (message is Map<String, dynamic>) {
      final command = message['command'] as String;
      final data = message['data'];
      final responsePort = message['responsePort'] as SendPort;

      try {
        switch (command) {
          case 'setup':
            final baseDir = data['baseDir'] as String;
            final workingDir = data['workingDir'] as String;
            final tempDir = data['tempDir'] as String;
            final port = data['port'] as int;
            final debug = data['debug'] as int;

            box.setupOnce(NativeApi.initializeApiDLData);
            final err = box
                .setup(
                  baseDir.toNativeUtf8().cast(),
                  workingDir.toNativeUtf8().cast(),
                  tempDir.toNativeUtf8().cast(),
                  port,
                  debug,
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'error': err});
            break;

          case 'parse':
            final path = data['path'] as String;
            final tempPath = data['tempPath'] as String;
            final debug = data['debug'] as int;

            final err = box
                .parse(
                  path.toNativeUtf8().cast(),
                  tempPath.toNativeUtf8().cast(),
                  debug,
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'error': err});
            break;

          case 'changeHiddifyOptions':
            final json = data as String;
            final err = box.changeHiddifyOptions(json.toNativeUtf8().cast()).cast<Utf8>().toDartString();
            responsePort.send({'error': err});
            break;

          case 'generateConfig':
            final path = data as String;
            final response = box
                .generateConfig(path.toNativeUtf8().cast())
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'response': response});
            break;

          case 'start':
            final configPath = data['configPath'] as String;
            final disableMemoryLimit = data['disableMemoryLimit'] as int;

            final err = box
                .start(
                  configPath.toNativeUtf8().cast(),
                  disableMemoryLimit,
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'error': err});
            break;

          case 'stop':
            final err = box.stop().cast<Utf8>().toDartString();
            responsePort.send({'error': err});
            break;

          case 'restart':
            final configPath = data['configPath'] as String;
            final disableMemoryLimit = data['disableMemoryLimit'] as int;

            final err = box
                .restart(
                  configPath.toNativeUtf8().cast(),
                  disableMemoryLimit,
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'error': err});
            break;

          case 'selectOutbound':
            final groupTag = data['groupTag'] as String;
            final outboundTag = data['outboundTag'] as String;

            final err = box
                .selectOutbound(
                  groupTag.toNativeUtf8().cast(),
                  outboundTag.toNativeUtf8().cast(),
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'error': err});
            break;

          case 'urlTest':
            final groupTag = data as String;
            final err = box.urlTest(groupTag.toNativeUtf8().cast()).cast<Utf8>().toDartString();
            responsePort.send({'error': err});
            break;

          case 'startCommandClient':
            final type = data['type'] as int;
            final port = data['port'] as int;
            final err = box.startCommandClient(type, port).cast<Utf8>().toDartString();
            responsePort.send({'error': err});
            break;

          case 'stopCommandClient':
            final type = data as int;
            final err = box.stopCommandClient(type).cast<Utf8>().toDartString();
            responsePort.send({'error': err});
            break;

          case 'generateWarpConfig':
            final licenseKey = data['licenseKey'] as String;
            final previousAccountId = data['previousAccountId'] as String;
            final previousAccessToken = data['previousAccessToken'] as String;

            final response = box
                .generateWarpConfig(
                  licenseKey.toNativeUtf8().cast(),
                  previousAccountId.toNativeUtf8().cast(),
                  previousAccessToken.toNativeUtf8().cast(),
                )
                .cast<Utf8>()
                .toDartString();
            responsePort.send({'response': response});
            break;

          default:
            responsePort.send({'error': 'Unknown command: $command'});
        }
      } catch (e) {
        responsePort.send({'error': e.toString()});
      }
    }
  });
}

SingboxNativeLibrary _createSingboxLibrary() {
  String fullPath = "";
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    fullPath = "libcore";
  }
  if (Platform.isWindows) {
    fullPath = p.join(fullPath, "libcore.dll");
  } else if (Platform.isMacOS) {
    fullPath = p.join(fullPath, "libcore.dylib");
  } else {
    fullPath = p.join(fullPath, "libcore.so");
  }
  _logger.debug('singbox native libs path: "$fullPath"');
  final lib = DynamicLibrary.open(fullPath);
  return SingboxNativeLibrary(lib);
}

class FFISingboxService with InfraLogger implements SingboxService {
  static final SingboxNativeLibrary _box = _createSingboxLibrary();

  Isolate? _isolate;
  late final SendPort _isolateSendPort;
  final Completer<SendPort> _isolateReady = Completer<SendPort>();

  late final ValueStream<SingboxStatus> _status;
  late final ReceivePort _statusReceiver;
  Stream<SingboxStats>? _serviceStatsStream;
  Stream<List<SingboxOutboundGroup>>? _outboundsStream;

  // Helper method to send commands to isolate
  Future<Map<String, dynamic>> _sendCommand(String command, dynamic data) async {
    final responsePort = ReceivePort();
    final sendPort = await _isolateReady.future;

    sendPort.send({
      'command': command,
      'data': data,
      'responsePort': responsePort.sendPort,
    });

    final response = await responsePort.first as Map<String, dynamic>;
    responsePort.close();
    return response;
  }

  @override
  Future<void> init() async {
    loggy.debug("initializing");

    // Start the isolate
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_singboxIsolateEntry, receivePort.sendPort);

    // Get the SendPort from the isolate
    _isolateSendPort = await receivePort.first as SendPort;
    _isolateReady.complete(_isolateSendPort);

    _statusReceiver = ReceivePort('service status receiver');
    final source = _statusReceiver.asBroadcastStream().map((event) => jsonDecode(event as String)).map(SingboxStatus.fromEvent);
    _status = ValueConnectableStream.seeded(
      source,
      const SingboxStopped(),
    ).autoConnect();
  }

  @override
  TaskEither<String, Unit> setup(
    Directories directories,
    bool debug,
  ) {
    final port = _statusReceiver.sendPort.nativePort;
    return TaskEither(
      () async {
        final response = await _sendCommand('setup', {
          'baseDir': directories.baseDir.path,
          'workingDir': directories.workingDir.path,
          'tempDir': directories.tempDir.path,
          'port': port,
          'debug': debug ? 1 : 0,
        });

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> validateConfigByPath(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () async {
        final response = await _sendCommand('parse', {
          'path': path,
          'tempPath': tempPath,
          'debug': debug ? 1 : 0,
        });

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> changeOptions(SingboxConfigOption options) {
    return TaskEither(
      () async {
        final json = jsonEncode(options.toJson());
        final response = await _sendCommand('changeHiddifyOptions', json);

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, String> generateFullConfigByPath(
    String path,
  ) {
    return TaskEither(
      () async {
        final result = await _sendCommand('generateConfig', path);

        if (result.containsKey('response')) {
          final response = result['response'] as String;
          if (response.startsWith("error")) {
            return left(response.replaceFirst("error", ""));
          }
          return right(response);
        } else {
          final err = result['error'] as String;
          return left(err);
        }
      },
    );
  }

  @override
  TaskEither<String, Unit> start(
    String configPath,
    String name,
    bool disableMemoryLimit,
  ) {
    loggy.debug("starting, memory limit: [${!disableMemoryLimit}]");
    return TaskEither(
      () async {
        final response = await _sendCommand('start', {
          'configPath': configPath,
          'disableMemoryLimit': disableMemoryLimit ? 1 : 0,
        });

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither(
      () async {
        final response = await _sendCommand('stop', null);

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> restart(
    String configPath,
    String name,
    bool disableMemoryLimit,
  ) {
    loggy.debug("restarting, memory limit: [${!disableMemoryLimit}]");
    return TaskEither(
      () async {
        final response = await _sendCommand('restart', {
          'configPath': configPath,
          'disableMemoryLimit': disableMemoryLimit ? 1 : 0,
        });

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> resetTunnel() {
    throw UnimplementedError(
      "reset tunnel function unavailable on platform",
    );
  }

  @override
  Stream<SingboxStatus> watchStatus() => _status;

  @override
  Stream<SingboxStats> watchStats() {
    if (_serviceStatsStream != null) return _serviceStatsStream!;
    final receiver = ReceivePort('stats');
    final statusStream = receiver.asBroadcastStream(
      onCancel: (_) {
        _logger.debug("stopping stats command client");
        final err = _box.stopCommandClient(1).cast<Utf8>().toDartString();
        if (err.isNotEmpty) {
          _logger.error("error stopping stats client");
        }
        receiver.close();
        _serviceStatsStream = null;
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            loggy.error("[service stats client] error received: $event");
            throw event.replaceFirst('error:', "");
          }
          return SingboxStats.fromJson(
            jsonDecode(event) as Map<String, dynamic>,
          );
        }
        loggy.error("[service status client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    final err = _box.startCommandClient(1, receiver.sendPort.nativePort).cast<Utf8>().toDartString();
    if (err.isNotEmpty) {
      loggy.error("error starting status command: $err");
      throw err;
    }

    return _serviceStatsStream = statusStream;
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchGroups() {
    final logger = newLoggy("watchGroups");
    if (_outboundsStream != null) return _outboundsStream!;
    final receiver = ReceivePort('groups');
    final outboundsStream = receiver.asBroadcastStream(
      onCancel: (_) {
        logger.debug("stopping");
        receiver.close();
        _outboundsStream = null;
        final err = _box.stopCommandClient(5).cast<Utf8>().toDartString();
        if (err.isNotEmpty) {
          _logger.error("error stopping group client");
        }
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            logger.error("error received: $event");
            throw event.replaceFirst('error:', "");
          }

          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        logger.error("unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    try {
      final err = _box.startCommandClient(5, receiver.sendPort.nativePort).cast<Utf8>().toDartString();
      if (err.isNotEmpty) {
        logger.error("error starting group command: $err");
        throw err;
      }
    } catch (e) {
      receiver.close();
      rethrow;
    }

    return _outboundsStream = outboundsStream;
  }

  @override
  Stream<List<SingboxOutboundGroup>> watchActiveGroups() {
    final logger = newLoggy("[ActiveGroupsClient]");
    final receiver = ReceivePort('active groups');
    final outboundsStream = receiver.asBroadcastStream(
      onCancel: (_) {
        logger.debug("stopping");
        receiver.close();
        final err = _box.stopCommandClient(13).cast<Utf8>().toDartString();
        if (err.isNotEmpty) {
          logger.error("failed stopping: $err");
        }
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            logger.error(event);
            throw event.replaceFirst('error:', "");
          }

          return (jsonDecode(event) as List).map((e) {
            return SingboxOutboundGroup.fromJson(e as Map<String, dynamic>);
          }).toList();
        }
        logger.error("unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    try {
      final err = _box.startCommandClient(13, receiver.sendPort.nativePort).cast<Utf8>().toDartString();
      if (err.isNotEmpty) {
        logger.error("error starting: $err");
        throw err;
      }
    } catch (e) {
      receiver.close();
      rethrow;
    }

    return outboundsStream;
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(
      () async {
        final response = await _sendCommand('selectOutbound', {
          'groupTag': groupTag,
          'outboundTag': outboundTag,
        });

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(
      () async {
        final response = await _sendCommand('urlTest', groupTag);

        final err = response['error'] as String;
        if (err.isNotEmpty) {
          return left(err);
        }
        return right(unit);
      },
    );
  }

  final _logBuffer = <String>[];
  int _logFilePosition = 0;

  @override
  Stream<List<String>> watchLogs(String path) async* {
    yield await _readLogFile(File(path));
    yield* Watcher(path, pollingDelay: const Duration(seconds: 1)).events.asyncMap((event) async {
      if (event.type == ChangeType.MODIFY) {
        await _readLogFile(File(path));
      }
      return _logBuffer;
    });
  }

  @override
  TaskEither<String, Unit> clearLogs() {
    return TaskEither(
      () async {
          _logBuffer.clear();
          return right(unit);
      },
    );
  }

  Future<List<String>> _readLogFile(File file) async {
    if (_logFilePosition == 0 && file.lengthSync() == 0) return [];
    final content = await file.openRead(_logFilePosition).transform(utf8.decoder).join();
    _logFilePosition = file.lengthSync();
    final lines = const LineSplitter().convert(content);
    if (lines.length > 300) {
      lines.removeRange(0, lines.length - 300);
    }
    for (final line in lines) {
      _logBuffer.add(line);
      if (_logBuffer.length > 300) {
        _logBuffer.removeAt(0);
      }
    }
    return _logBuffer;
  }

  @override
  TaskEither<String, WarpResponse> generateWarpConfig({
    required String licenseKey,
    required String previousAccountId,
    required String previousAccessToken,
  }) {
    loggy.debug("generating warp config");
    return TaskEither(
      () async {
        final result = await _sendCommand('generateWarpConfig', {
          'licenseKey': licenseKey,
          'previousAccountId': previousAccountId,
          'previousAccessToken': previousAccessToken,
        });

        if (result.containsKey('response')) {
          final response = result['response'] as String;
          if (response.startsWith("error:")) {
            return left(response.replaceFirst('error:', ""));
          }
          return right(warpFromJson(jsonDecode(response)));
        } else {
          final err = result['error'] as String;
          return left(err);
        }
      },
    );
  }

  // Cleanup method to kill the isolate
  void dispose() {
    _isolate?.kill();
    _statusReceiver.close();
  }
}
