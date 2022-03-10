import 'package:alexa_clean_the_kitchen/models/backend_response.dart';
import 'package:alexa_clean_the_kitchen/ResourceFetcher.dart';
import 'package:test/test.dart';

void main() {
  test('Counter value should be incremented', () {
    final Future<Function> response = ResourceFetcher.syncBackendWithDevice();

    expect(response, completion(isA<BackendResponse>() ));
  });
}