import 'dart:convert';

import 'package:data_explorer/data_explorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCallbackFunction extends Mock {
  call();
}

const testJson = '''
{
  "firstClass": {
    "firstClass.firstField": "firstField",
    "firstClass.secondField": "secondField",
    "firstClass.thirdField": "thirdField",
    "firstClass.firstClassField": {
      "firstClassField.firstField": "firstField",
      "firstClassField.secondField": "secondField",
      "firstClassField.thirdField": "thirdField",
      "firstClassField.innerClassField": {
        "innerClassField.firstField": "firstField",
        "innerClassField.secondField": "secondField",
        "innerClassField.thirdField": "thirdField"
      }
    },
    "firstClass.secondClassField": {
      "secondClassField.firstField": "firstField",
      "secondClassField.secondField": "secondField",
      "secondClassField.thirdField": "thirdField",
      "secondClassField.innerClassField": {
        "innerClassField.firstField": "firstField",
        "innerClassField.secondField": "secondField",
        "innerClassField.thirdField": "thirdField"
      }
    },
    "firstClass.array": [
      0,
      1,
      2
    ]
  },
  "secondClass": {
    "secondClass.firstField": "firstField",
    "secondClass.secondField": "secondField",
    "secondClass.thirdField": "thirdField",
    "secondClass.firstClassField": {
      "firstClassField.firstField": "firstField",
      "firstClassField.secondField": "secondField",
      "firstClassField.thirdField": "thirdField",
      "firstClassField.innerClassField": {
        "innerClassField.firstField": "firstField",
        "innerClassField.secondField": "secondField",
        "innerClassField.thirdField": "thirdField"
      }
    },
    "secondClass.secondClassField": {
      "secondClassField.firstField": "firstField",
      "secondClassField.secondField": "secondField",
      "secondClassField.thirdField": "thirdField",
      "secondClassField.innerClassField": {
        "innerClassField.firstField": "firstField",
        "innerClassField.secondField": "secondField",
        "innerClassField.thirdField": "thirdField"
      }
    },
    "secondClass.array": [
      0,
      1,
      2
    ]
  }
}
''';

