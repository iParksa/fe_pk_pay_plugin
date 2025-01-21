import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
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

  late final js.JsObject? _googlePaymentsClient;
  late final js.JsObject? _applePaymentsClient;

  PayWebPlugin() {
    _initializePaymentsClients();
  }

  Future<void> _initializePaymentsClients() async {
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
      debugPrint('Google paymentsClient initialized successfully.');
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
    try {
      if (_applePaymentsClient != null) {
        final canMakePayments = _applePaymentsClient!.callMethod('canMakePayments');

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

  Future<Map<String, dynamic>> _showPaymentSelectorApple(
      PaymentConfiguration paymentConfiguration, List<PaymentItem> paymentItems) async {
    if (_applePaymentsClient == null) {
      throw Exception('Apple Pay JS API is not available.');
    }

    try {
      // Convert PaymentItems to Apple Pay line items
      final lineItems = paymentItems.map((item) {
        return {
          'label': item.label,
          'amount': item.amount,
        };
      }).toList();

      // Create the payment request object
      final paymentRequest = js.JsObject.jsify({
        'countryCode': 'ES',
        'currencyCode': 'EUR',
        'merchantCapabilities': ['supports3DS'], // Add other capabilities as needed
        'supportedNetworks': ['amex', 'discover', 'masterCard', 'visa'], // Customize as needed
        'total': {
          'label': 'Test',
          'type': 'final',
          'amount': paymentItems
              .fold<double>(0.0, (sum, item) => sum + (double.tryParse(item.amount) ?? 0.0))
              .toStringAsFixed(2),
        },
        'lineItems': js.JsObject.jsify(lineItems),
      });

      // Initialize the ApplePaySession
      final session = js.JsObject(
        _applePaymentsClient as js.JsFunction,
        [3, paymentRequest], // Apple Pay API version (3) and request object
      );

      // Completer to handle the payment flow
      Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

      // Add event handlers
      session['onvalidatemerchant'] = js.allowInterop((event) async {
        debugPrint('onvalidatemerchant event triggered');
        try {
          final validationUrl = ((event as JSObject).getProperty('validationURL'.toJS) as JSString).toDart;
          final merchantSession = await _validateMerchant(validationUrl);
          session.callMethod('completeMerchantValidation', [merchantSession]);
        } catch (error) {
          session.callMethod('abort');
          completer.completeError(Exception('Merchant validation failed: $error'));
        }
      });

      // session['onpaymentmethodselected'] = js.allowInterop((event) {
      //   debugPrint('onpaymentmethodselected event triggered');
      //   final update = js.JsObject.jsify({});
      //   session.callMethod('completePaymentMethodSelection', [update]);
      // });

      // session['onshippingmethodselected'] = js.allowInterop((event) {
      //   debugPrint('onshippingmethodselected event triggered');
      //   final update = js.JsObject.jsify({});
      //   session.callMethod('completeShippingMethodSelection', [update]);
      // });

      // session['onshippingcontactselected'] = js.allowInterop((event) {
      //   debugPrint('onshippingcontactselected event triggered');
      //   final update = js.JsObject.jsify({});
      //   session.callMethod('completeShippingContactSelection', [update]);
      // });

      // session['oncouponcodechanged'] = js.allowInterop((event) {
      //   debugPrint('oncouponcodechanged event triggered');

      //   final update = js.JsObject.jsify({});
      //   session.callMethod('completeCouponCodeChange', [update]);
      // });

      session['onpaymentauthorized'] = js.allowInterop((event) async {
        debugPrint('onpaymentauthorized event triggered');
        final result = js.JsObject.jsify({
          'status': _applePaymentsClient!['STATUS_SUCCESS'],
        });
        session.callMethod('completePayment', [result]);

        if (event is JSPromise) {
          final paymentData = await event.toDart;
          if (paymentData.isA<JSArray>()) {
            js.context.callMethod('alert', ['Payment data is an array']);
          } else if (paymentData.isA<JSFunction>()) {
            js.context.callMethod('alert', ['Payment data is a function']);
          } else if (paymentData.isA<JSDataView>()) {
            js.context.callMethod('alert', ['Payment data is a DataView']);
          } else if (paymentData.isA<JSObject>()) {
            js.context.callMethod('alert', ['Payment data is an object']);
          } else {
            js.context.callMethod('alert', ['Payment data is: $paymentData']);
          }
        }
        completer.complete({});
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

  Future<js.JsObject> _validateMerchant(String? validationUrl) async {
    const String applePayWebMerchantValidationUrl =
        'https://r248zsz3-7021.uks1.devtunnels.ms/api/Cajero/ApplePayMerchantValidation';

    final dio = Dio();
    final response = await dio.post<Map<String, dynamic>>(applePayWebMerchantValidationUrl, data: {
      'validationUrl': validationUrl,
      'merchantIdentifier': 'merchant.com.meypar.qrpay',
      'displayName': 'Meypar QR Pay',
      'initiative': 'web',
      'initiativeContext': 'g1bt2wq4-8080.uks1.devtunnels.ms'
    });

    if (response.statusCode == 200 && response.data != null) {
      return js.JsObject.jsify(response.data!);
    } else {
      throw Exception('Merchant validation failed: ${response.data}');
    }
  }
}
