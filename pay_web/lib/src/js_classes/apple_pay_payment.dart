import 'dart:js_interop';

extension type ApplePayPaymentAuthorizedEvent._(JSObject _) implements JSObject {
  external ApplePayPayment payment;
}

extension type ApplePayPayment._(JSObject _) implements JSObject {
  external ApplePayPaymentToken token;
  external ApplePayPaymentContact billingContact;
  external ApplePayPaymentContact shippingContact;

  Map<String, dynamic> toJson() {
    return {
      'token': token.toJson(),
      'billingContact': billingContact.toJson(),
      'shippingContact': shippingContact.toJson(),
    };
  }
}

extension type ApplePayPaymentToken._(JSObject _) implements JSObject {
  external ApplePayPaymentMethod paymentMethod;
  external String transactionIdentifier;
  external ApplePayPaymentData paymentData;

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod.toJson(),
      'transactionIdentifier': transactionIdentifier,
      'paymentData': paymentData.toJson(),
    };
  }
}

extension type ApplePayPaymentMethod._(JSObject _) implements JSObject {
  external String displayName;
  external String network;
  external String type;
  external String paymentPass;
  external String billingContact;

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'network': network,
      'type': type,
      'paymentPass': paymentPass,
      'billingContact': billingContact,
    };
  }
}

extension type ApplePayPaymentData._(JSObject _) implements JSObject {
  external String data;
  external ApplePayPaymentDataHeader header;
  external String signature;
  external String version;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'data': data,
      'signature': signature,
      'header': header.toJson(),
    };
  }
}

extension type ApplePayPaymentDataHeader._(JSObject _) implements JSObject {
  external String ephemeralPublicKey;
  external String wrappedKey;
  external String publicKeyHash;
  external String transactionId;

  Map<String, dynamic> toJson() {
    return {
      'ephemeralPublicKey': ephemeralPublicKey,
      'wrappedKey': wrappedKey,
      'publicKeyHash': publicKeyHash,
      'transactionId': transactionId,
    };
  }
}

extension type ApplePayPaymentContact._(JSObject _) implements JSObject {
  external String phoneNumber;
  external String emailAddress;
  external String givenName;
  external String familyName;
  external String phoneticGivenName;
  external String phoneticFamilyName;
  external JSArray<JSString> addressLines;
  external String subLocality;
  external String locality;
  external String postalCode;
  external String subAdministrativeArea;
  external String administrativeArea;
  external String country;
  external String countryCode;

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'givenName': givenName,
      'familyName': familyName,
      'phoneticGivenName': phoneticGivenName,
      'phoneticFamilyName': phoneticFamilyName,
      'addressLines': addressLines.toDart.map((e) => e.toDart).toList(),
      'subLocality': subLocality,
      'locality': locality,
      'postalCode': postalCode,
      'subAdministrativeArea': subAdministrativeArea,
      'administrativeArea': administrativeArea,
      'country': country,
      'countryCode': countryCode,
    };
  }
}
