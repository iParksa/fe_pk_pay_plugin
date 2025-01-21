import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';

export 'src/pay_web_stub.dart' if (dart.library.html) 'src/pay_web.dart';

part 'src/widgets/google_pay_button.dart';
part 'src/widgets/apple_pay_button.dart';
