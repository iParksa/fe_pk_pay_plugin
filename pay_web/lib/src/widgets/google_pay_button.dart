part of '../../pay_web.dart';

/// The types of button supported on Google Pay.
enum GooglePayButtonTypeWeb { book, buy, checkout, donate, order, pay, plain, subscribe }

/// The button themes supported on Google Pay.
enum GooglePayButtonThemeWeb {
  dark,
  light,
}

/// A button widget that follows the Google Pay button themes and design
/// guidelines.
///
/// This widget is a representation of the Google Pay button in Flutter. The
/// button is drawn on the Flutter end using official assets, featuring all
/// the labels, and themes available, and can be used independently as a
/// standalone component.
///
/// To use this button independently, simply add it to your layout:
/// ```dart
/// RawGooglePayButton(
///   type: GooglePayButtonTypeWeb.pay,
///   onPressed: () => print('Button pressed'));
/// ```
class RawGooglePayButtonWeb extends StatelessWidget {
  /// The payment configuration for the button to show the last 4 digits of a
  /// pre-selected card
  final PaymentConfiguration _paymentConfiguration;

  /// The default width for the Google Pay Button.
  static const double minimumButtonWidth = 168;

  /// The default height for the Google Pay Button.
  static const double defaultButtonHeight = 48;

  /// The constraints used to limit the size of the button.
  final BoxConstraints constraints;

  // Identifier to register the view on the platform end.
  static const String viewType = 'plugins.flutter.io/pay/google_pay_button';

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// The amount of roundness applied to the corners of the button background.
  final int cornerRadius;

  /// The theme of the Google Pay button, to be adjusted based on the color
  /// scheme of the application.
  final GooglePayButtonThemeWeb theme;

  /// The type of button depending on the activity initiated with the payment
  /// transaction.
  final GooglePayButtonTypeWeb type;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// Creates a Google Pay button widget with the parameters specified.
  RawGooglePayButtonWeb({
    super.key,
    required final PaymentConfiguration paymentConfiguration,
    this.onPressed,
    this.cornerRadius = defaultButtonHeight ~/ 2,
    this.theme = GooglePayButtonThemeWeb.dark,
    this.type = GooglePayButtonTypeWeb.buy,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  })  : _paymentConfiguration = paymentConfiguration,
        constraints = const BoxConstraints.tightFor(
          width: minimumButtonWidth,
          height: defaultButtonHeight,
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

  /// Wrapper method to deliver the button
  Widget get _platformButton {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        decoration: BoxDecoration(
          color: theme == GooglePayButtonThemeWeb.dark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(cornerRadius.toDouble()),
        ),
        child: Center(
          child: Text(
            'Comprar con Google Pay',
            style: TextStyle(
              color: theme == GooglePayButtonThemeWeb.dark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  static bool get supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}
