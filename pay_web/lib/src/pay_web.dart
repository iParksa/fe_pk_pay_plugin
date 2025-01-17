import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pay_platform_interface/core/payment_configuration.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:pay_platform_interface/pay_platform_interface.dart';
import 'dart:js' as js;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class PayWebPlugin extends PayPlatform {
  static void registerWith(Registrar registrar) {
    PayPlatform.instance = PayWebPlugin();
  }

  late final js.JsObject? _googlePaymentsClient;
  late final js.JsObject? _applePaymentsClient;

  PayWebPlugin() {
    _initializePaymentsClients();
  }

  Future<void> _initializePaymentsClients() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Wait for api scripts to load

    // Google
    if (js.context['google'] != null &&
        js.context['google']['payments'] != null &&
        js.context['google']['payments']['api'] != null &&
        js.context['google']['payments']['api']['PaymentsClient'] != null) {
      // final environment = js.JsObject.jsify({'environment': 'TEST'});
      _googlePaymentsClient = js.JsObject(
        js.context['google']['payments']['api']['PaymentsClient'] as js.JsFunction,
        [js.JsObject.jsify({})],
      );
      debugPrint('PaymentsClient initialized successfully.');
    } else {
      debugPrint('Google Pay API is not available.');
      _googlePaymentsClient = null;
    }

    // Apple
    if (js.context['ApplePaySession'] != null) {
      _applePaymentsClient = js.context['ApplePaySession'] as js.JsObject?;
      debugPrint('Apple Pay API is available.');
    } else {
      debugPrint('Apple Pay API is not available.');
      _applePaymentsClient = null;
    }
  }

  @override
  Future<Map<String, dynamic>> showPaymentSelector(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) async {
    if (_googlePaymentsClient == null) {
      throw Exception('Google Pay API is not available or PaymentsClient is not initialized.');
    }

    try {
      // Build the transactionInfo object from the provided paymentItems
      final transactionInfo = {
        'countryCode': 'ES',
        'currencyCode': 'EUR',
        'totalPriceStatus': 'FINAL', // Indicates the total price is final
        'totalPrice': paymentItems
            .fold<double>(0.0, (sum, item) => sum + (double.tryParse(item.amount) ?? 0.0))
            .toStringAsFixed(2), // Calculate the total price
      };

      // Create the payment data request object
      final paymentDataRequest = js.JsObject.jsify({
        'apiVersion': 2,
        'apiVersionMinor': 0,
        'allowedPaymentMethods': [
          {
            'type': "CARD",
            'parameters': {
              'allowedAuthMethods': ["PAN_ONLY", "CRYPTOGRAM_3DS"],
              'allowedCardNetworks': ["AMEX", "DISCOVER", "INTERAC", "JCB", "MASTERCARD", "VISA"],
            },
            'tokenizationSpecification': {
              'type': 'PAYMENT_GATEWAY',
              'parameters': {
                'gateway': 'example',
                'gatewayMerchantId': 'gatewayMerchantId',
              }
            }
          }
        ],
        'transactionInfo': transactionInfo,
        'merchantInfo': {
          'merchantName': 'Example Merchant Name',
          // Optionally include merchantId if available for production
          // 'merchantId': paymentConfiguration.merchantId,
        }
      });

      // Call the `loadPaymentData` method
      final jsPromise = _googlePaymentsClient!.callMethod('loadPaymentData', [paymentDataRequest]);

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

  @override
  Future<bool> userCanPay(PaymentConfiguration paymentConfiguration) async {
    try {
      switch (paymentConfiguration.provider) {
        case PayProvider.google_pay:
          return _userCanPayGoogle(paymentConfiguration);
        case PayProvider.apple_pay:
          return _userCanPayApple(paymentConfiguration);
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking userCanPay: $e');
      return false;
    }
  }

  Future<bool> _userCanPayGoogle(PaymentConfiguration paymentConfiguration) async {
    try {
      if (_googlePaymentsClient != null) {
        // TODO: Sacarlo del paymentConfiguration y hacer el if de Google/Apple
        final request = js.JsObject.jsify({
          'allowedPaymentMethods': [
            {
              'type': "CARD",
              'parameters': {
                'allowedAuthMethods': ["PAN_ONLY", "CRYPTOGRAM_3DS"],
                'allowedCardNetworks': ["AMEX", "DISCOVER", "INTERAC", "JCB", "MASTERCARD", "VISA"]
              }
            }
          ],
          'apiVersion': 2,
          'apiVersionMinor': 0
        });

        final client = _googlePaymentsClient!;

        // final response = await js_util.promiseToFuture(client.callMethod('isReadyToPay', [request]) as Object);
        final jsPromise = client.callMethod('isReadyToPay', [request]);
        // Return a Dart Future that completes when the JavaScript promise resolves
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
    if (_applePaymentsClient != null) {
      // Call ApplePaySession.canMakePayments()
      final jsPromise = js.context['ApplePaySession'].callMethod('canMakePayments');

      // Handle the promise using a completer
      Completer<bool> completer = Completer<bool>();

      jsPromise.callMethod('then', [
        js.allowInterop((result) {
          debugPrint("Apple Pay canMakePayments result: $result");
          completer.complete(result == true); // Convert JS truthy to Dart boolean
        }),
      ]);

      jsPromise.callMethod('catch', [
        js.allowInterop((error) {
          debugPrint("Apple Pay canMakePayments failed: $error");
          completer.complete(false);
        }),
      ]);

      return completer.future;
    } else {
      return false;
    }
  }
}
