/*
 * Sign In Form
 *
 * Created by:  Blake Davis
 * Description: A widget which displays forms pertaining to user authentication
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:io" show Platform;
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/auth_session_manager.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__icecrm_response.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/theme/grain_button_style.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:bmd_flutter_tools/widgets/component__app_info_text.dart";
import "package:bmd_flutter_tools/widgets/modal__debug_menu.dart";
import "package:bmd_flutter_tools/widgets/modal__loading.dart";
import "package:bmd_flutter_tools/widgets/modal__message.dart";
import "package:bmd_flutter_tools/widgets/modal__two_factor_authentication_code_input.dart";
import "package:bmd_flutter_tools/widgets/styled_button.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:package_info_plus/package_info_plus.dart";
import 'package:sentry_flutter/sentry_flutter.dart';

/* ======================================================================================================================
 * MARK: Sign In Form
 * ------------------------------------------------------------------------------------------------------------------ */
class SignInForm extends ConsumerStatefulWidget {
  final bool isNewSignup, submitOnLoad;

  static const Key rootKey = Key("sign_in_form__root");

  final String initialUsername, initialPassword;

  const SignInForm(
      {super.key,
      this.initialUsername = "",
      this.initialPassword = "",
      this.isNewSignup = false,
      this.submitOnLoad = false});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _SignInFormState extends ConsumerState<SignInForm> {
  static const String _rememberMeFlagKey = 'remember_me';
  static const String _rememberedEmailKey = 'remember_me_email';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _rememberMe = false;
  bool incorrectCredentials = false, showAccessCodeField = false;

  bool _passwordVisible = false;

  IOSOptions get _iosOptions => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
        synchronizable: false,
      );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _accessCodeController;
  late TextEditingController _emailAddressController;
  late TextEditingController _loginController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _twoFactorAuthenticationCodeController;

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  // TODO: There is some confusion on this widget to resolve with the username/login field actually referring to the email address field
  @override
  void initState() {
    super.initState();

    showSystemUiOverlays();

    _accessCodeController = TextEditingController();
    _emailAddressController = TextEditingController();
    _loginController = TextEditingController();
    _loginController.addListener(_onLoginTextChanged);
    _passwordController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _twoFactorAuthenticationCodeController = TextEditingController();

    /*
         * Pre-fill the email address and password fields
         */
    _loginController.text =
        (widget.initialUsername != "") ? widget.initialUsername : "";
    _passwordController.text =
        (widget.initialPassword != "") ? widget.initialPassword : "";

    unawaited(_loadRememberedLogin());
    /*
         * Immediately submit the form if submitOnLoad is true. This is used to automatically sign in verfied users
         * upon submitting their registration form
         */
    if (widget.submitOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logPrint("🔄 Automatically submitting signin form...");
        loginUsers();
      });
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void dispose() {
    _loginController.removeListener(_onLoginTextChanged);
    // Dispose of all of the TextEditingControllers
    _accessCodeController.dispose();
    _loginController.dispose();
    _emailAddressController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _twoFactorAuthenticationCodeController.dispose();

    super.dispose();
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Show Loading Indicator
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  void showTwoFactorAuthenticationCodeInputModal(BuildContext context,
      {required String email, required String token}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) =>
            TwoFactorAuthenticationCodeInputModal(
                email: email,
                token: token,
                onComplete: (IceCrmResponseData responseData) async {
                  await doLogin(responseData.data);
                }),
      );
    }
  }

  // Inside _SignInFormState (e.g., above doLogin)
  void _dismissLoadingModalIfAny() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    // Pop a single dialog if one is showing (avoids popping the route)
    if (nav.canPop()) {
      nav.pop();
    }
  }

  Future<void> _loadRememberedLogin() async {
    try {
      final rememberValue = await _secureStorage.read(key: _rememberMeFlagKey);
      bool shouldRemember = rememberValue == 'true';
      String? savedEmail;
      if (!shouldRemember &&
          rememberValue != null &&
          rememberValue.isNotEmpty &&
          rememberValue != 'false') {
        savedEmail = rememberValue;
        shouldRemember = true;
      }

      if (shouldRemember) {
        savedEmail = await _secureStorage.read(key: _rememberedEmailKey);
        savedEmail ??= await _secureStorage.read(key: "user_email");
        savedEmail ??= rememberValue;
      }

      if (!mounted) return;
      setState(() {
        _rememberMe = shouldRemember;
        if (shouldRemember &&
            _loginController.text.isEmpty &&
            savedEmail != null &&
            savedEmail.isNotEmpty) {
          _loginController.text = savedEmail;
        }
      });
    } catch (e) {
      logPrint('RememberMe: failed to load saved credentials → $e');
    }
  }

  void _handleRememberMeChanged(bool value) {
    setState(() {
      _rememberMe = value;
    });
    unawaited(
        _persistRememberPreference(_secureStorage, _loginController.text));
  }

  void _onLoginTextChanged() {
    if (!_rememberMe) return;
    unawaited(
        _persistRememberPreference(_secureStorage, _loginController.text));
  }

  Future<void> _persistRememberPreference(
      FlutterSecureStorage storage, String email) async {
    try {
      await storage.write(
        key: _rememberMeFlagKey,
        value: _rememberMe && email.isNotEmpty ? email : 'false',
        iOptions: _iosOptions,
      );

      if (_rememberMe && email.isNotEmpty) {
        await storage.write(
          key: _rememberedEmailKey,
          value: email,
          iOptions: _iosOptions,
        );
      } else {
        await storage.delete(
          key: _rememberedEmailKey,
          iOptions: _iosOptions,
        );
      }
    } catch (e) {
      logPrint('RememberMe: failed to persist preference → $e');
    }
  }

  Future<void> doLogin(Map<dynamic, dynamic> responseData) async {
    logPrint("✅ Successfully logged in user ${_loginController.text}.");

    final Object? accessTokenValue = responseData["access_token"];
    if (accessTokenValue is! String || accessTokenValue.isEmpty) {
      logPrint("❌ AuthSessionManager: access token missing from response");
      if (mounted) {
        _dismissLoadingModalIfAny();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text("Failed to get user data."),
          backgroundColor: Colors.red.shade300,
        ));
      }
      return;
    }

    await AuthSessionManager.storeAccessToken(accessTokenValue);

    final currentUser = await AuthSessionManager.initializeSession(
      ref: ref,
      password: _passwordController.text,
    );

    if (currentUser == null) {
      if (mounted) {
        _dismissLoadingModalIfAny();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          content: Text("Failed to get user data."),
          backgroundColor: Colors.red.shade300,
        ));
      }
      return;
    }

    await _persistRememberPreference(_secureStorage, currentUser.email);

    _dismissLoadingModalIfAny();

    if (!mounted) {
      return;
    }

    final dynamic reviewCompanyInfoFlag = responseData["review_company_info"];
    bool reviewCompanyInfo = true;
    if (reviewCompanyInfoFlag is bool) {
      reviewCompanyInfo = reviewCompanyInfoFlag;
    } else if (reviewCompanyInfoFlag is String) {
      final normalized = reviewCompanyInfoFlag.toLowerCase();
      if (normalized == 'true') {
        reviewCompanyInfo = true;
      } else if (normalized == 'false') {
        reviewCompanyInfo = false;
      }
    }

    if (showAccessCodeField) {
      appRouter.replaceNamed("finalize account", extra: {
        'user': ref.read(userProvider),
        'reviewCompanyInfo': reviewCompanyInfo,
      });
    } else {
      appRouter.replaceNamed("home");
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Handle the Login Request's Response
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<void> handleLoginResponse(IceCrmResponseData iceCrmResponse) async {
    dynamic responseData = iceCrmResponse.data;

    if (responseData != null &&
        responseData is Map &&
        responseData.isNotEmpty) {
      if (responseData.containsKey("access_token")) {
        await doLogin(responseData);

        /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
             *  Show the 2FA modal if it is enabled for the User
             */
      } else if (responseData["2fa_token"] != null) {
        // Dismiss the loading indicator
        if (!mounted) {
          return;
        }
        context.pop();

        showTwoFactorAuthenticationCodeInputModal(context,
            email: _loginController.text, token: responseData["2fa_token"]);

        /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
             *  If login was not successful or data is missing
             */
      } else {
        logPrint("❌ Login unsuccessful or data is missing.");

        // Dismiss the loading indicator
        if (!mounted) {
          return;
        }
        context.pop();
      }
    } else {
      // Dismiss the loading indicator
      if (!mounted) {
        return;
      }
      context.pop();
    }
    if (iceCrmResponse.messages.isNotEmpty) {
      bool unauthorizedHandled = false;

      for (final rawMessage in iceCrmResponse.messages) {
        final String message = rawMessage.trim();

        if (message.isEmpty) {
          continue;
        }

        final bool isUnauthorized = message == "Unauthorized";

        if (!showAccessCodeField && isUnauthorized) {
          if (!unauthorizedHandled && mounted) {
            setState(() {
              incorrectCredentials = true;
            });
            unauthorizedHandled = true;
          }
          continue;
        }

        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
            content: Text(message,
                style: TextStyle(color: BeColorSwatch.red),
                textAlign: TextAlign.center)));
      }
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Attempt Sign In
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<void> loginUsers() async {
    // Show loading indicator
    if (_formKey.currentState!.validate()) {
      if (context.mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) =>
                LoadingModal(text: "Signing in..."));
      }
      logPrint("🔄 Signing in...");

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Attempt to sign in
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      try {
        IceCrmResponseData? response = await ApiClient.instance.login(
          email: showAccessCodeField ? null : _loginController.text,
          password: showAccessCodeField ? null : _passwordController.text,
          accessCode: showAccessCodeField ? _accessCodeController.text : null,
        );

        // Protect against null responses from the API client
        if (response == null) {
          logPrint("Login returned null response.");
          await Sentry.captureMessage(
              "ApiClient.login returned null response during sign in for ${_loginController.text}");
          if (!mounted) return;
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to contact server. Please try again."),
            backgroundColor: BeColorSwatch.red,
          ));
          return;
        }

        await handleLoginResponse(response);

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle login errors
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      } catch (error, stackTrace) {
        logPrint("❌ Sign-in error: $error");
        await Sentry.captureException(error, stackTrace: stackTrace);

        // Dismiss the loading indicator
        if (!mounted) {
          return;
        }
        context.pop();

        // Display the error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $error",
              style: TextStyle(color: BeColorSwatch.white)),
          backgroundColor: BeColorSwatch.red,
        ));
      }
    }
  }

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        /*
         * UI text
         *
         * Defined here to eventually aid in localization
         * TODO: Move this -- everything pertaining to localization needs to be organized and refactored
         */
        final Map<String, String> text = {
            "forgot_password_button_label": "Forgot password?",
            "header_title": "Sign in",
            "password_field_label": "Password",
            "password_validation_message": "Please enter your password.",
            "pre_sign_in_message": "Enter your Build Expo USA login and password.",
            "register_button_label": "New user? Register here!",
            "sign_in_button_label": "Sign in",
            "username_field_label": "Email address",
            "username_validation_message": "Please enter your email address.",
        };

    final passwordResetButton = TextButton(
      key: const Key("sign_in_form__forgot_password_button"),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                formFieldLabel(labelText: "Email address"),
                TextFormField(
                  key: const Key(
                      "forgot_password_modal__submit_email_address_field"),
                  controller: _emailAddressController,
                  decoration: gfieldInputDecoration.merge(InputDecoration(
                      hintText: "Email address", hintStyle: gfieldHintStyle)),
                  enableSuggestions: false,
                  strutStyle: StrutStyle(height: 2),
                ),
                const SizedBox(height: 18),
                StyledButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return LoadingModal(
                              text: "Requesting password reset link...");
                        });

                    final result = await ApiClient.instance
                        .requestPasswordReset(
                            email: _emailAddressController.text);

                    // Dismiss the loading modal
                    if (!context.mounted) {
                      return;
                    }
                    context.pop();

                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return MessageModal(
                              title: "Request sent",
                              body:
                                  "Please check your email inbox for the link to reset your password.");
                        });

                    Future.delayed(Duration(seconds: 2), () async {
                      // Dismiss the success/failure modal
                      if (context.mounted) {
                        context.pop();

                        // Dismiss the forgot password form modal
                        if (context.mounted) {
                          context.pop();
                        }
                      }
                    });
                  },
                  label: Text(
                      key: const Key("forgot_password_modal__submit_button"),
                      "Submit".toUpperCase()),
                  backgroundColor: BeColorSwatch.red,
                )
              ]));
            });
      },
      child: Text(text["forgot_password_button_label"]!,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: BeColorSwatch.blue)),
    );

    return PopScope(
        canPop: false,
        child: Scaffold(
            key: SignInForm.rootKey,
            backgroundColor: BeColorSwatch.offWhite,
            resizeToAvoidBottomInset: false,
            body: LayoutBuilder(builder: (context, constraints) {
              final media = MediaQuery.of(context);
              final double viewportHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : media.size.height;

              Widget scrollableContent = SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: media.padding.bottom + 48),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Padding(
                      padding: EdgeInsets.only(
                          top: 16, right: (32/textScaleFactor), bottom: 72, left: (32/textScaleFactor)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                    // Spacer
                                    const SizedBox(height: 56),

                                    /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                        *  Logo
                                        */
                                    Image.asset(
                                        "./assets/images/build-expo-usa-logo-vertical.png",
                                        width: 250,
                                        fit: BoxFit.fill),

                                    // Spacers
                                    const SizedBox(height: 28),

                                    ...(showAccessCodeField
                                        ? [null]
                                        : [
                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                            *  Quick sign in button
                                            */
                                            if (developmentFeaturesEnabled)
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  spacing: 8,
                                                  children: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          // Make sure we're using the demo server
                                                          ref
                                                              .read(
                                                                  isDevelopmentProvider
                                                                      .notifier)
                                                              .state = true;
                                                          ref
                                                                  .read(developmentSiteBaseUrlProvider
                                                                      .notifier)
                                                                  .state =
                                                              "demo.beusa.app";

                                                          // Set the user credentials
                                                          _loginController
                                                                  .text =
                                                              "attendeetest@example.com";
                                                          _passwordController
                                                                  .text =
                                                              "password";

                                                          // Sign in
                                                          loginUsers();
                                                        },
                                                        style: grainButtonStyle(
                                                            colors:      [ BeColorSwatch.blue, BeColorSwatch.blue ],
                                                            borderRadius:  BorderRadius.circular(mediumRadius),
                                                        ),
                                                        child: Text((textScaleFactor > 1.2) ? "Attendee" : "Attendee demo")),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          // Make sure we're using the demo server
                                                          ref
                                                              .read(
                                                                  isDevelopmentProvider
                                                                      .notifier)
                                                              .state = true;
                                                          ref
                                                                  .read(developmentSiteBaseUrlProvider
                                                                      .notifier)
                                                                  .state =
                                                              "demo.beusa.app";

                                                          // Set the user credentials
                                                          _loginController
                                                                  .text =
                                                              "adminuser@bmd_flutter_tools.com";
                                                          _passwordController
                                                                  .text =
                                                              "password";

                                                          // Sign in
                                                          loginUsers();
                                                        },
                                                        style: grainButtonStyle(
                                                            colors:      [ BeColorSwatch.blue, BeColorSwatch.blue ],
                                                            borderRadius:  BorderRadius.circular(mediumRadius),
                                                        ),
                                                        child: Text((textScaleFactor > 1.2) ? "Exhibitor" : "Exhibitor demo")),
                                                  ]),

                                            const SizedBox(height: 16),

                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                            *  Email field
                                            */
                                            formFieldLabel(
                                                labelText: "Email address"),

                                            TextFormField(
                                              autocorrect: false,
                                              controller: _loginController,
                                              cursorHeight: 25,
                                              decoration: gfieldInputDecoration
                                                  .merge(InputDecoration(
                                                      hintText: "Email address",
                                                      hintStyle:
                                                          gfieldHintStyle)),
                                              enableSuggestions: false,
                                              key: const Key(
                                                  "sign_in_form__email_address_field"),
                                              strutStyle: StrutStyle(height: 2),
                                              validator: (value) {
                                                return (value == null ||
                                                        value.isEmpty)
                                                    ? text[
                                                        "username_validation_message"]!
                                                    : null;
                                              },
                                            ),

                                            // Spacer
                                            const SizedBox(height: 16),

                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                            *  Password field
                                            */
                                             /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                *  Password reset button
                                                */
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        formFieldLabel(labelText: "Password"),
                                                        Spacer(),
                                                        passwordResetButton
                                                      ]),

                                            TextFormField(
                                              autocorrect: false,
                                              controller: _passwordController,
                                              cursorHeight: 25,
                                              decoration:
                                                  gfieldInputDecoration.merge(
                                                InputDecoration(
                                                  hintText: "Password",
                                                  hintStyle: gfieldHintStyle,
                                                  suffixIcon: IconButton(
                                                    splashRadius: 20,
                                                    icon: SFIcon(
                                                      _passwordVisible
                                                          ? SFIcons.sf_eye_slash
                                                          : SFIcons
                                                              .sf_eye,
                                                      fontSize: 16,
                                                      color: BeColorSwatch
                                                          .darkGray
                                                          .withAlpha(175),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _passwordVisible =
                                                            !_passwordVisible;
                                                      });
                                                    },
                                                    style: ButtonStyle(
                                                        splashFactory: NoSplash
                                                            .splashFactory),
                                                  ),
                                                ),
                                              ),
                                              enableSuggestions: false,
                                              key: const Key(
                                                  "sign_in_form__password_field"),
                                              obscureText: !_passwordVisible,
                                              onFieldSubmitted: (value) {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  _formKey.currentState?.save();
                                                  loginUsers;
                                                }
                                              },
                                              strutStyle: StrutStyle(height: 2),
                                              validator: (value) {
                                                return (value == null ||
                                                        value.isEmpty)
                                                    ? text[
                                                        "password_validation_message"]!
                                                    : null;
                                              },
                                            ),

                                            Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Checkbox(
                                                    value: _rememberMe,
                                                    onChanged: (value) =>
                                                        _handleRememberMeChanged(
                                                            value ?? false),
                                                  ),
                                                  Text('Remember me',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall!
                                                          .copyWith(
                                                              color: BeColorSwatch
                                                                  .darkGray
                                                                  .withAlpha(
                                                                      200))),
                                                  const Spacer(),

                                                ]),

                                            /*
                                            * Invalid credentials message
                                            */
                                            if (incorrectCredentials)
                                              Text(
                                                  "Incorrect email address and/or password",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                          color:
                                                              BeColorSwatch.red,
                                                          fontWeight:
                                                              FontWeight.bold)),

                                            // Spacer
                                            if (!incorrectCredentials)
                                              const SizedBox(height: 20),

                                            const SizedBox(height: 44),

                                          ]),

                                    ...(showAccessCodeField
                                        ? [
                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                            *  Access code field
                                            */
                                            formFieldLabel(
                                                labelText: "Access Code"),

                                            TextFormField(
                                              controller: _accessCodeController,
                                              cursorHeight: 25,
                                              decoration: gfieldInputDecoration
                                                  .merge(InputDecoration(
                                                      hintText: "Access Code",
                                                      hintStyle:
                                                          gfieldHintStyle)),
                                              enableSuggestions: false,
                                              keyboardType: TextInputType.text,
                                              strutStyle: StrutStyle(height: 2),
                                            ),

                                            // Spacer
                                            const SizedBox(height: 108),
                                          ]
                                        : [null]),

                                    /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                        *  Sign-in button
                                        */
                                    Container(
        decoration: hardEdgeDecoration.copyWith(borderRadius: BorderRadius.circular(fullRadius)),
        child: Container(
            foregroundDecoration: fullRadiusBeveledDecoration,
        child: ElevatedButton(
                                      key: const Key(
                                          "sign_in_form__sign_in_button"),
                                      onPressed: loginUsers,
                                      style: roundElevatedButtonStyle.merge(
                                          ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      BeColorSwatch.navy))),
                                      child: Text("Sign in"),
                                    ))),

                                    // Spacer
                                            const SizedBox(height: 12),

                                        /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                            *  Register button
                                            */
                                            Container(
        decoration: hardEdgeDecoration.copyWith(borderRadius: BorderRadius.circular(fullRadius)),
        child: Container(
            foregroundDecoration: fullRadiusBeveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "sign_in_form__register_button"),
                                              onPressed: () {
                                                appRouter.pushNamed("register",
                                                    extra: {
                                                      "initialEmail":
                                                          _loginController.text,
                                                    });
                                              },
                                              style: roundElevatedButtonStyle
                                                  .merge(
                                                  ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStateProperty
                                                              .all(BeColorSwatch
                                                                  .red))
                                                                  ),
                                              child: Text(
                                                  "Register"),
        ))),



                                    // Spacer
                                    const SizedBox(height: 24),

                                    /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                        *  Access code button
                                        */
                                    InkWell(
                                        onTap: () {
                                          setState(() {
                                            showAccessCodeField =
                                                !showAccessCodeField;
                                          });
                                        },
                                        child: Container(
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(fullRadius), color: BeColorSwatch.offWhite.withAlpha(200)),
                                            child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            spacing: 6,
                                            children: [
                                              showAccessCodeField
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 4),
                                                      child: SFIcon(
                                                          SFIcons.sf_arrow_left,
                                                          color:      BeColorSwatch.blue,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize:   14
                                                    )
                                                )
                                                  : null,
                                              Text(showAccessCodeField ? "Enter email and password" : "Enter access code", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold))
                                            ].nonNulls.toList()))),

                                    const SizedBox(height: 48),

                          ].nonNulls.toList(),
                        ),
                      ),
                    ),
                ),
              );

              scrollableContent = MediaQuery.removeViewPadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                removeLeft: true,
                removeRight: true,
                child: scrollableContent,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  AppInfoText(),
                  Positioned.fill(child: scrollableContent),
                  if (developmentFeaturesEnabled)
                    Positioned(
                      top: 36,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [DebugMenuToggle()],
                      ),
                    ),

                ],
              );
            })));
  }
}
