/*
 * Created by:  Blake Davis
 * Description: Utilities for printing and debugging
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

/* ======================================================================================================================
 * MARK: Stack Trace
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class LoggerStackTrace {
  final String functionName;
  final String callerFunctionName;
  final String fileName;
  final int lineNumber;
  final int columnNumber;

  const LoggerStackTrace._({
    required this.functionName,
    required this.callerFunctionName,
    required this.fileName,
    required this.lineNumber,
    required this.columnNumber,
  });

  factory LoggerStackTrace.from(StackTrace trace) {
    final frames = trace.toString().split("\n");
    final functionName = _getFunctionNameFromFrame(frames[0]);
    final callerFunctionName = _getFunctionNameFromFrame(frames[1]);
    final fileInfo = _getFileInfoFromFrame(frames[0]);

    return LoggerStackTrace._(
      functionName: functionName,
      callerFunctionName: callerFunctionName,
      fileName: fileInfo[0],
      lineNumber: int.parse(fileInfo[1]),
      columnNumber: int.parse(fileInfo[2].replaceFirst(")", "")),
    );
  }

  static List<String> _getFileInfoFromFrame(String trace) {
    final indexOfFileName = trace.indexOf(RegExp('[A-Za-z]+.dart'));
    final fileInfo = trace.substring(indexOfFileName);

    return fileInfo.split(':');
  }

  static String _getFunctionNameFromFrame(String trace) {
    final indexOfWhiteSpace = trace.indexOf(" ");
    final subStr = trace.substring(indexOfWhiteSpace);
    final indexOfFunction = subStr.indexOf(RegExp('[A-Za-z0-9]'));

    return subStr
        .substring(indexOfFunction)
        .substring(0, subStr.substring(indexOfFunction).indexOf(" "));
  }

  @override
  String toString() {
    return "LoggerStackTrace("
        "functionName: $functionName, "
        "callerFunctionName: $callerFunctionName, "
        "fileName: $fileName, "
        "lineNumber: $lineNumber, "
        "columnNumber: $columnNumber)";
  }
}

/* ======================================================================================================================
 * MARK: Get Caller
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
String getCaller(StackTrace currentStack) {
  final lines = currentStack.toString().trim().split('\n');
  if (lines.length < 2) {
    return 'unknown';
  }

  final line = lines[1];
  final match = RegExp(r'#\d+\s+(.+)').firstMatch(line);
  if (match == null) {
    return line.trim();
  }

  final frame = match.group(1)!; // e.g. "main (package:...:519:3)"
  final locationIndex = frame.indexOf(' (');
  if (locationIndex == -1) {
    return frame.trim();
  }

  return frame.substring(0, locationIndex).trim();
}

/* ======================================================================================================================
 * MARK: Log Print
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
void logPrint(String content,
    {String? context,
    Map<String, int> columnWidths = const {},
    bool contentOnly = false}) {
  multilineLogPrint([content],
      context: getCaller(StackTrace.current),
      columnWidths: columnWidths,
      contentOnly: contentOnly);
}

// Alias of multilineLogPrint()
void mlogPrint(List<String> contentList,
    {String? context,
    Map<String, int> columnWidths = const {},
    bool contentOnly = false}) {
  multilineLogPrint(contentList,
      context: getCaller(StackTrace.current),
      columnWidths: columnWidths,
      contentOnly: contentOnly);
}

void multilineLogPrint(List<String> contentList,
    {String? context,
    Map<String, int> columnWidths = const {},
    bool contentOnly = false}) {
  Map<String, int> defaultColumnWidths = {"content": -1, "context": 16};

  for (String content in contentList) {
    String output = "";

    context ??= getCaller(StackTrace.current);

    final maxContextWidth =
        (columnWidths["context"] ?? defaultColumnWidths["context"]!);
    if (context.length > maxContextWidth && maxContextWidth > -1) {
      final prefix = context.substring(0, 5);
      final suffix = context.substring(context.length - 8);
      output += "$prefix...$suffix";
    } else {
      output += context + (" " * (maxContextWidth - context.length));
    }

    output += " | ";

    if ((columnWidths["content"] ?? defaultColumnWidths["content"]!) > -1 &&
        content.length >
            (columnWidths["content"] ?? defaultColumnWidths["content"]!)) {
      output +=
          "${content.substring(0, ((columnWidths["content"] ?? defaultColumnWidths["content"]!) - 3))}...";
    } else {
      output += content +
          (" " *
              ((columnWidths["content"] ?? defaultColumnWidths["content"]!) -
                  content.length));
    }

    print(output);
  }
}

/* ======================================================================================================================
 * MARK: Long Print
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
void longPrint(Object object) async {
  int defaultPrintLength = 1020;

  if (object == null || object.toString().length <= defaultPrintLength) {
    print(object);
  } else {
    String log = object.toString();
    int start = 0;
    int endIndex = defaultPrintLength;
    int logLength = log.length;
    int tmpLogLength = log.length;

    while (endIndex < logLength) {
      print(log.substring(start, endIndex));

      endIndex += defaultPrintLength;
      start += defaultPrintLength;
      tmpLogLength -= defaultPrintLength;
    }

    if (tmpLogLength > 0) {
      print(log.substring(start, logLength));
    }
  }
}
