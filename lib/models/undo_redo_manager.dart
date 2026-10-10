import 'package:nixsvg/models/vector_shape.dart';

class UndoRedoManager {
  final List<List<VectorShape>> _history = [];
  int _currentIndex = -1;
  final int maxHistoryLength;

  UndoRedoManager({this.maxHistoryLength = 50});

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  void saveState(List<VectorShape> shapes) {
    // Truncate history after current index if we made new changes after undoing
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Deep copy of shapes
    final snapshot = shapes.map((s) => s.copyWith()).toList();
    _history.add(snapshot);

    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
    } else {
      _currentIndex++;
    }
  }

  List<VectorShape>? undo() {
    if (!canUndo) return null;
    _currentIndex--;
    return _history[_currentIndex].map((s) => s.copyWith()).toList();
  }

  List<VectorShape>? redo() {
    if (!canRedo) return null;
    _currentIndex++;
    return _history[_currentIndex].map((s) => s.copyWith()).toList();
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}
