// Adapted from dart_medic `misc` branch containing over_react diagnostics

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:over_react/src/plugin/component_usage.dart';

export 'package:over_react/src/plugin/component_usage.dart';

abstract class _Checker {
  String get name;
  String get description;
  
  int get _modificationStamp;

  List<CheckerError> _errors = [];

  void emitHint({String message, int offset, int end, String fix, String fixMessage}) {
    _errors.add(new CheckerError(name, message, offset, end, AnalysisErrorSeverity.INFO, AnalysisErrorType.LINT, fix, fixMessage, _modificationStamp));
  }
  void emitWarning({String message, int offset, int end, String fix, String fixMessage}) {
    _errors.add(new CheckerError(name, message, offset, end,  AnalysisErrorSeverity.WARNING, AnalysisErrorType.LINT, fix, fixMessage, _modificationStamp));
  }
  void emitError({String message, int offset, int end, String fix, String fixMessage}) {
    _errors.add(new CheckerError(name, message, offset, end,  AnalysisErrorSeverity.ERROR, AnalysisErrorType.LINT, fix, fixMessage, _modificationStamp));
  }

  List<CheckerError> getErrors() => _errors.toList();

  void clearErrors() {
    _errors.clear();
  }
}

abstract class ComponentUsageChecker extends SimpleElementVisitor<Null> with _Checker {
  void visitComponentUsage(
      CompilationUnit unit, FluentComponentUsage usage);

  @override
  Null visitCompilationUnitElement(CompilationUnitElement unit) {
    visitCompilationUnit(unit.computeNode());

    return null;
  }
  
  int _modificationStamp;
  
  Null visitCompilationUnit(CompilationUnit unit) {
    _modificationStamp = unit?.declaredElement?.source?.modificationStamp;

    var astVisitor = new ComponentUsageVisitor(
            (usage) => visitComponentUsage(unit, usage));
    unit..accept(astVisitor);

    _modificationStamp = null;

    return null;
  }
}

typedef void _OnComponent(FluentComponentUsage usage);

class ComponentUsageVisitor extends RecursiveAstVisitor<void> {
  final _OnComponent onComponent;

  ComponentUsageVisitor(this.onComponent);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    return visitInvocationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    return visitInvocationExpression(node);
  }

  void visitInvocationExpression(InvocationExpression node) {
    var usage = getComponentUsage(node);
    if (usage != null) {
      onComponent(usage);
    }

    node.visitChildren(this);
    return null;
  }
}

//
//class ComponentUsageElementVisitor extends RecursiveElementVisitor<void> {
//  final _OnComponent onComponent;
//
//  ComponentUsageElementVisitor(this.onComponent);
//
//  @override
//  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
//    return visitInvocationExpression(node);
//  }
//
//  @override
//  void visitMethodInvocation(MethodInvocation node) {
//    return visitInvocationExpression(node);
//  }
//
//  void visitInvocationExpression(InvocationExpression node) {
//    var usage = getComponentUsage(node);
//    if (usage != null) {
//      onComponent(usage);
//    }
//
//    node.visitChildren(this);
//    return null;
//  }
//}

class CheckerError {
  /// The code of the error
  final String code;
  
  /// Error message for the user.
  final String message;

  /// Optionally, the offset of the incorrect code.
  final int offset;

  /// Optionally, the length of the incorrect code.
  final int end;

  final int modificationStamp;

  String fixMessage;

  int get length => end - offset;

  /// Optionally, the fix for the incorrect code.
  final String fix;

  AnalysisErrorSeverity severity;

  AnalysisErrorType type;

  CheckerError(this.code, this.message, this.offset, this.end, this.severity, this.type, this.fix, this.fixMessage, this.modificationStamp) {
    if (((offset == null) != (end == null)) ||
        ((offset == null) && (fix != null))) {
      throw new ArgumentError(
          'Offset, end and fix must either all be null or all non-null. '
              'Got: offset $offset, end $end, fix $fix');
    }
  }
}
