// Reading a group's newest page again must keep what was already shown: an
// earlier page the person scrolled to, and a round that added rows in the
// middle of the page.

import 'package:dsh_app/state/bots_state.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_test/flutter_test.dart';

DsBotItem _line(String id, String text) =>
    DsBotItem(kind: DsBotItemKind.bot, id: id, text: text);

List<String?> _ids(List<DsBotItem> items) => [for (final item in items) item.id];

void main() {
  test('a page that starts in the middle keeps the lines before it', () {
    final shown = [_line('1', 'a'), _line('2', 'b'), _line('3', 'c')];
    final merged = mergeNewestPage(shown, [_line('3', 'c'), _line('4', 'd')]);
    expect(_ids(merged), ['1', '2', '3', '4']);
  });

  test('a page that shares nothing adds to what is shown', () {
    final shown = [_line('1', 'a'), _line('2', 'b')];
    final merged = mergeNewestPage(shown, [_line('3', 'c'), _line('4', 'd')]);
    expect(_ids(merged), ['1', '2', '3', '4']);
  });

  test('a page whose first row is new keeps what came before it', () {
    // A round logged rows above the page's first line: the overlap is further
    // in, and what is shown must not be replaced by it.
    final shown = [_line('1', 'a'), _line('2', 'b')];
    final merged = mergeNewestPage(shown, [_line('3', 'c'), _line('2', 'b'), _line('4', 'd')]);
    expect(_ids(merged), ['1', '2', '4']);
  });
}