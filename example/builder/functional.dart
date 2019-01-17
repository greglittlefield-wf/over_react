import 'package:over_react/over_react.dart';

// ignore: mixin_of_non_class,undefined_class
part 'functional.over_react.g.dart';

@Component()
_$FunctionalComponent(UiProps props, String foo, bool bar) => //
    Dom.span()(
      props.children,
      'Foo: $foo',
      'isOn: $bar',
    );

@Component()
_$AnotherOneComponent(Map props, bool yeah) => //
    Dom.span()(
      yeah ? 'YEAAAH' : 'nooo :(',
    );


