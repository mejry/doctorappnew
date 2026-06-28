import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/appointment/models/appointment.dart';

void main() {
  test('Appointment parses patientId from JSON', () {
    final appointment = Appointment.fromJson({
      '_id': 'a1',
      'patientId': 'p123',
      'patientName': 'John Doe',
      'doctorId': 'd1',
      'doctorName': 'Dr. Smith',
      'date': '2026-01-01T00:00:00.000Z',
      'time': '09:00',
      'type': 'Consultation',
    });

    expect(appointment.patientId, 'p123');
  });
}
