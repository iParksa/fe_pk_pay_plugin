class ApplePayClassData {
  final String data;
  final ApplePayClassDataHeader header;
  final String signature;
  final String version;

  ApplePayClassData({
    required this.data,
    required this.header,
    required this.signature,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': {
        'data': data,
        'signature': signature,
        'header': header.toJson(),
        'version': version,
      }
    };
  }

  factory ApplePayClassData.fromJson(Map<String, dynamic> json) {
    return ApplePayClassData(
      data: json['data'] as String,
      header: ApplePayClassDataHeader.fromJson(json['header'] as Map<String, dynamic>),
      signature: json['signature'] as String,
      version: json['version'] as String,
    );
  }
}

class ApplePayClassDataHeader {
  final String ephemeralPublicKey;
  final String publicKeyHash;
  final String transactionId;

  ApplePayClassDataHeader({
    required this.ephemeralPublicKey,
    required this.publicKeyHash,
    required this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ephemeralPublicKey': ephemeralPublicKey,
      'publicKeyHash': publicKeyHash,
      'transactionId': transactionId,
    };
  }

  factory ApplePayClassDataHeader.fromJson(Map<String, dynamic> json) {
    return ApplePayClassDataHeader(
      ephemeralPublicKey: json['ephemeralPublicKey'] as String,
      publicKeyHash: json['publicKeyHash'] as String,
      transactionId: json['transactionId'] as String,
    );
  }
}
