// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of '../../pay.dart';

/// A widget to show the Apple Pay button according to the rules and constraints
/// specified in [PayButton].
///
/// Example usage:
/// ```dart
/// ApplePayButton(
///   paymentConfiguration: _paymentConfiguration,
///   paymentItems: _paymentItems,
///   style: ApplePayButtonStyle.black,
///   type: ApplePayButtonType.buy,
///   margin: const EdgeInsets.only(top: 15.0),
///   onPaymentResult: onApplePayResult,
///   loadingIndicator: const Center(
///     child: CircularProgressIndicator(),
///   ),
/// )
/// ```
class ApplePayButton extends PayButton {
  late final Widget _applePayButton;

  ApplePayButton({
    super.key,
    super.buttonProvider = PayProvider.apple_pay,
    required super.paymentConfiguration,
    super.onPaymentResult,
    required List<PaymentItem> paymentItems,
    String? applePayWebMerchantValidationUrl,
    double cornerRadius =
        (kIsWeb ? RawGooglePayButtonWeb.defaultButtonHeight : RawGooglePayButton.defaultButtonHeight) / 2,
    ApplePayButtonStyle style = ApplePayButtonStyle.black,
    ApplePayButtonStyleWeb styleWeb = ApplePayButtonStyleWeb.black,
    ApplePayButtonType type = ApplePayButtonType.plain,
    ApplePayButtonTypeWeb typeWeb = ApplePayButtonTypeWeb.plain,
    super.width = kIsWeb ? RawApplePayButtonWeb.minimumButtonWidth : RawApplePayButton.minimumButtonWidth,
    super.height = kIsWeb ? RawApplePayButtonWeb.defaultButtonHeight : RawApplePayButton.minimumButtonHeight,
    super.margin = EdgeInsets.zero,
    Future<bool> Function()? beforePay,
    super.onError,
    super.childOnError,
    super.loadingIndicator,
  })  : assert(width >= RawApplePayButton.minimumButtonWidth),
        assert(height >= RawApplePayButton.minimumButtonHeight) {
    _applePayButton = kIsWeb
        ? RawApplePayButtonWeb(
            style: styleWeb,
            type: typeWeb,
            cornerRadius: cornerRadius,
            onPressed: _defaultOnPressed(beforePay, paymentItems))
        : RawApplePayButton(
            style: style,
            type: type,
            cornerRadius: cornerRadius,
            onPressed: _defaultOnPressed(beforePay, paymentItems));
  }

  @override
  final List<TargetPlatform> _supportedPlatforms = [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux
  ];

  @override
  late final Widget _payButton = _applePayButton;

  @override
  final bool _collectPaymentResultSynchronously = true;
}
