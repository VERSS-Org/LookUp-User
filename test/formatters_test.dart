import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/src/utils/formatters.dart';

void main() {
  group('salaryLabel', () {
    test('muestra rango con moneda', () {
      expect(
        salaryLabel({
          'salario_min': 4000,
          'salario_max': 7000,
          'moneda': 'PEN',
        }),
        '4,000 - 7,000 PEN',
      );
    });

    test('muestra un solo valor si falta el otro', () {
      expect(salaryLabel({'salario_min': 2500, 'moneda': 'PEN'}), '2,500 PEN');
      expect(salaryLabel({'salario_max': 9000, 'moneda': 'USD'}), '9,000 USD');
    });

    test('sin datos indica salario a convenir', () {
      expect(salaryLabel({}), 'Salario a convenir');
    });

    test('separa miles en montos grandes', () {
      expect(
        salaryLabel({'salario_min': 1250000, 'moneda': 'PEN'}),
        '1,250,000 PEN',
      );
    });
  });

  group('strongPassword', () {
    test('acepta contrasena valida', () {
      expect(strongPassword('Postula123!'), isNull);
    });

    test('rechaza contrasenas debiles', () {
      expect(strongPassword('corta'), isNotNull);
      expect(strongPassword('sinmayuscula1!'), isNotNull);
      expect(strongPassword('SINMINUSCULA1!'), isNotNull);
      expect(strongPassword('SinNumero!!'), isNotNull);
      expect(strongPassword('SinSimbolo123'), isNotNull);
    });
  });

  group('contractLabel', () {
    test('traduce los tipos conocidos', () {
      expect(contractLabel('tiempo_completo'), 'Tiempo completo');
      expect(contractLabel('practicas'), 'Practicas');
    });

    test('maneja valores nulos o desconocidos', () {
      expect(contractLabel(null), 'Contrato no especificado');
      expect(contractLabel('otro_tipo'), 'otro tipo');
    });
  });

  group('formatDate', () {
    test('formatea fechas ISO', () {
      expect(formatDate('2026-07-09T10:30:00'), '09/07/2026');
    });

    test('devuelve vacio para nulos', () {
      expect(formatDate(null), '');
    });
  });

  group('asMap / asMapList', () {
    test('convierte estructuras dinamicas', () {
      expect(asMap({'a': 1}), {'a': 1});
      expect(asMap('no-map'), isEmpty);
      expect(
        asMapList([
          {'a': 1},
          {'b': 2},
        ]).length,
        2,
      );
      expect(asMapList('no-list'), isEmpty);
    });
  });
}
