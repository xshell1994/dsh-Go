// A send that the watch no longer owns (a reconnect moved the mux generation
// on) hands its text back to the composer. It must say so: the bubble is gone
// and the text came back, and without a word that reads as the message having
// vanished on its own.

import 'dart:async';

import 'package:dsh_app/l10n/l10n.dart';
import 'package:dsh_app/state/chat_state.dart';
import 'package:dsh_app/state/connection_state.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what [ChatController.send] delivers, and holds the prompt until the
/// test lets it through, so the send is still in flight when the watch moves.
class _HeldClient extends DshClient {
  _HeldClient() : super(DshConnection(Uri.parse('http://127.0.0.1:9')));

  final events = StreamController<DshEvent>.broadcast();
  final prompts = <String?>[];

  /// Held while a send is in flight; completed by [release].
  Completer<String>? held;

  void release() {
    held?.complete('r');
    held = null;
  }

  @override
  Stream<DshEvent> watch(String sessionId, {WatchOptions options = const WatchOptions()}) => events.stream;

  @override
  Future<String> prompt(
    String sessionId,
    String text, {
    List<PromptImage> images = const [],
    List<String> fileReceiptIds = const [],
    String? requestId,
    PromptMode mode = PromptMode.queue,
    String? timeZone,
  }) async {
    prompts.add(requestId);
    if (held case final held?) return held.future;
    return requestId ?? 'r';
  }
}

void main() {
  late _HeldClient client;
  late ProviderContainer container;

  ChatController chat() => container.read(chatProvider('s1').notifier);
  ChatState state() => container.read(chatProvider('s1'));
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    client = _HeldClient();
    container = ProviderContainer(
      overrides: [
        activeConnectionProvider.overrideWithValue(
          AsyncData<HostConnection?>(HostConnection(client: client, label: '本机', isLocal: true)),
        ),
      ],
    );
    container.listen(chatProvider('s1'), (_, _) {});
    client.events.add(
      SessionSnapshotEvent.fromJson('s1', {
        'header': {'id': 's1'},
        'cursor': -1,
        'records': <Object?>[],
        'projections': {'asOfSeq': -1, 'values': <String, Object?>{}},
      }),
    );
    await container.pump();
  });

  tearDown(() async {
    container.dispose();
    await client.events.close();
  });

  test('a send the watch no longer owns says it did not go out', () async {
    client.held = Completer<String>();
    final sending = chat().send('还没发出去的一句话', mode: SendMode.now);
    await settle();
    expect(state().pending, hasLength(1), reason: 'the bubble waits while the send is in flight');

    // The watch moves on: the mux generation changes under the in-flight send,
    // which is what a reconnect does.
    client.mux.reconnect();
    client.release();
    await sending;
    await settle();

    expect(state().pending, isEmpty, reason: 'the bubble it can no longer match goes');
    expect(
      state().notice,
      appL10n.stateChatSendRetired,
      reason: 'the text comes back to the composer, so it has to say why it did',
    );
  });
}