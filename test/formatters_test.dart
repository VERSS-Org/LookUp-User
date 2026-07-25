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

  group('jobLocationLabel', () {
    test('elimina la modalidad remota duplicada y conserva la cobertura', () {
      expect(
        jobLocationLabel({
          'ubicacion': 'Remoto · Latinoamérica',
          'modalidad': 'remoto',
        }),
        'Latinoamérica',
      );
    });

    test('conserva la ciudad física y elimina partes repetidas', () {
      expect(
        jobLocationLabel({
          'ubicacion': 'San Isidro, Lima · Presencial · San Isidro, Lima',
          'modalidad': 'presencial',
        }),
        'San Isidro, Lima',
      );
    });

    test('admite guion y coma como separadores legacy de modalidad', () {
      expect(
        jobLocationLabel({
          'ubicacion': 'Remoto - Latinoamérica',
          'modalidad': 'remoto',
        }),
        'Latinoamérica',
      );
      expect(
        jobLocationLabel({
          'ubicacion': 'Remoto, Latinoamérica',
          'modalidad': 'remoto',
        }),
        'Latinoamérica',
      );
    });

    test('reconoce En remoto e Híbrida sin eliminar la ciudad', () {
      expect(
        jobLocationLabel({'ubicacion': 'En remoto', 'modalidad': 'remoto'}),
        isEmpty,
      );
      expect(
        jobLocationLabel({
          'ubicacion': 'Híbrida · Lima',
          'modalidad': 'hibrido',
        }),
        'Lima',
      );
      expect(
        jobLocationLabel({
          'ubicacion': 'Hibrida / San Isidro, Lima',
          'modalidad': 'hibrido',
        }),
        'San Isidro, Lima',
      );
    });

    test('no divide guiones internos de ubicaciones legítimas', () {
      expect(
        jobLocationLabel({
          'ubicacion': 'Lima-Callao',
          'modalidad': 'presencial',
        }),
        'Lima-Callao',
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
      expect(contractLabel('tiempo_completo'), 'Jornada Completa');
      expect(contractLabel('medio_tiempo'), 'Jornada Parcial');
      expect(contractLabel('practicas'), 'Prácticas Preprofesionales');
      expect(contractLabel('temporal'), 'Temporal');
    });

    test('mantiene compatibilidad con contratos legacy', () {
      expect(contractLabel('freelance'), 'Freelance');
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
