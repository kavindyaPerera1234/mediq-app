import 'package:flutter_test/flutter_test.dart';
import 'package:mediq_app/core/utils/app_validators.dart';

void main() {
  group('NIC Validation (Sri Lankan Format - Old & New)', () {
    test('Valid 12-digit new NIC passes', () {
      expect(AppValidators.validateNic('200112345678'), isNull);
      expect(AppValidators.validateNic('199923456789'), isNull);
    });

    test('Valid 9-digit + V/X old NIC passes', () {
      expect(AppValidators.validateNic('991234567V'), isNull);
      expect(AppValidators.validateNic('991234567v'), isNull);
      expect(AppValidators.validateNic('851234567X'), isNull);
    });

    test('Invalid NIC fails with descriptive message', () {
      expect(AppValidators.validateNic('', required: true), 'National ID (NIC) is required');
      expect(AppValidators.validateNic('12345'), 'NIC must be either 10 characters (Old) or 12 digits (New)');
      expect(AppValidators.validateNic('1234567890123'), 'NIC must be either 10 characters (Old) or 12 digits (New)');
      expect(AppValidators.validateNic('991234567A'), contains('Invalid Sri Lankan NIC format'));
      expect(AppValidators.validateNic('20011234567A'), contains('Invalid Sri Lankan NIC format'));
    });
  });

  group('Phone Number Validation (10 Digits)', () {
    test('Valid 10-digit Sri Lankan phone passes', () {
      expect(AppValidators.validatePhone('0712345678'), isNull);
      expect(AppValidators.validatePhone('0771234567'), isNull);
      expect(AppValidators.validatePhone('0112345678'), isNull);
    });

    test('Valid formatted +94 phone passes', () {
      expect(AppValidators.validatePhone('+94 77 123 4567'), isNull);
    });

    test('Invalid phone number fails', () {
      expect(AppValidators.validatePhone(''), 'Phone number is required');
      expect(AppValidators.validatePhone('071234'), contains('must be exactly 10 digits'));
      expect(AppValidators.validatePhone('071234567899'), contains('must be exactly 10 digits'));
    });
  });

  group('Dual Phone or Email Validation (Patient Login)', () {
    test('Valid phone numbers pass', () {
      expect(AppValidators.validatePhoneOrEmail('0771234567'), isNull);
      expect(AppValidators.validatePhoneOrEmail('+94771234567'), isNull);
    });

    test('Valid email addresses pass', () {
      expect(AppValidators.validatePhoneOrEmail('patient@mediq.lk'), isNull);
      expect(AppValidators.validatePhoneOrEmail('user@gmail.com'), isNull);
    });

    test('Invalid phone or email fails with helpful guidance', () {
      expect(AppValidators.validatePhoneOrEmail(''), 'Please enter your phone number or email');
      expect(AppValidators.validatePhoneOrEmail('2222222222'), contains('Phone number must start with 0'));
      expect(AppValidators.validatePhoneOrEmail('071234'), contains('must be exactly 10 digits'));
      expect(AppValidators.validatePhoneOrEmail('bad-email@'), contains('valid email address'));
    });
  });

  group('Age Validation (2 Digits: 1 - 99)', () {
    test('Valid 2-digit age passes', () {
      expect(AppValidators.validateAge('23'), isNull);
      expect(AppValidators.validateAge('1'), isNull);
      expect(AppValidators.validateAge('99'), isNull);
    });

    test('Invalid age fails', () {
      expect(AppValidators.validateAge(''), 'Age is required');
      expect(AppValidators.validateAge('0'), contains('between 1 and 99'));
      expect(AppValidators.validateAge('100'), contains('cannot exceed 2 digits'));
      expect(AppValidators.validateAge('abc'), 'Please enter a valid numeric age');
    });
  });

  group('Full Name Validation', () {
    test('Valid names pass', () {
      expect(AppValidators.validateFullName('Sunil Perera'), isNull);
      expect(AppValidators.validateFullName('Dr. K. Silva'), isNull);
      expect(AppValidators.validateFullName("Mary-Jane O'Connor"), isNull);
    });

    test('Invalid names fail', () {
      expect(AppValidators.validateFullName(''), 'Full name is required');
      expect(AppValidators.validateFullName('A'), 'Name must be at least 2 characters');
      expect(AppValidators.validateFullName('John123'), 'Name can only contain alphabetic letters and spaces');
    });
  });

  group('Service Layer Assertions (assertValid)', () {
    test('assertValid throws ArgumentError on invalid input', () {
      expect(
        () => AppValidators.assertValid(nic: '12345'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AppValidators.assertValid(phone: '071'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AppValidators.assertValid(age: 105),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AppValidators.assertValid(fullName: '1234'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('assertValid passes silently on valid input', () {
      expect(
        () => AppValidators.assertValid(
          fullName: 'Sunil Perera',
          phone: '0771234567',
          nic: '200112345678',
          age: 25,
        ),
        returnsNormally,
      );
    });
  });
}
