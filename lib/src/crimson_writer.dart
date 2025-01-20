// ignore_for_file: parameter_assignments, avoid_positional_boolean_parameters

import 'dart:math';
import 'dart:typed_data';

import 'package:crimson/src/consts.dart';

/// A writer that writes JSON to a [Uint8List].
class CrimsonWriter {
  final _buffers = <Uint8List>[];
  var _buffer = Uint8List(2048);
  var _offset = 0;

  @pragma('vm:prefer-inline')
  void _ensure(int size) {
    if (_buffer.length - _offset < size) {
      final bufferView = Uint8List.view(_buffer.buffer, 0, _offset);
      _buffers.add(bufferView);
      _buffer = Uint8List(max(size, _buffer.length) * 2);
    }
  }

  @pragma('vm:prefer-inline')
  void _writeByte(int byte) {
    _ensure(1);
    _buffer[_offset++] = byte;
  }

  @pragma('vm:prefer-inline')
  void _writeString(String value) {
    _ensure(value.length + 2);
    var offset = _offset;

    _buffer[offset++] = tokenDoubleQuote;

    var i = 0;
    for (; i < value.length; i++) {
      final char = value.codeUnitAt(i);
      if (char < oneByteLimit && canDirectWrite[char]) {
        _buffer[offset++] = char;
      } else {
        break;
      }
    }

    if (i < value.length) {
      _ensure((value.length - i) * 3 + 1);

      for (; i < value.length; i++) {
        final char = value.codeUnitAt(i);
        if (char < oneByteLimit) {
          if (canDirectWrite[char]) {
            _buffer[offset++] = char;
          } else {
            switch (char) {
              case tokenDoubleQuote:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenDoubleQuote;
              case tokenBackslash:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenBackslash;
              case tokenBackspace:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenB;
              case tokenFormFeed:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenF;
              case tokenLineFeed:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenN;
              case tokenCarriageReturn:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenR;
              case tokenTab:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenT;
              default:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenU;
                _buffer[offset++] = tokenZero;
                _buffer[offset++] = tokenZero;
                _buffer[offset++] = hexDigits[(char >> 4) & 0xF];
                _buffer[offset++] = hexDigits[char & 0xF];
            }
          }
        } else if ((char & surrogateTagMask) == leadSurrogateMin) {
          // combine surrogate pair
          final nextChar = value.codeUnitAt(++i);
          final rune = 0x10000 + ((char & surrogateValueMask) << 10) |
              (nextChar & surrogateValueMask);
          // If the rune is encoded with 2 code-units then it must be encoded
          // with 4 bytes in UTF-8.
          _buffer[offset++] = 0xF0 | (rune >> 18);
          _buffer[offset++] = 0x80 | ((rune >> 12) & 0x3f);
          _buffer[offset++] = 0x80 | ((rune >> 6) & 0x3f);
          _buffer[offset++] = 0x80 | (rune & 0x3f);
        } else if (char <= twoByteLimit) {
          _buffer[offset++] = 0xC0 | (char >> 6);
          _buffer[offset++] = 0x80 | (char & 0x3f);
        } else {
          _buffer[offset++] = 0xE0 | (char >> 12);
          _buffer[offset++] = 0x80 | ((char >> 6) & 0x3f);
          _buffer[offset++] = 0x80 | (char & 0x3f);
        }
      }
    }

    _buffer[offset++] = tokenDoubleQuote;
    _offset = offset;
  }

  /// Start a new JSON object.
  @pragma('vm:prefer-inline')
  void writeObjectStart() {
    _writeByte(tokenLBrace);
  }

  /// End the current JSON object.
  @pragma('vm:prefer-inline')
  void writeObjectEnd() {
    if (_buffer[_offset - 1] == tokenComma) {
      _buffer[_offset - 1] = tokenRBrace;
      _writeByte(tokenComma);
    } else {
      _ensure(2);
      _buffer[_offset++] = tokenRBrace;
      _buffer[_offset++] = tokenComma;
    }
  }

