import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:pay_platform_interface/pay_platform_interface.dart';
import 'dart:js' as js;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:dio/dio.dart';

class PayWebPlugin extends PayPlatform {
  static void registerWith(Registrar registrar) {
    PayPlatform.instance = PayWebPlugin();
  }

  late final bool _googlePaymentsAvailable;
  late final bool _applePaymentsAvailable;

  PayWebPlugin() {
    _initializePaymentsClients();
  }

  @override
  Future<bool> userCanPay(PaymentConfiguration paymentConfiguration) async {
    try {
      switch (paymentConfiguration.provider) {
        case PayProvider.google_pay:
          return _userCanPayGoogle(paymentConfiguration);
        case PayProvider.apple_pay:
          return _userCanPayApple(paymentConfiguration);
      }
    } catch (e) {
      debugPrint('Error checking userCanPay: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> showPaymentSelector(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) async {
    switch (paymentConfiguration.provider) {
      case PayProvider.google_pay:
        return _showPaymentSelectorGoogle(paymentConfiguration, paymentItems);
      case PayProvider.apple_pay:
        return _showPaymentSelectorApple(paymentConfiguration, paymentItems);
    }
  }

  Map<String, dynamic> _convertJsObjectToDart(js.JsObject jsObject) {
    final dartMap = <String, dynamic>{};

    final keys = js.context['Object'].callMethod('keys', [jsObject]) as List;
    for (final key in keys) {
      final value = jsObject[key as String];

      // Recursively handle nested JsObjects
      if (value is js.JsObject) {
        dartMap[key] = _convertJsObjectToDart(value);
      } else {
        dartMap[key] = value; // Directly assign primitive values
      }
    }

    return dartMap;
  }

  Future<void> _initializePaymentsClients() async {
    // Google
    if (js.context['google'] != null &&
        js.context['google']['payments'] != null &&
        js.context['google']['payments']['api'] != null &&
        js.context['google']['payments']['api']['PaymentsClient'] != null) {
      // final environment = js.JsObject.jsify({'environment': 'TEST'});
      _googlePaymentsAvailable = true;
      debugPrint('Google Pay API is available.');
    } else {
      _googlePaymentsAvailable = false;
      debugPrint('Google Pay API is not available.');
    }

    // Apple
    if (js.context['ApplePaySession'] != null) {
      _applePaymentsAvailable = true;
      debugPrint('Apple Pay API is available.');
    } else {
      _applePaymentsAvailable = false;
      debugPrint('Apple Pay API is not available.');
    }
  }

  Future<bool> _userCanPayGoogle(PaymentConfiguration paymentConfiguration) async {
    try {
      if (_googlePaymentsAvailable) {
        final payConfigMap = await paymentConfiguration.parameterMap();
        final request = js.JsObject.jsify(payConfigMap);

        final environment = js.JsObject.jsify(
            {'environment': payConfigMap.containsKey('environment') ? payConfigMap['environment'] : 'TEST'});

        final client = js.JsObject(
          js.context['google']['payments']['api']['PaymentsClient'] as js.JsFunction,
          [environment],
        );

        final jsPromise = client.callMethod('isReadyToPay', [request]);
        Completer<bool> completer = Completer<bool>();

        //Handle the promise using `.then()` in Dart
        jsPromise.callMethod('then', [
          js.allowInterop((result) {
            completer.complete(result['result'] == true);
          }),
        ]);

        // Optionally, you can handle rejection using `.catch()`
        jsPromise.callMethod('catch', [
          js.allowInterop((error) {
            debugPrint("Promise rejected with error: $error");
            completer.complete(false);
          }),
        ]);

        return completer.future;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking userCanPayGoogle: $e');
      return false;
    }
  }

  Future<bool> _userCanPayApple(PaymentConfiguration paymentConfiguration) async {
    try {
      if (_applePaymentsAvailable) {
        final client = js.context['ApplePaySession'] as js.JsObject;

        final canMakePayments = client.callMethod('canMakePayments');

        return canMakePayments == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking userCanPayApple: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _showPaymentSelectorGoogle(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) async {
    if (!_googlePaymentsAvailable) {
      throw Exception('Google Pay API is not available.');
    }

    try {
      // Build the transactionInfo object from the provided paymentItems
      final transactionInfo = {
        'totalPriceStatus': 'FINAL', // Indicates the total price is final
        'totalPrice': paymentItems
            .fold<double>(0.0, (sum, item) => sum + (double.tryParse(item.amount) ?? 0.0))
            .toStringAsFixed(2), // Calculate the total price
      };

      final paymentDataRequest = await paymentConfiguration.parameterMap();
      if (!paymentDataRequest.containsKey('transactionInfo')) {
        paymentDataRequest['transactionInfo'] = transactionInfo;
      } else {
        (paymentDataRequest['transactionInfo'] as Map<String, dynamic>).addAll(transactionInfo);
      }

      final environment = js.JsObject.jsify(
          {'environment': paymentDataRequest.containsKey('environment') ? paymentDataRequest['environment'] : 'TEST'});

      final client = js.JsObject(
        js.context['google']['payments']['api']['PaymentsClient'] as js.JsFunction,
        [environment],
      );

      // Call the `loadPaymentData` method
      final jsPromise = client.callMethod('loadPaymentData', [js.JsObject.jsify(paymentDataRequest)]);

      // Handle the promise using a completer
      Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

      jsPromise.callMethod('then', [
        js.allowInterop((paymentData) {
          final result = _convertJsObjectToDart(paymentData as js.JsObject);
          debugPrint(result.toString());
          completer.complete(Map<String, dynamic>.from(result));
        }),
      ]);

      jsPromise.callMethod('catch', [
        js.allowInterop((error) {
          debugPrint("Payment data request failed: $error");
          completer.completeError(error as Object);
        }),
      ]);

      return completer.future;
    } catch (e) {
      debugPrint('Error in showPaymentSelector: $e');
      throw Exception('Failed to show payment selector: $e');
    }
  }

  Future<Map<String, dynamic>> _showPaymentSelectorApple(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) async {
    if (!_applePaymentsAvailable) {
      throw Exception('Apple Pay JS API is not available.');
    }

    try {
      final paymentRequest = await paymentConfiguration.parameterMap();

      if (!paymentRequest.containsKey('webMerchantValidationUrl')) {
        throw Exception('Apple Pay configurations must include a validationURL.');
      }

      final paramsData = {
        "merchantCapabilities": ["supports3DS", "supportsCredit", "supportsDebit"],
        "supportedNetworks": paymentRequest["supportedNetworks"],
        "countryCode": paymentRequest["countryCode"], // Codi de país
        "currencyCode": paymentRequest["currencyCode"], // Codi de moneda
        "total": {
          'label': paymentItems.first.label,
          'amount': paymentItems
              .fold<double>(0.0, (sum, item) => sum + (double.tryParse(item.amount) ?? 0.0))
              .toStringAsFixed(2),
        }
      };
      //debugPrint(paramsData.toString());
      final paymentDataRequest = js.JsObject.jsify(paramsData);

      // Initialize the ApplePaySession
      final session = js.JsObject(js.context['ApplePaySession'] as js.JsFunction, [3, paymentDataRequest]);

      // Completer to handle the payment flow
      Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

      // Add event handlers
      session['onvalidatemerchant'] = js.allowInterop((event) async {
        try {
          final validationUrl = js.JsObject.fromBrowserObject(event as js.JsObject)['validationURL'] as String?;
          final merchantSession = await _validateMerchant(paymentRequest, validationUrl);
          session.callMethod('completeMerchantValidation', [merchantSession]);
        } catch (error) {
          debugPrint('Error in onvalidatemerchant: $error');
          session.callMethod('abort');
          completer.completeError(Exception('Merchant validation failed: $error'));
        }
      });

      session['onpaymentauthorized'] = js.allowInterop((event) async {
        try {
          final result = js.JsObject.jsify({'status': session['STATUS_SUCCESS']});
          session.callMethod('completePayment', [result]);

          js.context.callMethod('alert', [event.payment.token.toJson().toString()]);

          //completer.complete(event.payment.token.toJson());
          completer.complete({"ok": true, "data": event.payment.token.toJson()});
        } catch (e) {
          debugPrint('Error in onpaymentauthorized: $e');
          session.callMethod('abort');
          completer.completeError(Exception('Payment authorized failed: $e'));
        }
      });

      session['oncancel'] = js.allowInterop((event) {
        debugPrint('Apple Pay session was cancelled by the user.');
        completer.completeError(Exception('Payment cancelled by user'));
      });

      // Begin the session
      session.callMethod('begin');
      return completer.future;
    } catch (e) {
      debugPrint('Error in showPaymentSelector for Apple Pay: $e');
      throw Exception('Failed to show Apple Pay payment selector: $e');
    }
  }

  Future<js.JsObject> _validateMerchant(Map<String, dynamic> params, String? validationUrl) async {
    final dio = Dio();
    final response = await dio.post<Map<String, dynamic>>(params["webMerchantValidationUrl"].toString(), data: {
      'validationUrl': validationUrl,
      'merchantIdentifier': params["merchantIdentifier"],
      'displayName': params["displayName"],
      'initiative': 'web',
      'initiativeContext': params["webMerchantDomain"],
    });

    if (response.statusCode == 200 && response.data != null) {
      return js.JsObject.jsify(response.data!);
    } else {
      debugPrint('Merchant validation failed: ${response.statusCode} - ${response.data}');
      throw Exception('Merchant validation failed: ${response.data}');
    }
  }
}
