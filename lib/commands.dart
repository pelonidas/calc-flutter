import 'dart:io';

/// "stack" for numbers entered and result of operations
typedef Registry = List<num>;

/// Function to undo a command
typedef UndoFunction = Registry Function(Registry);

/// Application state is a stack of numbers (registry) and stack of undo functions (history)
class CalculatorState {
  final Registry registry;
  final List<UndoFunction> history;
  const CalculatorState({required this.registry, required this.history});
  CalculatorState.empty() : this(registry: [], history: []);
  copy({required Registry registry, required UndoFunction undo}) =>
      CalculatorState(registry: registry, history: [...history, undo]);
}

/// Factory functions for commands
const commands = [
  Enter.new,
  Print.new,
  Exit.new,
  Clear.new,
  Add.new,
  Subtract.new,
  Multiply.new,
  Divide.new,
  Undo.new,
  Help.new,
  Invalid.new
];

/// "interface" for all commands
abstract class Command {
  final String input;
  const Command(this.input);

  /// Names/aliases for the command
  List<String> get names => [];

  /// Description of command
  String get description;

  /// Whether the input is valid for the command on given registry
  bool accept(List<num> registry) => names.contains(input);

  /// Executing the command returns the next application state
  CalculatorState execute(CalculatorState state);
}

class Enter extends Command {
  @override
  final names = ['<number>'];
  @override
  final description = 'Insert/push a number to the registry';
  final num? number;
  Enter(input)
      : number = num.tryParse(input),
        super(input);
  @override
  accept(registry) => number != null;
  @override
  execute(state) => state.copy(
        registry: [...state.registry, number!],
        undo: (registry) => [...registry.take(registry.length - 1)],
      );
}

class Clear extends Command {
  Clear(super.input);
  @override
  final names = ['clear', 'c'];
  @override
  final description = 'Clear the registry';
  @override
  execute(state) => state.copy(registry: [], undo: (_) => state.registry);
}

class Print extends Command {
  @override
  final names = ['print', 'p', ''];
  @override
  final description = 'Print registry';
  Print(super.input);
  @override
  execute(state) {
    print(state.registry);
    return state;
  }
}

class Exit extends Command {
  Exit(super.input);
  @override
  final names = ['exit', 'quit', 'q'];
  @override
  final description = 'Exit process';
  @override
  execute(state) => exit(1);
}

class Undo extends Command {
  @override
  final names = ['undo', 'u'];
  @override
  final description =
      'Undo previously executed command using the undo function in history stack';
  Undo(super.input);
  @override
  execute(state) => CalculatorState(
        registry: state.history.last(state.registry),
        history: [...state.history.take(state.history.length - 1)],
      );
}

class Help extends Command {
  @override
  final names = ['help', 'h', '?'];
  @override
  final description = 'Print help message';
  Help(super.input);
  @override
  execute(CalculatorState state) {
    print('Available commands are:\n');
    commands.map((factory) => factory('')).forEach((command) {
      print(command.names.join(', '));
      print('\t\t${command.description}\n');
    });
    return state;
  }
}

/// Base class for arithmetic operation consuming two operants from registry
abstract class Operator extends Command {
  Operator(super.input);
  apply(num val1, num val2);
  @override
  accept(registry) => super.accept(registry) && registry.length > 1;
  @override
  execute(state) {
    final arg1 = state.registry.elementAt(state.registry.length - 2);
    final arg2 = state.registry.last;
    final result = apply(arg1, arg2);
    print(result);
    return state.copy(
      registry: [...state.registry.take(state.registry.length - 2), result],
      undo: (registry) => [...registry.take(registry.length - 1), arg1, arg2],
    );
  }
}

class Add extends Operator {
  @override
  final names = ['+', 'add'];
  @override
  final description = 'Addition';
  Add(super.input);
  @override
  apply(val1, val2) => val1 + val2;
}

class Subtract extends Operator {
  @override
  final names = ['-', 'sub', 'subtract'];
  @override
  final description = 'Subtraction';
  Subtract(super.input);
  @override
  apply(val1, val2) => val1 - val2;
}

class Multiply extends Operator {
  @override
  final names = ['*', 'mul', 'multiply'];
  @override
  final description = 'Multiplication';
  Multiply(super.input);
  @override
  apply(val1, val2) => val1 * val2;
}

class Divide extends Operator {
  @override
  final names = ['/', 'div', 'divide'];
  @override
  final description = 'Division';
  Divide(super.input);
  @override
  apply(val1, val2) => val1 / val2;
}

/// Fallback command for when no other accepts the input
class Invalid extends Command {
  @override
  final description = '';
  Invalid(super.input);
  @override
  accept(List<num> registry) => true;
  @override
  execute(CalculatorState state) {
    print('Invalid command "$input"');
    return state;
  }
}
