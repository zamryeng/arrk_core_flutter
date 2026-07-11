import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/navigation.dart';

void main() {
  group('ArrkRoute', () {
    test('toString returns the name', () {
      const route = ArrkRoute(name: 'home', path: '/home');
      expect(route.toString(), 'home');
    });

    test('name and path are stored correctly', () {
      const route = ArrkRoute(name: 'profile', path: '/profile');
      expect(route.name, 'profile');
      expect(route.path, '/profile');
    });

    test('queryParameters defaults to empty map', () {
      const route = ArrkRoute(name: 'splash', path: '/');
      expect(route.queryParameters, isEmpty);
    });

    test('pathParameters defaults to empty map', () {
      const route = ArrkRoute(name: 'splash', path: '/');
      expect(route.pathParameters, isEmpty);
    });

    test('explicit queryParameters are stored', () {
      const route = ArrkRoute(
        name: 'search',
        path: '/search',
        queryParameters: {'q': 'hello'},
      );
      expect(route.queryParameters['q'], 'hello');
    });

    test('explicit pathParameters are stored', () {
      const route = ArrkRoute(
        name: 'user',
        path: '/users/:id',
        pathParameters: {'id': '42'},
      );
      expect(route.pathParameters['id'], '42');
    });

    test('toString with path parameters still returns the name', () {
      const route = ArrkRoute(
        name: 'user-detail',
        path: '/users/:id',
        pathParameters: {'id': '99'},
      );
      expect(route.toString(), 'user-detail');
    });
  });
}
