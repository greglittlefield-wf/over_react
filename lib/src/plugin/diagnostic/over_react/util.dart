import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:over_react/src/plugin/component_usage.dart';

void forEachCascadedProp(FluentComponentUsage usage, void f(PropertyAccess lhs, Expression rhs)) {
  if (usage.cascadeExpression == null) return;

  for (var section in usage.cascadeExpression.cascadeSections) {
    if (section is AssignmentExpression) {
      final lhs = section.leftHandSide;
      if (lhs is PropertyAccess) {
        f(lhs, section.rightHandSide);
      }
    }
  }
}

const String missingBuilderMessageSuffix = '\nAre you missing the builder invocation?';
const String missingBuilderFixMessage = 'Add builder invocation.';

bool couldBeMissingBuilderInvocation(Expression expression) {
  // TODO actually check against UiProps, or at the very least against Map
  return expression.staticType.name?.endsWith('Props');
}

List<SourceEdit> getMissingInvocationBuilderEdits(Expression expression) {
  if (expression.unParenthesized != expression) {
    // Expression is already parenthesized
    return [
      new SourceEdit(expression.end, 0, '()'),
    ]; 
  } else if (expression.parent is ParenthesizedExpression) {
    // Expression is the child of a parenthesized expression
    return [
      new SourceEdit(expression.parent.end, 0, '()'),
    ];
  } else {
    if (expression is CascadeExpression) {
      // Expression is unparenthesized cascade
      return [
        new SourceEdit(expression.offset, 0, '('),
        new SourceEdit(expression.end + '('.length, 0, ')()'),
      ];
    } else {
      // Expression is unparenthesized without cascade
      return [
        new SourceEdit(expression.end, 0, '()'),
      ];
    }
  }
}
