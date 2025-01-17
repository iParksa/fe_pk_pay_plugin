// File to use when not building for web
import 'package:flutter/foundation.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:pay_platform_interface/pay_platform_interface.dart';

class PayWebPlugin extends PayPlatform {
  PayWebPlugin();

  @override
  Future<Map<String, dynamic>> showPaymentSelector(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) {
    debugPrint('showPaymentSelectorStub');
    throw UnimplementedError();
  }

  @override
  Future<bool> userCanPay(PaymentConfiguration paymentConfiguration) async {
    debugPrint('userCanPayStub');
    throw UnimplementedError();
  }
}