  /// Write a JSON object key.
  @pragma('vm:prefer-inline')
  void writeObjectKey(String field) {
    _writeString(field);
    _writeByte(tokenColon);
  }

  /// Write a JSON object key that only consists of ASCII characters and does
  /// not need escaping.
  @pragma('vm:prefer-inline')
  void writeObjectKeyRaw(String field) {
    _ensure(field.length + 3);
    _buffer[_offset++] = tokenDoubleQuote;
    for (var i = 0; i < field.length; i++) {
      _buffer[_offset++] = field.codeUnitAt(i);
    }
    _buffer[_offset++] = tokenDoubleQuote;
    _buffer[_offset++] = tokenColon;
  }

  /// Start a new JSON array.
  @pragma('vm:prefer-inline')
  void writeArrayStart() {
    _writeByte(tokenLBracket);
  }

  /// End the current JSON array.
  @pragma('vm:prefer-inline')
  void writeArrayEnd() {
    if (_buffer[_offset - 1] == tokenComma) {
      _buffer[_offset - 1] = tokenRBracket;
      _writeByte(tokenComma);
    } else {
      _ensure(2);
      _buffer[_offset++] = tokenRBracket;
      _buffer[_offset++] = tokenComma;
    }
  }

  /// Write the null value.
  @pragma('vm:prefer-inline')
  void writeNull() {
    _ensure(5);
    _buffer[_offset++] = tokenN;
    _buffer[_offset++] = tokenU;
    _buffer[_offset++] = tokenL;
    _buffer[_offset++] = tokenL;
    _buffer[_offset++] = tokenComma;
  }

  /// Write true or false.
  @pragma('vm:prefer-inline')
  void writeBool(bool value) {
    if (value) {
      _ensure(5);
      _buffer[_offset++] = tokenT;
      _buffer[_offset++] = tokenR;
      _buffer[_offset++] = tokenU;
      _buffer[_offset++] = tokenE;
    } else {
      _ensure(6);
      _buffer[_offset++] = tokenF;
      _buffer[_offset++] = tokenA;
      _buffer[_offset++] = tokenL;
      _buffer[_offset++] = tokenS;
      _buffer[_offset++] = tokenE;
    }
    _buffer[_offset++] = tokenComma;
  }

  /// Write a string.
  @pragma('vm:prefer-inline')
  void writeString(String value) {
    _writeString(value);
    _writeByte(tokenComma);
  }

  /// Write a number.
  void writeNum(num value) {
    final str = value.toString();
    _ensure(str.length + 1);
    for (var i = 0; i < str.length; i++) {
      _buffer[_offset++] = str.codeUnitAt(i);
    }
    _buffer[_offset++] = tokenComma;
  }

  /// Write a list.
  void writeArray(List<dynamic> value) {
    writeArrayStart();
    for (final item in value) {
      write(item);
    }
    writeArrayEnd();
  }

  /// Write a map.
  void writeObject(Map<String, dynamic> value) {
    writeObjectStart();
    for (final key in value.keys) {
      writeObjectKey(key);
      write(value[key]);
    }
    writeObjectEnd();
  }

  /// Write any value.
  void write(dynamic value) {
    if (value == null) {
      writeNull();
    } else if (value is bool) {
      writeBool(value);
    } else if (value is num) {
      writeNum(value);
    } else if (value is String) {
      writeString(value);
    } else if (value is List) {
      writeArray(value);
    } else if (value is Map<String, dynamic>) {
      writeObject(value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  /// Convert the internal buffer to a [Uint8List].
  Uint8List toBytes() {
    if (_buffer[_offset - 1] == tokenComma) {
      _offset--;
    }

    var size = 0;
    for (final buffer in _buffers) {
      size += buffer.length;
    }
    size += _offset;
    final result = Uint8List(size);
    var offset = 0;
    for (final buffer in _buffers) {
      result.setRange(offset, offset + buffer.length, buffer);
      offset += buffer.length;
    }
    result.setRange(offset, offset + _offset, _buffer);
    return result;
  }
}
