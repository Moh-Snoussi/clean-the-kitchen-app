/// Represent an error received from MIIO device.
class MiIoError implements Exception {
  final int code;
  final String message;

  MiIoError({
    this.code,
    this.message,
  });

  @override
  String toString() => 'MiIoError(code: $code, message: $message)';
}
