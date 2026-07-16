import 'dart:mirrors';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  var classMirror = reflectClass(GoogleSignIn);
  print('Class: ${classMirror.simpleName}');
  print('--- Constructors ---');
  classMirror.declarations.forEach((key, value) {
    if (value is MethodMirror && value.isConstructor) {
      print('Constructor: ${value.simpleName}');
    }
  });
  print('--- Methods ---');
  classMirror.declarations.forEach((key, value) {
    if (value is MethodMirror && !value.isConstructor) {
      print('Method: ${value.simpleName} (static: ${value.isStatic})');
    }
  });
}
