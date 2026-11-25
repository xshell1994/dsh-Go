// A Bot's own chat (`chat`) sends a group's rows as `post` and `relay`; the
// app draws a post as the member's message and a relay as its round event.

import 'package:dsh_client/dsh_client.dart';
import 'package:test/test.dart';

void main() {
  test('a post reads as its member\'s message', () {
    final item = DsBotItem.fromJson({
      'kind': 'post',
      'botId': 'writer',
      'name': 'Writer',
      'text': '初稿放在这里',
      'time': 1760000000000,
      'duration': 1200,
    });
    expect(item.kind, DsBotItemKind.bot);
    expect(item.text, '初稿放在这里');
    expect(item.botId, 'writer');
    expect(item.name, 'Writer');
    expect(item.time, DateTime.fromMillisecondsSinceEpoch(1760000000000));
    expect(item.duration, const Duration(milliseconds: 1200));
    expect(item.whole, isNull);
  });

  test('a post of several replies keeps them in order', () {
    final item = DsBotItem.fromJson({
      'kind': 'post',
      'texts': ['第一句', '', '第二句'],
    });
    expect(item.text, '第一句\n\n第二句');
  });

  test('a post past one message carries its file', () {
    final item = DsBotItem.fromJson({
      'kind': 'post',
      'text': '开头……',
      'length': 9100,
      'file': {'attachmentId': 'a1', 'name': 'post.md'},
    });
    expect(item.text, '开头……');
    expect(item.whole?.length, 9100);
    expect(item.whole?.file['attachmentId'], 'a1');
  });

  test('a relay with no event of its own is a message', () {
    final item = DsBotItem.fromJson({
      'kind': 'relay',
      'time': 1760000000000,
      'reply': {'botId': 'chief', 'name': 'Chief', 'text': '收到', 'duration': 800},
    });
    expect(item.kind, DsBotItemKind.bot);
    expect(item.text, '收到');
    expect(item.botId, 'chief');
    expect(item.duration, const Duration(milliseconds: 800));
  });

  test('a relay of a round event is an event line', () {
    final item = DsBotItem.fromJson({
      'kind': 'relay',
      'reply': {'kind': 'working', 'botId': 'chief', 'name': 'Chief'},
    });
    expect(item.kind, DsBotItemKind.event);
    expect(item.event, 'working');
    expect(item.name, 'Chief');
  });

  test('a relay of the person stays the person\'s', () {
    final item = DsBotItem.fromJson({
      'kind': 'relay',
      'reply': {'kind': 'user', 'text': '我也说一句'},
    });
    expect(item.kind, DsBotItemKind.user);
    expect(item.text, '我也说一句');
  });
}