void main() {
  group('DataExplorerStore', () {
    test('build nodes', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));
      expect(store.displayNodes, hasLength(48));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(24).key, 'secondClass');
    });

    test('build all collapsed nodes', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson), isAllCollapsed: true);
      expect(store.displayNodes, hasLength(2));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(1).key, 'secondClass');
      expect(store.areAllExpanded(), isFalse);
      expect(store.areAllCollapsed(), isTrue);
    });

    test('build nodes notifies listeners', () {
      final store = DataExplorerStore();
      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.buildNodes(json.decode(testJson));
      verify(() => listener.call()).called(1);
    });

    test('build collapsed nodes notifies listeners', () {
      final store = DataExplorerStore();
      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.buildNodes(json.decode(testJson), isAllCollapsed: true);
      verify(() => listener.call()).called(1);
    });

    test('collapse all nodes', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));

      final listener = MockCallbackFunction();
      store.addListener(listener);
      store.collapseAll();

      expect(store.displayNodes, hasLength(2));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(1).key, 'secondClass');
      verify(() => listener.call()).called(1);

      expect(store.areAllExpanded(), isFalse);
      expect(store.areAllCollapsed(), isTrue);
    });

    test('expand all nodes', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson), isAllCollapsed: true);

      final listener = MockCallbackFunction();
      store.addListener(listener);
      store.expandAll();

      expect(store.displayNodes, hasLength(48));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(24).key, 'secondClass');
      verify(() => listener.call()).called(1);

      expect(store.areAllExpanded(), isTrue);
      expect(store.areAllCollapsed(), isFalse);
    });

    test('collapse node', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));

      final listener = MockCallbackFunction();
      store.addListener(listener);

      expect(store.displayNodes, hasLength(48));
      store.collapseNode(store.displayNodes.first);

      expect(store.displayNodes, hasLength(25));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(1).key, 'secondClass');
      verify(() => listener.call()).called(1);

      expect(store.areAllExpanded(), isFalse);
      expect(store.areAllCollapsed(), isFalse);
    });

    test("collapse won't do anything for non root nodes", () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));
      expect(store.displayNodes, hasLength(48));

      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.collapseNode(store.displayNodes.elementAt(1));

      expect(store.displayNodes, hasLength(48));
      expect(store.displayNodes.elementAt(1).isCollapsed, isFalse);
      verifyNever(() => listener.call());
    });

    test("collapse won't do anything for already collapsed nodes", () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson), isAllCollapsed: true);
      expect(store.displayNodes, hasLength(2));

      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.collapseNode(store.displayNodes.first);

      expect(store.displayNodes, hasLength(2));
      expect(store.displayNodes.first.isCollapsed, isTrue);
      verifyNever(() => listener.call());
    });

    test('expand node', () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson), isAllCollapsed: true);

      final listener = MockCallbackFunction();
      store.addListener(listener);

      expect(store.displayNodes, hasLength(2));
      store.expandNode(store.displayNodes.first);

      expect(store.displayNodes, hasLength(8));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(7).key, 'secondClass');
      verify(() => listener.call()).called(1);

      expect(store.areAllExpanded(), isFalse);
      expect(store.areAllCollapsed(), isFalse);
    });

    test("expand won't do anything for non root nodes", () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson), isAllCollapsed: true);
      store.expandNode(store.displayNodes.first);
      expect(store.displayNodes, hasLength(8));

      /// Force view model value as collapsed.
      store.displayNodes.elementAt(1).collapse();

      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.expandNode(store.displayNodes.elementAt(1));

      expect(store.displayNodes, hasLength(8));
      expect(store.displayNodes.elementAt(1).isCollapsed, isTrue);
      verifyNever(() => listener.call());
    });

    test("expand won't do anything for already expanded nodes", () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));
      expect(store.displayNodes, hasLength(48));

      final listener = MockCallbackFunction();
      store.addListener(listener);

      store.expandNode(store.displayNodes.first);

      expect(store.displayNodes, hasLength(48));
      expect(store.displayNodes.first.isCollapsed, isFalse);
      verifyNever(() => listener.call());
    });

    test("expand and collapse won't change collapse state of children nodes",
        () {
      final store = DataExplorerStore();
      store.buildNodes(json.decode(testJson));
      expect(store.displayNodes, hasLength(48));

      final listener = MockCallbackFunction();
      store.addListener(listener);

      // Just make sure the this element is our expected inner class.
      expect(store.displayNodes.elementAt(4).key, 'firstClass.firstClassField');

      store.collapseNode(store.displayNodes.elementAt(4));
      expect(store.displayNodes, hasLength(41));

      // Now collapse the parent class node.
      store.collapseNode(store.displayNodes.elementAt(0));
      expect(store.displayNodes, hasLength(25));
      expect(store.displayNodes.elementAt(0).key, 'firstClass');
      expect(store.displayNodes.elementAt(1).key, 'secondClass');

      // Expand again and check if firstClass.firstClassField node still
      // collapsed and firstClass.secondClassField still expanded.
      store.expandNode(store.displayNodes.elementAt(0));
      expect(store.displayNodes, hasLength(41));
      expect(store.displayNodes.elementAt(4).key, 'firstClass.firstClassField');
      expect(store.displayNodes.elementAt(4).isCollapsed, isTrue);
      expect(
        store.displayNodes.elementAt(5).key,
        'firstClass.secondClassField',
      );
      expect(store.displayNodes.elementAt(5).isCollapsed, isFalse);

      verify(() => listener.call()).called(3);
    });

    group('areAllCollapsed', () {
      test('works properly when nodes are built with isAllCollapsed as false',
          () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: false);

        expect(store.areAllCollapsed(), isFalse);
      });

      test('works properly when nodes are built with isAllCollapsed as true',
          () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: true);

        expect(store.areAllCollapsed(), isTrue);
      });

      test('''works properly when collapsing a root class child that has 
      inner classes that are not collapsed''', () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: true);

        store.expandNode(store.getNodeByKey('firstClass'));
        store.expandNode(store.getNodeByKey('firstClass.firstClassField'));
        store.expandNode(store.getNodeByKey('firstClassField.innerClassField'));
        store.collapseNode(store.getNodeByKey('firstClass.firstClassField'));

        expect(store.areAllCollapsed(), isFalse);

        store.collapseNode(store.getNodeByKey('firstClass'));

        expect(store.areAllCollapsed(), isTrue);
      });

      test('works properly when collapsing each node individually', () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: false);

        expect(store.areAllCollapsed(), isFalse);

        // collapse all nodes individually
        store.collapseNode(
          store.getNodeByKey('firstClassField.innerClassField'),
        );
        store.collapseNode(
          store.getNodeByKey(
            'firstClassField.innerClassField',
            lastWhere: true,
          ),
        );
        store.collapseNode(
          store.getNodeByKey('secondClassField.innerClassField'),
        );
        store.collapseNode(
          store.getNodeByKey(
            'secondClassField.innerClassField',
            lastWhere: true,
          ),
        );
        store.collapseNode(store.getNodeByKey('firstClass.firstClassField'));
        store.collapseNode(store.getNodeByKey('firstClass.secondClassField'));
        store.collapseNode(store.getNodeByKey('secondClass.firstClassField'));
        store.collapseNode(store.getNodeByKey('secondClass.secondClassField'));
        store.collapseNode(store.getNodeByKey('firstClass.array'));
        store.collapseNode(store.getNodeByKey('secondClass.array'));
        store.collapseNode(store.getNodeByKey('firstClass'));
        store.collapseNode(store.getNodeByKey('secondClass'));

        expect(store.areAllCollapsed(), isTrue);

        // expand a node
        store.expandNode(store.getNodeByKey('secondClass'));

        expect(store.areAllCollapsed(), isFalse);
      });
    });

    group('areAllExpanded', () {
      test('works properly when nodes are built with isAllCollapsed as false',
          () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: false);

        expect(store.areAllExpanded(), isTrue);
      });

      test('works properly when nodes are built with isAllCollapsed as true',
          () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: true);

        expect(store.areAllExpanded(), isFalse);
      });

      test('works properly when expanding each node individually', () {
        final store = DataExplorerStore();
        store.buildNodes(json.decode(testJson), isAllCollapsed: true);

        expect(store.areAllExpanded(), isFalse);

        // expand all nodes individually
        store.expandNode(store.getNodeByKey('firstClass'));
        store.expandNode(store.getNodeByKey('firstClass.firstClassField'));
        store.expandNode(store.getNodeByKey('firstClassField.innerClassField'));
        store.expandNode(store.getNodeByKey('firstClass.secondClassField'));
        store.expandNode(
          store.getNodeByKey('secondClassField.innerClassField'),
        );
        store.expandNode(store.getNodeByKey('firstClass.array'));
        store.expandNode(store.getNodeByKey('secondClass'));
        store.expandNode(store.getNodeByKey('secondClass.firstClassField'));
        store.expandNode(
          store.getNodeByKey(
            'firstClassField.innerClassField',
            lastWhere: true,
          ),
        );
        store.expandNode(store.getNodeByKey('secondClass.secondClassField'));
        store.expandNode(
          store.getNodeByKey(
            'secondClassField.innerClassField',
            lastWhere: true,
          ),
        );
        store.expandNode(store.getNodeByKey('secondClass.array'));

        expect(store.areAllExpanded(), isTrue);

        // collapse a node
        store.collapseNode(store
            .getNodeByKey('secondClassField.innerClassField', lastWhere: true));

        expect(store.areAllExpanded(), isFalse);
      });
    });
  });
}

extension on DataExplorerStore {
  NodeViewModelState getNodeByKey(String key, {bool lastWhere = false}) {
    if (lastWhere) {
      return displayNodes.lastWhere((node) => node.key == key);
    }

    return displayNodes.firstWhere((node) => node.key == key);
  }
}
