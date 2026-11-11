import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/testing.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Counts constructions and disposals across all instances.
class _CountingVm extends ArrkViewModel {
  _CountingVm() : super(FakeMessageSink()) {
    created++;
  }

  static int created = 0;
  static int disposed = 0;

  @override
  void dispose() {
    disposed++;
    super.dispose();
  }
}

/// A parent whose rebuilds re-run the build method that holds the ArrkView.
class _Parent extends StatefulWidget {
  const _Parent({required this.child});

  final Widget Function() child;

  @override
  State<_Parent> createState() => _ParentState();
}

class _ParentState extends State<_Parent> {
  int ticks = 0;

  void rebuild() => setState(() => ticks++);

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: widget.child());
}

Widget _show(_CountingVm vm, BuildContext context) => const SizedBox();

void main() {
  setUp(() {
    _CountingVm.created = 0;
    _CountingVm.disposed = 0;
  });

  Future<void> rebuildParent(WidgetTester tester, int times) async {
    final state = tester.state<_ParentState>(find.byType(_Parent));
    for (var i = 0; i < times; i++) {
      state.rebuild();
      await tester.pump();
    }
  }

  testWidgets('create: builds the VM once across parent rebuilds, disposes it once', (tester) async {
    late _CountingVm provided;
    await tester.pumpWidget(
      _Parent(
        child: () => ArrkView<_CountingVm>(
          create: _CountingVm.new,
          builder: (vm, context) {
            provided = vm;
            return const SizedBox();
          },
        ),
      ),
    );
    final first = provided;

    await rebuildParent(tester, 5);

    expect(_CountingVm.created, 1);
    expect(identical(provided, first), isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(_CountingVm.disposed, 1);
  });

  testWidgets('create: ServiceLocator.get.call resolves a factory VM once', (tester) async {
    GetIt.instance.registerFactory<_CountingVm>(_CountingVm.new);
    addTearDown(GetIt.instance.reset);

    await tester.pumpWidget(
      _Parent(child: () => ArrkView<_CountingVm>(create: ServiceLocator.get.call, builder: _show)),
    );
    await rebuildParent(tester, 3);

    expect(_CountingVm.created, 1);
    await tester.pumpWidget(const SizedBox());
    expect(_CountingVm.disposed, 1);
  });

  testWidgets('model: built in build() leaks one VM per rebuild (why create: exists)', (tester) async {
    await tester.pumpWidget(
      _Parent(child: () => ArrkView<_CountingVm>(model: _CountingVm(), builder: _show)),
    );
    await rebuildParent(tester, 3);
    await tester.pumpWidget(const SizedBox());

    expect(_CountingVm.created, 4);
    expect(_CountingVm.disposed, 1, reason: 'only the first instance is ever used and disposed');
  });

  testWidgets('model: a caller-held instance is used and auto-disposed', (tester) async {
    final vm = _CountingVm();
    late _CountingVm provided;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ArrkView<_CountingVm>(
          model: vm,
          builder: (v, context) {
            provided = v;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(provided, vm), isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(_CountingVm.disposed, 1);
  });

  testWidgets('autoDispose: false leaves the VM to its owner', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ArrkView<_CountingVm>(create: _CountingVm.new, autoDispose: false, builder: _show),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(_CountingVm.created, 1);
    expect(_CountingVm.disposed, 0);
  });

  testWidgets('initState and postFrameCallback receive the created VM', (tester) async {
    _CountingVm? fromInit;
    _CountingVm? fromFrame;
    late _CountingVm provided;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ArrkView<_CountingVm>(
          create: _CountingVm.new,
          initState: (vm) => fromInit = vm,
          postFrameCallback: (vm) => fromFrame = vm,
          builder: (vm, context) {
            provided = vm;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(identical(fromInit, provided), isTrue);
    expect(identical(fromFrame, provided), isTrue);
  });

  test('exactly one of create: and model: is required', () {
    expect(() => ArrkView<_CountingVm>(builder: _show), throwsAssertionError);
    expect(
      () => ArrkView<_CountingVm>(create: _CountingVm.new, model: _CountingVm(), builder: _show),
      throwsAssertionError,
    );
  });
}
