import 'dart:collection';

import 'package:webviewx/src/utils/source_type.dart';

/// Web version only.
///
/// Custom history stack coded from scratch.
/// This was needed because I couldn't retrieve accurate information
/// about the current state of the URL from within the iframe.
class HistoryStack {
  HistoryEntry _currentEntry;
  final Queue<HistoryEntry> _backHistory = Queue();
  final Queue<HistoryEntry> _forwardHistory = Queue();

  /// Constructor
  HistoryStack({HistoryEntry initialEntry}) : _currentEntry = initialEntry;

  @override
  String toString() {
    return 'Back: $_backHistory\nCurrent: $_currentEntry\nForward: $_forwardHistory\n';
  }

  /// Returns current history entry (i.e. current page)
  HistoryEntry get currentEntry => _currentEntry;

  /// Returns true if you can go back
  bool get canGoBack => _backHistory.isNotEmpty;

  /// Returns true if you can go forward
  bool get canGoForward => _forwardHistory.isNotEmpty;

  /// Function to add a new history entry.
  /// This is used when accessing another page.
  void addEntry(HistoryEntry newEntry) {
    if (newEntry == _currentEntry) {
      return;
    }

    _backHistory.addLast(_currentEntry);

    _currentEntry = newEntry;

    _forwardHistory.clear();
  }

  /// Function to move back in history.
  /// Returns the new history entry.
  HistoryEntry moveBack() {
    if (canGoBack) {
      _forwardHistory.addFirst(_currentEntry);

      _currentEntry = _backHistory.removeLast();

      return _currentEntry;
    }
    return null;
  }

  /// Function to move forward in history.
  /// Returns the new history entry.
  HistoryEntry moveForward() {
    if (canGoForward) {
      _backHistory.addLast(_currentEntry);

      _currentEntry = _forwardHistory.removeFirst();

      return _currentEntry;
    }
    return null;
  }
}

/// History entry
class HistoryEntry {
  /// Source
  final String source;

  /// Source type
  final SourceType sourceType;

  /// Constructor
  HistoryEntry({
    this.source,
    this.sourceType,
  });

  @override
  String toString() {
    return [source, sourceType.toString()].toString();
  }

  @override
  bool operator ==(Object other) =>
      (other is HistoryEntry) &&
      (other.source == source) &&
      (other.sourceType == sourceType);

  @override
  int get hashCode => source.hashCode ^ sourceType.hashCode;
}
