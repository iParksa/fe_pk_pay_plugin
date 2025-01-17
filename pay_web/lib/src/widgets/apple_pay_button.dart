part of '../../pay_web.dart';

/// The types of button supported on Apple Pay.
///
/// See the [PKPaymentButtonType](https://developer.apple.com/documentation/passkit/pkpaymentbuttontype)
/// class in the Apple Pay documentation to learn more.
enum ApplePayButtonTypeWeb {
  plain,
  buy,
  setUp,
  inStore,
  donate,
  checkout,
  book,
  subscribe,
  reload,
  addMoney,
  topUp,
  order,
  rent,
  support,
  contribute,
  tip
}

/// The button styles supported on Apple Pay.
///
/// See the [PKPaymentButtonStyle](https://developer.apple.com/documentation/passkit/pkpaymentbuttonstyle)
/// class in the Apple Pay documentation to learn more.
enum ApplePayButtonStyleWeb {
  white,
  whiteOutline,
  black,
  automatic,
}

/// A set of utility methods associated to the [ApplePayButtonTypeWeb] enumeration.
extension on ApplePayButtonTypeWeb {
  /// The minimum width for this button type according to
  /// [Apple Pay's Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/apple-pay/overview/buttons-and-marks/)
  /// for the button.
  double get minimumAssetWidth => this == ApplePayButtonTypeWeb.plain ? 100 : 140;
}

/// A button widget that follows the Apple Pay button styles and design
/// guidelines.
///
/// This widget is a representation of the Apple Pay button in Flutter. The
/// button is drawn natively through a [PlatformView] and sent back to the UI
/// element tree in Flutter. The button features all the labels, and styles
/// available, and can be used independently as a standalone component.
///
/// To use this button independently, simply add it to your layout:
/// ```dart
/// RawApplePayButton(
///   style: ApplePayButtonStyleWeb.black,
///   type: ApplePayButtonTypeWeb.buy,
///   onPressed: () => print('Button pressed'));
/// ```
class RawApplePayButtonWeb extends StatelessWidget {
  /// The default width for the Apple Pay Button.
  static const double minimumButtonWidth = 100;

  /// The default height for the Apple Pay Button.
  static const double minimumButtonHeight = 30;

  /// The constraints used to limit the size of the button.
  final BoxConstraints constraints;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// The style of the Apple Pay button, to be adjusted based on the color
  /// scheme of the application.
  final ApplePayButtonStyleWeb style;

  /// The type of button depending on the activity initiated with the payment
  /// transaction.
  final ApplePayButtonTypeWeb type;

  /// The amount of roundness applied to the corners of the button.
  final double? cornerRadius;

  /// Creates an Apple Pay button widget with the parameters specified.
  RawApplePayButtonWeb({
    super.key,
    this.onPressed,
    this.style = ApplePayButtonStyleWeb.black,
    this.type = ApplePayButtonTypeWeb.plain,
    this.cornerRadius,
  }) : constraints = BoxConstraints.tightFor(
          width: type.minimumAssetWidth,
          height: minimumButtonHeight,
        ) {
    assert(constraints.debugAssertIsValid());
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: constraints,
      child: _platformButton,
    );
  }

  /// Wrapper method to deliver the button only to applications running on Web.
  Widget get _platformButton {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        decoration: BoxDecoration(
          color: style == ApplePayButtonStyleWeb.black ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(cornerRadius?.toDouble() ?? 1),
        ),
        child: Center(
          child: Text(
            'Comprar con Apple Pay',
            style: TextStyle(
              color: style == ApplePayButtonStyleWeb.black ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  static bool get supported =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
}
