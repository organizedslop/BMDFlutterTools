/*
 * Registration Form
 *
 * Created by:  Blake Davis
 * Description: A widget which displays and handles the user registration form
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/auth_session_manager.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/data/data__us_states.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/utilities/clip_utilities.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/modals/loading.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:collection/collection.dart";
import "package:country_picker/country_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:go_router/go_router.dart";
import "package:intl_phone_number_input/intl_phone_number_input.dart";
import "package:url_launcher/url_launcher.dart";

/* ======================================================================================================================
 * MARK: Registration Form
 * ------------------------------------------------------------------------------------------------------------------ */
class RegistrationForm extends ConsumerStatefulWidget {
  static const Key rootKey = Key("registration_form__root");

  final bool isFinalizing;

  final bool reviewCompanyInfo;

  final String? title;

  final String? initialEmail;

  final UserData? user;

  const RegistrationForm({
    super.key,
    this.title,
    this.user,
    this.initialEmail,
    isFinalizing,
    bool? reviewCompanyInfo,
  })  : reviewCompanyInfo = reviewCompanyInfo ?? true,
        isFinalizing = isFinalizing ?? false;

  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  AppDatabase appDatabase = AppDatabase.instance;

  String? _previousPhoneIsoCode = 'US';
  String? _previousCompanyPhoneIsoCode = 'US';
  bool _isPasswordVisible = false;

  double pageIndicatorWidth = 40,
      progressBarHeight = 14,
      progressBarWidth = 300;

  static Uri _registrationHelpUri = Uri(scheme: 'tel', path: '15122495303');

  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _companyFormKey = GlobalKey<FormState>();

  int pageIndex = 0, totalPageCount = 3;

  final Map<String, Map<String, dynamic>> _userFieldData = {
    "first_name": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "last_name": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "email": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>(
          debugLabel: "register_user_form__email_address_field")
    },
    "phone": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "phone_iso": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>(),
      "value": "1",
      "dial_code": "+1",
      "iso_code": "US"
    },
    "contact_consent": {"value": false, "key": GlobalKey<FormFieldState>()},
    "sms_consent": {"value": false, "key": GlobalKey<FormFieldState>()},
    "password": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "password_confirm": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
  };

  final Map<String, Map<String, dynamic>> _companyFieldData = {
    "company_name": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "company_email": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "company_phone": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "company_phone_iso": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>(),
      "value": "1",
      "dial_code": "+1",
      "iso_code": "US"
    },
    "company_website": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "address": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "address_2": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "city": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "state": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "zip": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "country": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "country_code": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
    "job_title": {
      "controller": TextEditingController(),
      "key": GlobalKey<FormFieldState>()
    },
  };

  Map<String, Map<String, dynamic>> get _fieldData => {
        ..._userFieldData,
        ..._companyFieldData,
      };

  ScrollController _scrollController =
      ScrollController(keepScrollOffset: false, initialScrollOffset: 0.0);

  static const String _rememberMeFlagKey = 'remember_me';
  static const String _rememberedEmailKey = 'remember_me_email';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  );

  GlobalKey<FormState> get _currentFormKey =>
      pageIndex == 0 ? _userFormKey : _companyFormKey;

  bool _userStageSubmitting = false;
  bool _showHelpSection = true;
  String? _registeredUserId;
  bool _emailDuplicateDetected = false;

  String _formatPhoneWithIsoPrefix(PhoneNumber number) {
    String dialCode = (number.dialCode ?? "").replaceAll(RegExp(r"[^0-9]"), "");
    String digits =
        (number.phoneNumber ?? "").replaceAll(RegExp(r"[^0-9]"), "");

    if (digits.isEmpty) {
      return "";
    }

    if (dialCode.isEmpty || digits.startsWith(dialCode)) {
      return digits;
    }

    return dialCode + digits;
  }

  String? _numericDialCode(PhoneNumber number) {
    String dialCode = (number.dialCode ?? "").replaceAll(RegExp(r"[^0-9]"), "");

    return dialCode.isEmpty ? null : dialCode;
  }

  bool _containsDuplicateEmailMessage(List<String> messages) {
    for (final message in messages) {
      final lower = message.toLowerCase();
      if (lower.contains('email') &&
          (lower.contains('already') ||
              lower.contains('exist') ||
              lower.contains('duplicate') ||
              lower.contains('registered'))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _launchPasswordReset() async {
    final protocol = ref.read(protocolProvider);
    final isDev = ref.read(isDevelopmentProvider);
    final host = isDev
        ? ref.read(developmentSiteBaseUrlProvider)
        : ref.read(productionSiteBaseUrlProvider);
    final Uri url = Uri.parse('$protocol$host');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      logPrint('⚠️ Failed to open password reset URL: $url');
    }
  }

  PhoneNumber _buildInitialPhoneNumber({
    required Map<String, dynamic>? isoField,
    required Map<String, dynamic>? phoneField,
    required String? fallbackIso,
  }) {
    final String isoCode =
        (isoField?["iso_code"] as String?) ?? fallbackIso ?? 'US';
    final String? numericDial = isoField?["value"] as String?;
    final String? dialWithPlus = isoField?["dial_code"] as String? ??
        ((numericDial != null && numericDial.isNotEmpty)
            ? '+$numericDial'
            : null);

    final TextEditingController? controller =
        phoneField?["controller"] as TextEditingController?;
    final bool hasControllerText = controller?.text.isNotEmpty ?? false;
    final dynamic storedValue = phoneField?["value"];
    final String? phoneNumber =
        (!hasControllerText && storedValue is String && storedValue.isNotEmpty)
            ? '+$storedValue'
            : null;

    return PhoneNumber(
      isoCode: isoCode,
      dialCode: dialWithPlus,
      phoneNumber: phoneNumber,
    );
  }

  void _prefillPhoneForFinalizing(
    String rawPhone, {
    String phoneFieldKey = "phone",
    String phoneIsoFieldKey = "phone_iso",
    String? fallbackIso,
  }) async {
    final Map<String, dynamic>? phoneField = _fieldData[phoneFieldKey];
    final Map<String, dynamic>? isoField = _fieldData[phoneIsoFieldKey];
    final TextEditingController? controller =
        phoneField?["controller"] as TextEditingController?;

    final sanitized = rawPhone.trim();

    if (sanitized.isEmpty) {
      controller?.text = "";
      phoneField?["value"] = null;
      return;
    }

    final digitsOnly = sanitized.replaceAll(RegExp(r"[^0-9]"), "");
    if (digitsOnly.isEmpty) {
      controller?.text = "";
      phoneField?["value"] = null;
      return;
    }

    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      final String national = digitsOnly.substring(1);
      final String? existingIso =
          (isoField?["iso_code"] as String?) ?? fallbackIso;
      final String resolvedIso =
          (existingIso != null && existingIso.toUpperCase() == 'CA')
              ? 'CA'
              : 'US';

      controller?.text = national;
      phoneField?["value"] = digitsOnly;

      isoField?["iso_code"] = resolvedIso;
      isoField?["value"] = '1';
      isoField?["dial_code"] = '+1';

      if (phoneIsoFieldKey == "phone_iso") {
        _previousPhoneIsoCode = resolvedIso;
      } else if (phoneIsoFieldKey == "company_phone_iso") {
        _previousCompanyPhoneIsoCode = resolvedIso;
      }

      return;
    }

    final defaultIso =
        (isoField?["iso_code"] as String?) ?? fallbackIso ?? 'US';
    final formattedWithPlus =
        sanitized.startsWith('+') ? sanitized : '+$digitsOnly';
    Future<PhoneNumber?> tryParse(String value, String isoHint) async {
      try {
        return await PhoneNumber.getRegionInfoFromPhoneNumber(value, isoHint);
      } catch (_) {
        return null;
      }
    }

    PhoneNumber? info = await tryParse(formattedWithPlus, defaultIso);

    if (info != null) {
      final dial = info.dialCode?.replaceAll(RegExp(r"[^0-9]"), "") ?? "";
      String national;

      try {
        final parsable = await PhoneNumber.getParsableNumber(info);
        national = parsable.replaceAll(RegExp(r"[^0-9]"), "");
      } catch (_) {
        national = info.parseNumber().replaceAll(RegExp(r"[^0-9]"), "");
      }

      if (national.isEmpty) {
        national = digitsOnly;
        if (dial.isNotEmpty && national.startsWith(dial)) {
          national = national.substring(dial.length);
        }
      }

      controller?.text = national;
      phoneField?["value"] = dial.isNotEmpty ? dial + national : digitsOnly;

      if (info.isoCode != null && info.isoCode!.isNotEmpty) {
        isoField?["iso_code"] = info.isoCode;
        if (phoneIsoFieldKey == "phone_iso") {
          _previousPhoneIsoCode = info.isoCode;
        } else if (phoneIsoFieldKey == "company_phone_iso") {
          _previousCompanyPhoneIsoCode = info.isoCode;
        }
      }
      if (dial.isNotEmpty) {
        isoField?["value"] = dial;
        isoField?["dial_code"] = '+$dial';
      }
      return;
    }

    var national = digitsOnly;
    final numericDial = (isoField?["value"] as String?) ?? '';
    if (numericDial.isNotEmpty && national.startsWith(numericDial)) {
      national = national.substring(numericDial.length);
    }
    controller?.text = national;
    phoneField?["value"] = digitsOnly;
  }

  void _dismissLoadingModalIfAny() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _openRegistrationHelpCall() async {
    try {
      final launched = await launchUrl(
        _registrationHelpUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to open the dialer.'),
        ));
      }
    } catch (error) {
      logPrint('Registration Help: failed to open dialer → $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to open the dialer.'),
        ));
      }
    }
  }

  Widget _buildHelpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Need help registering? Call Build Expo USA for assistance.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BeColorSwatch.navy, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                color: BeColorSwatch.darkGray,
                tooltip: 'Dismiss',
                onPressed: () {
                  setState(() {
                    _showHelpSection = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const Key('register_user_form__help_button'),
            onPressed: _openRegistrationHelpCall,
            icon: SFIcon(
              SFIcons.sf_phone,
              color: BeColorSwatch.blue,
              fontSize: 18,
            ),
            label: const Text('Call (512) 249-5303'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: BeColorSwatch.blue,
              textStyle: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isUnitedStatesSelected {
    final String codeFromValue =
        (_fieldData["country"]?["value"] as String? ?? "").trim();
    if (codeFromValue.isNotEmpty) {
      return codeFromValue.toUpperCase() == 'US';
    }

    final TextEditingController? countryCodeController =
        _fieldData["country_code"]?["controller"] as TextEditingController?;
    final String codeFromController = countryCodeController?.text.trim() ?? "";
    if (codeFromController.isNotEmpty) {
      return codeFromController.toUpperCase() == 'US';
    }

    final TextEditingController? countryNameController =
        _fieldData["country"]?["controller"] as TextEditingController?;
    final String countryName =
        countryNameController?.text.trim().toLowerCase() ?? "";

    if (countryName.isEmpty) {
      return true;
    }

    return countryName == 'united states';
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void initState() {
    super.initState();

    if (widget.isFinalizing && !widget.reviewCompanyInfo) {
      totalPageCount = 1;
    }

    // _isRestoringDraft = true;

    // Pre-fill the form if UserData was provided
    if (widget.user != null) {
      _fieldData["first_name"]!["controller"].text =
          widget.user?.name.first ?? "";
      _fieldData["last_name"]!["controller"].text =
          widget.user?.name.last ?? "";
      _fieldData["email"]!["controller"].text = widget.user?.email ?? "";
      final String userPhonePrimary = widget.user?.phone.primary ?? "";
      if (widget.isFinalizing) {
        _prefillPhoneForFinalizing(
          userPhonePrimary,
          fallbackIso: _previousPhoneIsoCode,
        );
      } else {
        _fieldData["phone"]!["controller"].text = userPhonePrimary;
      }
      _fieldData["company_name"]!["controller"].text =
          widget.user?.companies.firstOrNull?.name ?? "";
      _fieldData["company_email"]!["controller"].text =
          widget.user?.companies.firstOrNull?.email ?? "";
      final String companyPhonePrimary =
          widget.user?.companies.firstOrNull?.phone ?? "";
      if (widget.isFinalizing) {
        _prefillPhoneForFinalizing(
          companyPhonePrimary,
          phoneFieldKey: "company_phone",
          phoneIsoFieldKey: "company_phone_iso",
          fallbackIso: _previousCompanyPhoneIsoCode,
        );
      } else {
        _fieldData["company_phone"]!["controller"].text = companyPhonePrimary;
      }
      _fieldData["company_website"]!["controller"].text =
          widget.user?.companies.firstOrNull?.website ?? "";
      _fieldData["address"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.street ?? "";
      _fieldData["address_2"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.street2 ?? "";
      _fieldData["city"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.city ?? "";
      _fieldData["state"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.state ?? "";
      _fieldData["zip"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.zip ?? "";
      _fieldData["country"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.country ?? "";
      _fieldData["country_code"]!["controller"].text =
          widget.user?.companies.firstOrNull?.address.country ?? "";
      _fieldData["job_title"]!["controller"].text = widget.user?.companyUsers
              .firstWhereOrNull((companyUser) =>
                  companyUser.companyId == widget.user?.companies.first.id)
              ?.jobTitle ??
          "";
    }

    // Pre-fill the email field with the sign-in form data if no User is provided
    if (widget.initialEmail != null && widget.user == null) {
      _fieldData["email"]!["controller"].text = widget.initialEmail!;
    }

    (_fieldData['email']?['controller'] as TextEditingController?)
        ?.addListener(() {
      if (_emailDuplicateDetected && mounted) {
        setState(() {
          _emailDuplicateDetected = false;
        });
      }
    });

    final TextEditingController? countryController =
        _fieldData["country"]?["controller"] as TextEditingController?;
    final TextEditingController? countryCodeController =
        _fieldData["country_code"]?["controller"] as TextEditingController?;

    if ((countryController?.text.isEmpty ?? true) &&
        (countryCodeController?.text.isEmpty ?? true)) {
      countryController?.text = "United States";
      countryCodeController?.text = "US";
      _fieldData["country"]?["value"] = "US";
      _fieldData["country_code"]?["value"] = "US";
    }

    if (!widget.isFinalizing) {
      final bool hasCompletedUserStage =
          ref.read(registrationUserStageCompletedProvider);
      if (hasCompletedUserStage) {
        final String? storedUserId =
            ref.read(registrationUserStageUserIdProvider);
        if (storedUserId != null && storedUserId.isNotEmpty) {
          _registeredUserId = storedUserId;
        }
        pageIndex = 1;
      }
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void dispose() {
    // Dispose of the scroll controller
    _scrollController.dispose();

    // Dispose of the text controllers
    for (final fieldData in [
      ..._userFieldData.values,
      ..._companyFieldData.values,
    ]) {
      if (fieldData["controller"] != null) {
        fieldData["controller"].dispose();
      }
    }

    super.dispose();
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Go to Next Page
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  void nextPage() {
    setState(() {
      FocusScope.of(context).unfocus();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      int newPageIndex = pageIndex + 1;

      if (newPageIndex < totalPageCount) {
        pageIndex = newPageIndex;
      }
    });
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Go to Previous Page
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  void previousPage() {
    setState(() {
      FocusScope.of(context).unfocus();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(-2000);
      }
      int newPageIndex = pageIndex - 1;

      if (newPageIndex >= 0) {
        pageIndex = newPageIndex;
      }
    });
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Submit the Form
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  void saveRegistrationForm(
      {required BuildContext context,
      required Map<String, dynamic> formData}) async {
    logPrint("🔄 Called saveRegistrationForm()");

    if (!mounted) {
      return;
    }

    if (widget.isFinalizing) {
      await _submitFinalizingCompanyStage(
        context: context,
        formData: formData,
      );
      return;
    }

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Save the form to the database
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingModal(text: "Saving registration form..."));
    logPrint("🔄 Saving registration form to database...");

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Submit the form data
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    if (!context.mounted) {
      return;
    }
    appRouter.pop();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingModal(text: "Submitting company info..."));
    logPrint("🔄 Submitting company creation form...");

    UserData? submittedUser;

    if (widget.user != null) {
      logPrint("🔄 Updating user...");
      submittedUser =
          await ApiClient.instance.updateUser(widget.user!.id, formData);
    } else if (_registeredUserId != null && _registeredUserId!.isNotEmpty) {
      final companyPayload = _collectCompanyStageData();
      companyPayload['user_id'] = _registeredUserId;
      submittedUser = await ApiClient.instance
          .submitRegistrationCompanyStage(companyPayload);
    } else {
      final users = await ApiClient.instance.submitRegistrationForm(formData);
      if (users != null && users.isNotEmpty) {
        submittedUser = users.first;
      }
    }

    // Dismiss the loading indicator
    if (!context.mounted) {
      return;
    }
    appRouter.pop();

    if (submittedUser != null) {
      if (!context.mounted) {
        return;
      }

      if (widget.user != null) {
        appRouter.goNamed("home");
        return;
      }

      setState(() {
        if (_registeredUserId == null || _registeredUserId!.isEmpty) {
          _registeredUserId = submittedUser?.id;
        }
      });

      if (submittedUser != null && submittedUser.companies.isNotEmpty) {
        if (ref.read(companyProvider) == null) {
          final sortedCompanies = [...submittedUser.companies]
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          ref.read(companyProvider.notifier).update(sortedCompanies.first);
        }
      }

      ref.read(registrationUserStageCompletedProvider.notifier).state = false;
      ref.read(registrationUserStageUserIdProvider.notifier).state = null;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted && context.canPop()) {
              context.pop();
            }
          });

          return const AlertDialog(
            title: Text("Registration Successful"),
            content: Text("You will be redirected shortly..."),
          );
        },
      );

      final username = formData["email"] as String? ?? "";
      final password = formData["password"] as String? ?? "";

      ref.read(isNewSignupProvider.notifier).update((state) => true);

      appRouter.goNamed(
        "signin",
        extra: {
          "initialUsername": username,
          "initialPassword": password,
          "submitOnLoad": true,
        },
      );
    } else {
      // Log it for debugging
      logPrint("❌ : registration form failed to submit.");

      // Show feedback to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration failed to submit. Please try again.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleSubmitPressed(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_companyFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final Map<String, dynamic> formDataAsMap = {
      ..._collectUserStageData(),
      ..._collectCompanyStageData(),
    };

    saveRegistrationForm(context: context, formData: formDataAsMap);
  }

  Map<String, dynamic> _collectUserStageData() {
    return _extractStageValues(_userFieldData.keys);
  }

  Map<String, dynamic> _collectCompanyStageData() {
    final data = _extractStageValues(_companyFieldData.keys);

    final String? companyEmail = data['company_email'] as String?;
    if (companyEmail != null && companyEmail.isNotEmpty) {
      data.putIfAbsent('email', () => companyEmail);
    }

    final String? companyPhone = data['company_phone'] as String?;
    if (companyPhone != null && companyPhone.isNotEmpty) {
      data.putIfAbsent('phone', () => companyPhone);
    }

    final String? companyPhoneIso = data['company_phone_iso'] as String?;
    if (companyPhoneIso != null && companyPhoneIso.isNotEmpty) {
      data.putIfAbsent('phone_iso', () => companyPhoneIso);
    }

    return data;
  }

  Future<UserData?> _finalizeExistingUser({
    required BuildContext context,
    required Map<String, dynamic> formData,
    bool navigateHomeOnSuccess = true,
  }) async {
    logPrint("🔄 Called _finalizeExistingUser()");

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingModal(text: "Updating your information..."));

    UserData? updatedUser;
    String? failureMessage;
    bool canSubmit = true;

    try {
      final String? targetUserId = widget.user?.id ?? _registeredUserId;

      if (targetUserId == null || targetUserId.isEmpty) {
        logPrint("❌ Finalizing registration failed: user id is missing.");
        failureMessage =
            'We could not determine which account to update. Please sign in again.';
        canSubmit = false;
      } else {
        final Map<String, dynamic> userPayload =
            _buildUserUpdatePayload(formData);

        if (userPayload.isEmpty) {
          logPrint("❌ Finalizing registration aborted: no user data provided.");
          failureMessage = 'No updates were provided.';
          canSubmit = false;
        } else {
          logPrint("🔄 Finalizing registration, updating user...");
          updatedUser =
              await ApiClient.instance.updateUser(targetUserId, userPayload);
        }
      }
    } finally {
      if (context.mounted) {
        appRouter.pop();
      }
    }

    if (!mounted) {
      return null;
    }

    if (updatedUser != null) {
      try {
        await appDatabase.write(updatedUser);
      } catch (error) {
        logPrint("⚠️ Failed to persist finalized user locally → $error");
      }

      ref.read(userProvider.notifier).update(updatedUser);

      if (navigateHomeOnSuccess) {
        appRouter.goNamed("home");
      }

      return updatedUser;
    }

    if (!canSubmit) {
      logPrint(
          "❌ Finalizing registration skipped: ${failureMessage ?? 'unknown reason'}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failureMessage ??
            'Failed to update your information. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );

    return null;
  }

  Future<void> _submitFinalizingCompanyStage({
    required BuildContext context,
    required Map<String, dynamic> formData,
  }) async {
    final String? targetUserId = widget.user?.id ?? _registeredUserId;

    if (targetUserId == null || targetUserId.isEmpty) {
      logPrint(
          '❌ Finalizing company stage failed: user id is missing. Unable to submit company data.');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not determine which account to update. Please sign in again.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final Map<String, dynamic> companyPayload = _collectCompanyStageData();
    companyPayload['user_id'] = targetUserId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingModal(text: 'Submitting company info...'),
    );

    UserData? updatedUser;

    try {
      updatedUser = await ApiClient.instance
          .submitRegistrationCompanyStage(companyPayload);
    } on RegistrationSubmissionException catch (error) {
      final messages = error.messages
          .map((message) => message.trim())
          .where((message) => message.isNotEmpty)
          .toList();
      final displayMessage = messages.isNotEmpty
          ? messages.join('\n')
          : 'Failed to update your information. Please try again.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(displayMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    } catch (error) {
      logPrint('❌ Finalizing company stage failed → $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Failed to update your company information. Please try again.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ));
      }
      return;
    } finally {
      if (context.mounted) {
        appRouter.pop();
      }
    }

    if (!mounted) {
      return;
    }

    if (updatedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Failed to update your information. Please try again.',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ));
      return;
    }

    try {
      await appDatabase.write(updatedUser);
    } catch (error) {
      logPrint('⚠️ Failed to persist finalized company data locally → $error');
    }

    if (mounted) {
      setState(() {
        _registeredUserId = updatedUser?.id;
      });
    }

    ref.read(userProvider.notifier).update(updatedUser);

    if (updatedUser != null && updatedUser.companies.isNotEmpty) {
      if (ref.read(companyProvider) == null) {
        final sortedCompanies = [...updatedUser.companies]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        ref.read(companyProvider.notifier).update(sortedCompanies.first);
      }
    }

    ref.read(registrationUserStageCompletedProvider.notifier).state = false;
    ref.read(registrationUserStageUserIdProvider.notifier).state = null;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Your information has been updated.'),
      duration: Duration(seconds: 3),
    ));

    appRouter.goNamed('home');
  }

  Map<String, dynamic> _buildUserUpdatePayload(Map<String, dynamic> formData) {
    final Map<String, dynamic> payload = {};

    for (final key in _userFieldData.keys) {
      if (key == 'password_confirm') {
        continue;
      }

      if (!formData.containsKey(key)) {
        continue;
      }

      final dynamic value = formData[key];

      if (value == null) {
        continue;
      }

      if (value is String) {
        final String trimmed = value.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        payload[key] = trimmed;
        continue;
      }

      payload[key] = value;
    }

    return payload;
  }

  Map<String, dynamic> _extractStageValues(Iterable<String> keys) {
    final Map<String, dynamic> data = {};

    for (final fieldKey in keys) {
      final field = _fieldData[fieldKey];
      if (field == null) continue;

      final TextEditingController? controller =
          field['controller'] as TextEditingController?;
      final dynamic storedValue = field['value'];

      if (fieldKey == 'phone' || fieldKey == 'company_phone') {
        final isoKey = fieldKey == 'phone' ? 'phone_iso' : 'company_phone_iso';
        final isoField = _fieldData[isoKey];
        final String numericDial =
            (isoField?['value'] as String?)?.trim() ?? '';
        if (isoField != null && numericDial.isNotEmpty) {
          data[isoKey] = numericDial;
        }

        final String digits =
            (controller?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          if (numericDial.isNotEmpty && !digits.startsWith(numericDial)) {
            data[fieldKey] = numericDial + digits;
          } else {
            data[fieldKey] = digits;
          }
        } else if (storedValue is String && storedValue.isNotEmpty) {
          data[fieldKey] = storedValue;
        }
        continue;
      }

      if (controller != null && controller.text.isNotEmpty) {
        data[fieldKey] = controller.text;
        continue;
      }

      if (storedValue != null) {
        data[fieldKey] = storedValue;
      }
    }

    return data;
  }

  Future<bool> _authenticateRegisteredUser(Map<String, dynamic> payload) async {
    String? email = payload['email'] as String?;
    String? password = payload['password'] as String?;

    email ??=
        (_fieldData['email']?['controller'] as TextEditingController?)?.text;
    password ??=
        (_fieldData['password']?['controller'] as TextEditingController?)?.text;

    email = email?.trim();

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      logPrint('❌ Registration: missing credentials for automatic sign in');
      return false;
    }

    try {
      final response =
          await ApiClient.instance.login(email: email, password: password);

      if (response == null) {
        return false;
      }

      final data = response.data;
      final Object? accessToken = data is Map ? data['access_token'] : null;

      if (accessToken is String && accessToken.isNotEmpty) {
        await AuthSessionManager.storeAccessToken(accessToken);
        final currentUser = await AuthSessionManager.initializeSession(
          ref: ref,
          password: password,
          markAsNewSignup: true,
        );
        if (currentUser != null) {
          await _rememberEmailForLogin(
              currentUser.email.isNotEmpty ? currentUser.email : email);
        }
        return currentUser != null;
      }

      final String? message = response.messages
          .map((message) => message.toString().trim())
          .firstWhereOrNull((message) => message.isNotEmpty);

      if (message != null && message.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      logPrint('❌ Registration: automatic sign in failed → $error');
    }

    return false;
  }

  Future<void> _rememberEmailForLogin(String? email) async {
    if (email == null || email.trim().isEmpty) {
      return;
    }

    try {
      await _secureStorage.write(
        key: _rememberMeFlagKey,
        value: email.trim(),
        iOptions: _iosOptions,
      );
      await _secureStorage.write(
        key: _rememberedEmailKey,
        value: email.trim(),
        iOptions: _iosOptions,
      );
    } catch (error) {
      logPrint('Registration: failed to remember email for login → $error');
    }
  }

  void _prefillCompanyContactFromUser() {
    final TextEditingController? userEmailController =
        _fieldData['email']?['controller'] as TextEditingController?;
    final TextEditingController? companyEmailController =
        _fieldData['company_email']?['controller'] as TextEditingController?;

    if (userEmailController != null &&
        userEmailController.text.isNotEmpty &&
        companyEmailController != null &&
        companyEmailController.text.isEmpty) {
      companyEmailController.text = userEmailController.text;
    }

    final TextEditingController? userPhoneController =
        _fieldData['phone']?['controller'] as TextEditingController?;
    final TextEditingController? companyPhoneController =
        _fieldData['company_phone']?['controller'] as TextEditingController?;

    if (userPhoneController != null &&
        userPhoneController.text.isNotEmpty &&
        companyPhoneController != null &&
        companyPhoneController.text.isEmpty) {
      companyPhoneController.text = userPhoneController.text;
    }

    final dynamic userPhoneValue = _fieldData['phone']?['value'];
    if (userPhoneValue is String && userPhoneValue.isNotEmpty) {
      _fieldData['company_phone']?['value'] = userPhoneValue;
    }

    final Map<String, dynamic>? userPhoneIso =
        _fieldData['phone_iso'] as Map<String, dynamic>?;
    final Map<String, dynamic>? companyPhoneIso =
        _fieldData['company_phone_iso'] as Map<String, dynamic>?;

    if (userPhoneIso != null && companyPhoneIso != null) {
      final String? isoCode = userPhoneIso['iso_code'] as String?;
      final String? dialCode = userPhoneIso['dial_code'] as String?;
      final String? numericDial = userPhoneIso['value'] as String?;

      if (isoCode != null && isoCode.isNotEmpty) {
        companyPhoneIso['iso_code'] = isoCode;
        _previousCompanyPhoneIsoCode = isoCode;
      }

      if (dialCode != null && dialCode.isNotEmpty) {
        companyPhoneIso['dial_code'] = dialCode;
      }

      if (numericDial != null && numericDial.isNotEmpty) {
        companyPhoneIso['value'] = numericDial;
      }
    }
  }

  Future<void> _handleUserStageNext() async {
    FocusScope.of(context).unfocus();
    if (_userStageSubmitting) return;
    if (!(_userFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _userStageSubmitting = true;
      _emailDuplicateDetected = false;
    });

    final payload = _collectUserStageData();

    if (!mounted) {
      setState(() => _userStageSubmitting = false);
      return;
    }

    if (widget.isFinalizing) {
      final bool shouldReviewCompany = widget.reviewCompanyInfo;

      setState(() => _userStageSubmitting = false);

      final UserData? updatedUser = await _finalizeExistingUser(
        context: context,
        formData: payload,
        navigateHomeOnSuccess: false,
      );

      if (!mounted || updatedUser == null) {
        return;
      }

      setState(() {
        _registeredUserId = updatedUser.id;
      });

      if (shouldReviewCompany) {
        ref.read(registrationUserStageCompletedProvider.notifier).state = true;
        ref.read(registrationUserStageUserIdProvider.notifier).state =
            updatedUser.id;
      }

      await appRouter.pushNamed('account created confirmation');

      if (!mounted) {
        return;
      }

      if (!shouldReviewCompany) {
        ref.read(registrationUserStageCompletedProvider.notifier).state = false;
        ref.read(registrationUserStageUserIdProvider.notifier).state = null;
        appRouter.goNamed('home');
        return;
      }

      _prefillCompanyContactFromUser();
      nextPage();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingModal(text: 'Creating account...'),
    );

    try {
      final user =
          await ApiClient.instance.submitRegistrationUserStage(payload);

      if (!mounted) return;

      if (user != null && user.id.isNotEmpty) {
        final bool loggedIn = await _authenticateRegisteredUser(payload);

        _dismissLoadingModalIfAny();

        if (!mounted) {
          return;
        }

        setState(() {
          _registeredUserId = user.id;
        });

        ref.read(registrationUserStageCompletedProvider.notifier).state = true;
        ref.read(registrationUserStageUserIdProvider.notifier).state = user.id;

        await appRouter.pushNamed('account created confirmation');

        if (!mounted) {
          return;
        }

        if (!loggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Account created, but we could not sign you in automatically. Please sign in manually.',
            ),
          ));
        }

        _prefillCompanyContactFromUser();

        nextPage();
      } else {
        _dismissLoadingModalIfAny();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to create user account. Please try again.'),
        ));
      }
    } on RegistrationSubmissionException catch (error) {
      if (mounted) {
        _dismissLoadingModalIfAny();
        final messages = error.messages
            .map((message) => message.trim())
            .where((message) => message.isNotEmpty)
            .toList();
        final displayMessage = messages.isNotEmpty
            ? messages.join('\n')
            : 'Failed to create user account. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(displayMessage),
          backgroundColor: BeColorSwatch.red,
        ));
        if (_containsDuplicateEmailMessage(messages)) {
          setState(() {
            _emailDuplicateDetected = true;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _dismissLoadingModalIfAny();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error creating user account: $error'),
          backgroundColor: BeColorSwatch.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _userStageSubmitting = false;
        });
      }
    }
  }

  void _handleCompanyPageNext() {
    FocusScope.of(context).unfocus();
    if (_registeredUserId == null || _registeredUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete your account details first.'),
      ));
      return;
    }
    if (!(_companyFormKey.currentState?.validate() ?? false)) {
      return;
    }
    nextPage();
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  Widget build(BuildContext context) {
    const fieldHorizontalSpacer = SizedBox(width: 10);
    const buttonHorziontalSpacer = SizedBox(width: 12);
    const verticalSpacerSmall = SizedBox(height: 10);
    const verticalSpacerMedium = SizedBox(height: 32);
    const verticalSpacerLarge = SizedBox(height: 48);

    final mediaQuery = MediaQuery.of(context);
    final double bottomInset = mediaQuery.viewInsets.bottom;
    final bool isKeyboardVisible = bottomInset > 0.0;

    Row buildBottomControls() {
      final previousButtonStyle = ButtonStyle(
          backgroundColor: WidgetStateProperty.all(BeColorSwatch.gray));

      Row buildNavigationRow({
        Widget? previous,
        required Widget next,
      }) {
        final children = <Widget>[
          buttonHorziontalSpacer,
        ];

        if (previous != null) {
          children.add(previous);
          children.add(const Spacer());
        }

        children.add(const Spacer());
        children.add(next);
        children.add(buttonHorziontalSpacer);

        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children);
      }

      switch (pageIndex) {
        case 0:
          return buildNavigationRow(
            next: ElevatedButton(
              key: const Key("register_user_form__page_1__next_button"),
              onPressed:
                  _userStageSubmitting ? null : () => _handleUserStageNext(),
              child: _userStageSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))
                  : Text(widget.isFinalizing ? "Submit" : "Create account"),
            ),
          );
        case 1:
          return buildNavigationRow(
            next: ElevatedButton(
              key: const Key("register_user_form__page_2__next_button"),
              onPressed: _handleCompanyPageNext,
              child: Text("Next"),
            ),
          );
        case 2:
          return buildNavigationRow(
            previous: ElevatedButton(
              key: const Key("register_user_form__page_3__previous_button"),
              onPressed: previousPage,
              style: previousButtonStyle,
              child: Text("Previous"),
            ),
            next: ElevatedButton(
              key: const Key("register_user_form__submit_button"),
              onPressed: () => _handleSubmitPressed(context),
              child: Text("Finish"),
            ),
          );
        default:
          return Row(children: const []);
      }
    }

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    return Scaffold(
        appBar: PrimaryNavigationBar(
          backgroundColor: Colors.transparent,
          iconColor: BeColorSwatch.navy,
          showCancelAction: widget.isFinalizing,
          showOptions: false,
          title: "",
        ),
        key: RegistrationForm.rootKey,
        body: PopScope(
            onPopInvoked: _handleRegistrationPop,
            child: Stack(children: [
              Positioned.fill(
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                         *  Header
                         */
                            Transform.translate(
                                offset: Offset(0, -35),
                                child: RichText(
                                    text: TextSpan(
                                        style: beTextTheme.titleLarge.merge(
                                            TextStyle(
                                                fontSize: 56, height: 0.95)),
                                        children: widget.title != null
                                            ? [
                                                TextSpan(
                                                    text: widget.title,
                                                    style: TextStyle(
                                                        color: BeColorSwatch
                                                            .navy)),
                                              ]
                                            : [
                                                TextSpan(
                                                    text: "Build ",
                                                    style: TextStyle(
                                                        color:
                                                            BeColorSwatch.red)),
                                                TextSpan(
                                                    text:
                                                        "Your \nBusiness Profile.",
                                                    style: TextStyle(
                                                        color: BeColorSwatch
                                                            .navy)),
                                              ]))),

                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                         *  Form
                         */
                            Expanded(
                                child: Form(
                                    key: _currentFormKey,
                                    child: Stack(children: [
                                      ListView(
                                          controller: _scrollController,
                                          padding: EdgeInsets.zero,
                                          children: () {
                                            var output = <Widget>[
                                              const SizedBox(height: 56)
                                            ];

                                            var contactPageContent = [
                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Name Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "What's your name?",
                                                  isRequired: true),

                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    // First name
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText:
                                                                  "First name",
                                                              isRequired: true),
                                                          Container(
                                                              key: const Key(
                                                                  "register_user_form__first_name_field"),
                                                              child:
                                                                  TextFormField(
                                                                      controller:
                                                                          _fieldData["first_name"]?[
                                                                              "controller"],
                                                                      key: _fieldData["first_name"]
                                                                          ?[
                                                                          "key"],
                                                                      autovalidateMode:
                                                                          AutovalidateMode
                                                                              .onUserInteraction,
                                                                      decoration: InputDecoration(
                                                                          hintText:
                                                                              "John",
                                                                          hintStyle:
                                                                              gfieldHintStyle),
                                                                      enabled:
                                                                          true,
                                                                      enableSuggestions:
                                                                          false,
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .name,
                                                                      obscureText:
                                                                          false,
                                                                      validator:
                                                                          (String?
                                                                              value) {
                                                                        if (value ==
                                                                                null ||
                                                                            value.isEmpty) {
                                                                          return "This field is required.";
                                                                        }
                                                                        return null;
                                                                      }))
                                                        ])),
                                                    fieldHorizontalSpacer,

                                                    // Last name
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText:
                                                                  "Last name",
                                                              isRequired: true),
                                                          Container(
                                                              key: const Key(
                                                                  "register_user_form__last_name_field"),
                                                              child:
                                                                  TextFormField(
                                                                      controller:
                                                                          _fieldData["last_name"]?[
                                                                              "controller"],
                                                                      key: _fieldData["last_name"]
                                                                          ?[
                                                                          "key"],
                                                                      autovalidateMode:
                                                                          AutovalidateMode
                                                                              .onUserInteraction,
                                                                      decoration: InputDecoration(
                                                                          hintText:
                                                                              "Smith",
                                                                          hintStyle:
                                                                              gfieldHintStyle),
                                                                      enabled:
                                                                          true,
                                                                      enableSuggestions:
                                                                          false,
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .name,
                                                                      obscureText:
                                                                          false,
                                                                      validator:
                                                                          (String?
                                                                              value) {
                                                                        if (value ==
                                                                                null ||
                                                                            value.isEmpty) {
                                                                          return "This field is required.";
                                                                        }
                                                                        return null;
                                                                      }))
                                                        ]))
                                                  ]),
                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Email Address Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "What's your email?",
                                                  isRequired: true),
                                              // formFieldLabel(labelText:  "Email address",
                                              //                isRequired: true
                                              // ),

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__email_address_field"),
                                                  child: TextFormField(
                                                      controller:
                                                          _fieldData["email"]
                                                              ?["controller"],
                                                      key: _fieldData["email"]
                                                          ?["key"],
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      decoration: InputDecoration(
                                                          hintText:
                                                              "name@example.com",
                                                          hintStyle:
                                                              gfieldHintStyle),
                                                      enabled: true,
                                                      enableSuggestions: false,
                                                      keyboardType:
                                                          TextInputType
                                                              .emailAddress,
                                                      obscureText: false,
                                                      validator:
                                                          (String? value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return "This field is required.";
                                                        }
                                                        return null;
                                                      })),
                                              if (_emailDuplicateDetected)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton(
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      onPressed:
                                                          _launchPasswordReset,
                                                      child: Text(
                                                        'Forgot your password? Reset it here.',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                                color: BeColorSwatch
                                                                    .blue),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Phone Number Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "What's your phone number?",
                                                  isRequired: false),
                                              // formFieldLabel(labelText:  "Phone number",
                                              //                isRequired: false
                                              // ),

                                              Container(
                                                key: const Key(
                                                    "register_user_form__phone_number_field"),
                                                child:
                                                    InternationalPhoneNumberInput(
                                                  key: _fieldData["phone"]
                                                      ?["key"],
                                                  textFieldController:
                                                      _fieldData["phone"]
                                                          ?["controller"],
                                                  ignoreBlank: true,
                                                  autoValidateMode:
                                                      AutovalidateMode.disabled,
                                                  initialValue:
                                                      _buildInitialPhoneNumber(
                                                    isoField:
                                                        _fieldData["phone_iso"],
                                                    phoneField:
                                                        _fieldData["phone"],
                                                    fallbackIso:
                                                        _previousPhoneIsoCode,
                                                  ),
                                                  selectorConfig:
                                                      const SelectorConfig(
                                                    selectorType:
                                                        PhoneInputSelectorType
                                                            .DROPDOWN,
                                                    setSelectorButtonAsPrefixIcon:
                                                        true,
                                                    trailingSpace: false,
                                                  ),
                                                  inputDecoration:
                                                      InputDecoration(
                                                    hintText: "(123) 555-1234",
                                                    hintStyle: gfieldHintStyle,
                                                    enabledBorder:
                                                        gfieldRoundedBorder,
                                                    focusedBorder: gfieldRoundedBorder.copyWith(
                                                        borderSide: gfieldRoundedBorder
                                                            .borderSide
                                                            .copyWith(
                                                                color:
                                                                    BeColorSwatch
                                                                        .blue,
                                                                width:
                                                                    gfieldRoundedBorderWidth +
                                                                        0.5)),
                                                    errorBorder: gfieldRoundedBorder.copyWith(
                                                        borderSide: gfieldRoundedBorder
                                                            .borderSide
                                                            .copyWith(
                                                                color:
                                                                    BeColorSwatch
                                                                        .red,
                                                                width:
                                                                    gfieldRoundedBorderWidth)),
                                                    filled: true,
                                                    fillColor:
                                                        BeColorSwatch.offWhite,
                                                    contentPadding:
                                                        gfieldHorizontalPadding,
                                                  ),
                                                  // autoValidateMode: AutovalidateMode.onUserInteraction,
                                                  onInputChanged:
                                                      (PhoneNumber number) {
                                                    final isoCode =
                                                        number.isoCode;
                                                    final dialCode =
                                                        _numericDialCode(
                                                            number);

                                                    if (isoCode != null &&
                                                        isoCode !=
                                                            _previousPhoneIsoCode) {
                                                      _previousPhoneIsoCode =
                                                          isoCode;
                                                    }

                                                    if (isoCode != null) {
                                                      _fieldData["phone_iso"]
                                                              ?["iso_code"] =
                                                          isoCode;
                                                    } else {
                                                      _fieldData["phone_iso"]
                                                          ?.remove("iso_code");
                                                    }

                                                    if (dialCode != null) {
                                                      _fieldData["phone_iso"]
                                                          ?["value"] = dialCode;
                                                      _fieldData["phone_iso"]
                                                              ?["dial_code"] =
                                                          "+$dialCode";
                                                    } else {
                                                      _fieldData["phone_iso"]
                                                          ?.remove("value");
                                                      _fieldData["phone_iso"]
                                                          ?.remove("dial_code");
                                                    }

                                                    // Store parsed E.164 phone number without mutating the controller to avoid duplication
                                                    final formatted =
                                                        _formatPhoneWithIsoPrefix(
                                                            number);
                                                    _fieldData["phone"]
                                                            ?["value"] =
                                                        formatted.isEmpty
                                                            ? null
                                                            : formatted;
                                                  },
                                                  // onInputValidated: (bool isValid) {},
                                                  // validator: (String? value) {
                                                  //     if (value == null || value.trim().isEmpty) {
                                                  //         return "This field is required.";
                                                  //     }
                                                  //     return null;
                                                  // },
                                                  selectorTextStyle:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                  formatInput: false,
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                          signed: true,
                                                          decimal: false),
                                                  spaceBetweenSelectorAndTextField:
                                                      8,
                                                  validator: (_) => null,
                                                  countrySelectorScrollControlled:
                                                      true,
                                                ),
                                              ),
                                              verticalSpacerSmall,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: SMS Consent Field
                                                     */
                                              Container(
                                                  child: FormField<bool>(
                                                      key: _fieldData[
                                                              "sms_consent"]
                                                          ?["key"],
                                                      builder: (state) {
                                                        return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  spacing: 8,
                                                                  children: <Widget>[
                                                                    Container(
                                                                        width:
                                                                            36,
                                                                        child: CheckboxListTile(
                                                                            key: const Key("register_user_form__sms_consent_checkbox"),
                                                                            checkboxScaleFactor: 1.4,
                                                                            side: (_fieldData["sms_consent"]?["key"]?.currentState?.validate() ?? true) ? null : null,
                                                                            onChanged: (value) {
                                                                              setState(() {
                                                                                var newFieldData = _fieldData;
                                                                                newFieldData["sms_consent"]?["value"] = value;
                                                                              });
                                                                            },
                                                                            value: _fieldData["sms_consent"]?["value"] ?? false)),
                                                                    Flexible(
                                                                        child: RichText(
                                                                            text: TextSpan(children: [
                                                                              TextSpan(text: "I want to receive SMS notifications from Build Expo USA. "),
                                                                              TextSpan(text: "You can adjust this later in your account settings.", style: TextStyle(fontStyle: FontStyle.italic, color: BeColorSwatch.darkGray.withAlpha(200))),
                                                                            ], style: Theme.of(context).textTheme.bodyMedium!),
                                                                            softWrap: true)),
                                                                  ]),
                                                              Text(
                                                                  state.errorText ??
                                                                      "",
                                                                  style: TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .error,
                                                                      fontSize: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodySmall!
                                                                          .fontSize))
                                                            ]);
                                                      })),

                                              verticalSpacerSmall,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Password Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "Choose a password",
                                                  isRequired: true),

                                              Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 8, right: 4),
                                                  child: Text(
                                                      "Set the password you want to use to sign in to the Build Expo USA app and website.",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                              color: BeColorSwatch
                                                                  .darkGray))),

                                              verticalSpacerSmall,

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__password_field"),
                                                  child: TextFormField(
                                                      controller:
                                                          _fieldData["password"]
                                                              ?["controller"],
                                                      key:
                                                          _fieldData["password"]
                                                              ?["key"],
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "Password",
                                                        hintStyle:
                                                            gfieldHintStyle,
                                                        suffixIcon: IconButton(
                                                          icon: SFIcon(
                                                            _isPasswordVisible
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
                                                              _isPasswordVisible =
                                                                  !_isPasswordVisible;
                                                            });
                                                          },
                                                          style: ButtonStyle(
                                                              splashFactory:
                                                                  NoSplash
                                                                      .splashFactory),
                                                        ),
                                                      ),
                                                      enabled: true,
                                                      enableSuggestions: false,
                                                      keyboardType:
                                                          TextInputType
                                                              .visiblePassword,
                                                      obscureText:
                                                          !_isPasswordVisible,
                                                      validator:
                                                          (String? value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return "This field is required.";
                                                        } else if (value
                                                                .length <
                                                            8) {
                                                          return "Passwords must be at least 8 characters long.";
                                                        } else if (!RegExp(
                                                                r"\d")
                                                            .hasMatch(value)) {
                                                          return "Passwords must include at least one number.";
                                                        } else if (!RegExp(
                                                                r"[^A-Za-z0-9]")
                                                            .hasMatch(value)) {
                                                          return "Passwords must include at least one symbol.";
                                                        }

                                                        return null;
                                                      })),

                                              verticalSpacerSmall,

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__password_confirmation_field"),
                                                  child: TextFormField(
                                                      controller: _fieldData[
                                                              "password_confirm"]
                                                          ?["controller"],
                                                      key: _fieldData[
                                                              "password_confirm"]
                                                          ?["key"],
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      decoration: InputDecoration(
                                                          hintText:
                                                              "Confirm password",
                                                          hintStyle:
                                                              gfieldHintStyle),
                                                      enabled: true,
                                                      enableSuggestions: false,
                                                      keyboardType:
                                                          TextInputType
                                                              .visiblePassword,
                                                      obscureText: true,
                                                      validator:
                                                          (String? value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return "This field is required.";
                                                        } else if (value !=
                                                            _fieldData["password"]
                                                                    ?[
                                                                    "controller"]
                                                                .text) {
                                                          return "Passwords do not match.";
                                                        }
                                                        return null;
                                                      })),

                                              const SizedBox(height: 6),

                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 8),
                                                  child: Text(
                                                      "Passwords must contain at least 8 characters, including 1 number and 1 symbol",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                              color: BeColorSwatch
                                                                  .darkGray))),

                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Contact Consent Field
                                                     */
                                              Container(
                                                  child: FormField<bool>(
                                                key: _fieldData[
                                                    "contact_consent"]?["key"],
                                                builder: (state) {
                                                  return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            spacing: 8,
                                                            children: <Widget>[
                                                              Container(
                                                                  width: 36,
                                                                  child: CheckboxListTile(
                                                                      key: const Key("register_user_form__contact_consent_checkbox"),
                                                                      checkboxScaleFactor: 1.4,
                                                                      side: (_fieldData["contact_consent"]?["key"]?.currentState?.validate() ?? true) ? null : null, //gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red),
                                                                      onChanged: (value) {
                                                                        setState(
                                                                            () {
                                                                          var newFieldData =
                                                                              _fieldData;
                                                                          newFieldData["contact_consent"]
                                                                              ?[
                                                                              "value"] = value;
                                                                        });
                                                                      },
                                                                      value: _fieldData["contact_consent"]?["value"] ?? false)),
                                                              Flexible(
                                                                  child: Text(
                                                                      "Build Expo USA may contact me about my account.",
                                                                      softWrap:
                                                                          true)),
                                                            ]),
                                                        Text(
                                                            state
                                                                    .errorText ??
                                                                "",
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error,
                                                                fontSize: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall!
                                                                    .fontSize))
                                                      ]);
                                                },
                                                validator: (value) {
                                                  if (!_fieldData[
                                                          "contact_consent"]
                                                      ?["value"]) {
                                                    return "This field is required.";
                                                  }
                                                  return null;
                                                },
                                              )),

                                              const SizedBox(height: 64),
                                            ];

                                            var addressPageContent = [
                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Address Fields
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "Where's your company located?",
                                                  isRequired: true),

                                              formFieldLabel(
                                                  labelText: "Street address",
                                                  isRequired: true),

                                              // Street address field
                                              Container(
                                                key: const Key(
                                                    "register_user_form__address_field"),
                                                child: TextFormField(
                                                    controller:
                                                        _fieldData["address"]
                                                            ?["controller"],
                                                    key: _fieldData["address"]
                                                        ?["key"],
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    decoration: InputDecoration(
                                                        hintText: "123 Main St",
                                                        hintStyle:
                                                            gfieldHintStyle),
                                                    keyboardType: TextInputType
                                                        .streetAddress,
                                                    validator: (String? value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return "This field is required.";
                                                      }
                                                      return null;
                                                    }),
                                              ),
                                              verticalSpacerSmall,

                                              // Street address line 2 label
                                              formFieldLabel(
                                                  labelText: "",
                                                  isRequired: false),

                                              // Street address line 2 field
                                              Container(
                                                  key: const Key(
                                                      "register_user_form__address_2_field"),
                                                  child: TextFormField(
                                                    controller:
                                                        _fieldData["address_2"]
                                                            ?["controller"],
                                                    key: _fieldData["address_2"]
                                                        ?["key"],
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    decoration: InputDecoration(
                                                        hintText:
                                                            "Building A, Unit 1",
                                                        hintStyle:
                                                            gfieldHintStyle),
                                                    keyboardType: TextInputType
                                                        .streetAddress,
                                                  )),
                                              verticalSpacerSmall,

                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // City
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText: "City",
                                                              isRequired: true),
                                                          Container(
                                                              key: const Key(
                                                                  "register_user_form__city_field"),
                                                              child:
                                                                  TextFormField(
                                                                      controller:
                                                                          _fieldData["city"]
                                                                              ?[
                                                                              "controller"],
                                                                      key: _fieldData[
                                                                              "city"]
                                                                          ?[
                                                                          "key"],
                                                                      autovalidateMode:
                                                                          AutovalidateMode
                                                                              .onUserInteraction,
                                                                      decoration: InputDecoration(
                                                                          hintText:
                                                                              "Austin",
                                                                          hintStyle:
                                                                              gfieldHintStyle),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .name,
                                                                      validator:
                                                                          (String?
                                                                              value) {
                                                                        if (value ==
                                                                                null ||
                                                                            value.isEmpty) {
                                                                          return "This field is required.";
                                                                        }
                                                                        return null;
                                                                      }))
                                                        ])),
                                                    fieldHorizontalSpacer,

                                                    // State
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText:
                                                                  "State",
                                                              isRequired: true),
                                                          Container(
                                                            key: const Key(
                                                                "register_user_form__state_field"),
                                                            child: Builder(
                                                                builder:
                                                                    (context) {
                                                              final TextEditingController?
                                                                  stateController =
                                                                  _fieldData["state"]
                                                                          ?[
                                                                          "controller"]
                                                                      as TextEditingController?;
                                                              final GlobalKey<
                                                                      FormFieldState>?
                                                                  stateKey =
                                                                  _fieldData["state"]
                                                                          ?[
                                                                          "key"]
                                                                      as GlobalKey<
                                                                          FormFieldState>?;
                                                              final String?
                                                                  currentValue =
                                                                  (stateController !=
                                                                              null &&
                                                                          stateController
                                                                              .text
                                                                              .isNotEmpty)
                                                                      ? stateController
                                                                          .text
                                                                      : null;
                                                              final bool
                                                                  isUnitedStates =
                                                                  _isUnitedStatesSelected;

                                                              if (!isUnitedStates) {
                                                                return TextFormField(
                                                                  key: stateKey,
                                                                  controller:
                                                                      stateController,
                                                                  autovalidateMode:
                                                                      AutovalidateMode
                                                                          .onUserInteraction,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    hintText:
                                                                        "State/Province/Region",
                                                                    hintStyle:
                                                                        gfieldHintStyle,
                                                                  ),
                                                                  validator:
                                                                      (String?
                                                                          value) {
                                                                    if (value ==
                                                                            null ||
                                                                        value
                                                                            .isEmpty) {
                                                                      return "This field is required.";
                                                                    }
                                                                    return null;
                                                                  },
                                                                );
                                                              }

                                                              return Theme(
                                                                data: Theme.of(
                                                                        context)
                                                                    .copyWith(
                                                                  popupMenuTheme:
                                                                      PopupMenuThemeData(
                                                                    color: Colors
                                                                        .white,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                    ),
                                                                    elevation:
                                                                        4,
                                                                  ),
                                                                ),
                                                                child:
                                                                    DropdownButtonFormField<
                                                                        String>(
                                                                  key: stateKey,
                                                                  value:
                                                                      currentValue,
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium!
                                                                      .copyWith(
                                                                          height:
                                                                              2),
                                                                  dropdownColor:
                                                                      Colors
                                                                          .white,
                                                                  isExpanded:
                                                                      true,
                                                                  items: usStates
                                                                      .entries
                                                                      .map(
                                                                          (entry) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value: entry
                                                                          .key,
                                                                      child:
                                                                          Text(
                                                                        entry
                                                                            .value,
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .bodyMedium,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            1,
                                                                        softWrap:
                                                                            false,
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                  decoration:
                                                                      InputDecoration(
                                                                    hintText:
                                                                        "Select a state",
                                                                    hintStyle:
                                                                        gfieldHintStyle,
                                                                  ),
                                                                  autovalidateMode:
                                                                      AutovalidateMode
                                                                          .onUserInteraction,
                                                                  onChanged:
                                                                      (String?
                                                                          code) {
                                                                    setState(
                                                                        () {
                                                                      if (stateController !=
                                                                          null) {
                                                                        stateController.text =
                                                                            code ??
                                                                                "";
                                                                      } else {
                                                                        _fieldData["state"]
                                                                            ?[
                                                                            "value"] = code;
                                                                      }
                                                                    });
                                                                  },
                                                                  validator:
                                                                      (String?
                                                                          value) {
                                                                    if (value ==
                                                                            null ||
                                                                        value
                                                                            .isEmpty) {
                                                                      return "This field is required.";
                                                                    }
                                                                    return null;
                                                                  },
                                                                ),
                                                              );
                                                            }),
                                                          )
                                                        ]))
                                                  ]),
                                              verticalSpacerSmall,

                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Postal code
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText:
                                                                  "ZIP/Postal code",
                                                              isRequired: true),
                                                          Container(
                                                              key: const Key(
                                                                  "register_user_form__zip_field"),
                                                              child:
                                                                  TextFormField(
                                                                      controller:
                                                                          _fieldData["zip"]
                                                                              ?[
                                                                              "controller"],
                                                                      key: _fieldData[
                                                                              "zip"]
                                                                          ?[
                                                                          "key"],
                                                                      autovalidateMode:
                                                                          AutovalidateMode
                                                                              .onUserInteraction,
                                                                      decoration: InputDecoration(
                                                                          hintText:
                                                                              "12345",
                                                                          hintStyle:
                                                                              gfieldHintStyle),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .number,
                                                                      validator:
                                                                          (String?
                                                                              value) {
                                                                        if (value ==
                                                                                null ||
                                                                            value.isEmpty) {
                                                                          return "This field is required.";
                                                                        }
                                                                        return null;
                                                                      }))
                                                        ])),
                                                    fieldHorizontalSpacer,

                                                    // Country
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          formFieldLabel(
                                                              labelText:
                                                                  "Country",
                                                              isRequired: true),

                                                          TextFormField(
                                                              key: const Key(
                                                                  "register_user_form__country_field"),
                                                              decoration:
                                                                  gfieldInputDecoration
                                                                      .copyWith(
                                                                fillColor:
                                                                    BeColorSwatch
                                                                        .white,
                                                                hintText:
                                                                    "Select a country",
                                                                hintStyle:
                                                                    gfieldHintStyle,
                                                                suffixIcon:
                                                                    const Icon(Icons
                                                                        .arrow_drop_down),
                                                              ),
                                                              style: TextStyle(
                                                                color:
                                                                    BeColorSwatch
                                                                        .black,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                              readOnly: true,
                                                              controller: _fieldData[
                                                                      "country"]
                                                                  ?[
                                                                  "controller"],
                                                              onTap: () {
                                                                showCountryPicker(
                                                                  context:
                                                                      context,
                                                                  countryListTheme:
                                                                      const CountryListThemeData(
                                                                    margin: EdgeInsets.only(
                                                                        top: 24,
                                                                        right:
                                                                            24,
                                                                        left:
                                                                            24),
                                                                  ),
                                                                  showPhoneCode:
                                                                      false,
                                                                  useSafeArea:
                                                                      true,
                                                                  onSelect: (Country
                                                                      country) {
                                                                    var previousCountryCode =
                                                                        _fieldData["country_code"]?["controller"]
                                                                            .text;
                                                                    setState(
                                                                        () {
                                                                      final String
                                                                          selectedCode =
                                                                          country
                                                                              .countryCode
                                                                              .toUpperCase();

                                                                      (_fieldData["country"]?["controller"] as TextEditingController?)
                                                                              ?.text =
                                                                          country
                                                                              .name;
                                                                      (_fieldData["country_code"]
                                                                              ?[
                                                                              "controller"] as TextEditingController?)
                                                                          ?.text = selectedCode;
                                                                      _fieldData["country"]
                                                                              ?[
                                                                              "value"] =
                                                                          selectedCode;
                                                                      _fieldData["country_code"]
                                                                              ?[
                                                                              "value"] =
                                                                          selectedCode;

                                                                      if ((previousCountryCode == "US" &&
                                                                              selectedCode !=
                                                                                  "US") ||
                                                                          (previousCountryCode != "US" &&
                                                                              selectedCode == "US")) {
                                                                        (_fieldData["state"]?["controller"]
                                                                                as TextEditingController?)
                                                                            ?.text = '';
                                                                        _fieldData["state"]
                                                                            ?[
                                                                            "value"] = '';
                                                                      }
                                                                    });
                                                                  },
                                                                );
                                                              },
                                                              validator:
                                                                  (value) {
                                                                final String
                                                                    countryText =
                                                                    (_fieldData["country"]?["controller"]
                                                                                as TextEditingController?)
                                                                            ?.text ??
                                                                        "";
                                                                if (countryText
                                                                    .isEmpty) {
                                                                  return "This field is required.";
                                                                }
                                                                return null;
                                                              }),

                                                          // Hidden field to ensure country_code participates in validation
                                                          SizedBox(
                                                              height: 0,
                                                              width: 0,
                                                              child:
                                                                  TextFormField(
                                                                      key: _fieldData[
                                                                              "country_code"]
                                                                          ?[
                                                                          "key"],
                                                                      controller: _fieldData[
                                                                              "country_code"]
                                                                          ?[
                                                                          "controller"],
                                                                      readOnly:
                                                                          true,
                                                                      decoration: const InputDecoration(
                                                                          isCollapsed:
                                                                              true,
                                                                          border: InputBorder
                                                                              .none),
                                                                      validator:
                                                                          (value) {
                                                                        if ((value ??
                                                                                "")
                                                                            .isEmpty) {
                                                                          return "";
                                                                        }
                                                                        return null;
                                                                      }))
                                                        ]))
                                                  ]),
                                              const SizedBox(height: 8),

                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                child: Text(
                                                    "Badges will be shipped to this address unless specified otherwise. The mailing address can be set per-badge.",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            color: BeColorSwatch
                                                                .darkGray)),
                                              ),
                                              const SizedBox(height: 28),

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Job Title Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "What do you do at your company?",
                                                  isRequired: true),
                                              // formFieldLabel(
                                              //     labelText:  "Job title",
                                              //     isRequired: true
                                              // ),

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__job_title_field"),
                                                  child: TextFormField(
                                                      controller: _fieldData[
                                                              "job_title"]
                                                          ?["controller"],
                                                      key: _fieldData[
                                                          "job_title"]?["key"],
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      decoration: InputDecoration(
                                                          hintText: "Owner",
                                                          hintStyle:
                                                              gfieldHintStyle),
                                                      enabled: true,
                                                      enableSuggestions: false,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      obscureText: false,
                                                      validator:
                                                          (String? value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return "This field is required.";
                                                        }
                                                        return null;
                                                      })),
                                              verticalSpacerLarge,
                                            ];

                                            var companyPageContent = [
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8),
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!
                                                        .copyWith(
                                                            color: BeColorSwatch
                                                                .darkGray),
                                                    children: const [
                                                      TextSpan(
                                                        text:
                                                            "Next, let's set up your company profile. This will be used while networking with exhibitors. ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            "If your company is already in our system, ask the person who set it up to send you an invite to join. If you are not sure, give us a call!",
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Company Name Field
                                                     */
                                              formFieldDescription(
                                                  descriptionText:
                                                      "What's your company's name?",
                                                  isRequired: true),
                                              // formFieldLabel(labelText:  "Company name",
                                              //                isRequired: true
                                              // ),

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__company_field"),
                                                  child: TextFormField(
                                                      controller: _fieldData[
                                                              "company_name"]
                                                          ?["controller"],
                                                      key: _fieldData[
                                                              "company_name"]
                                                          ?["key"],
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      decoration: InputDecoration(
                                                          hintText:
                                                              "Example Corp.",
                                                          hintStyle:
                                                              gfieldHintStyle),
                                                      enabled:
                                                          !widget.isFinalizing,
                                                      enableSuggestions: false,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      obscureText: false,
                                                      validator:
                                                          (String? value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return "This field is required.";
                                                        }
                                                        return null;
                                                      })),

                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8,
                                                    right: 8,
                                                    bottom: 0,
                                                    left: 8),
                                                child: Text(
                                                    "If you are an independent contractor, please enter your DBA name or full name here.",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            color: BeColorSwatch
                                                                .darkGray)),
                                              ),
                                              verticalSpacerMedium,

                                              formFieldDescription(
                                                  descriptionText:
                                                      "How can we contact your company?",
                                                  isRequired: true),

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Company Email Field
                                                     */
                                              formFieldLabel(
                                                  labelText:
                                                      "Company email address",
                                                  isRequired: true),

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__company_email_field"),
                                                  child: TextFormField(
                                                    controller: _fieldData[
                                                            "company_email"]
                                                        ?["controller"],
                                                    key: _fieldData[
                                                            "company_email"]
                                                        ?["key"],
                                                    validator: (String? value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return "This field is required.";
                                                      }
                                                      return null;
                                                    },
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    decoration: InputDecoration(
                                                        hintText:
                                                            "info@example.com",
                                                        hintStyle:
                                                            gfieldHintStyle),
                                                    enabled: true,
                                                    enableSuggestions: false,
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    obscureText: false,
                                                  )),
                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Company Phone Field
                                                     */
                                              formFieldLabel(
                                                labelText:
                                                    "Company phone number",
                                                isRequired: true,
                                              ),
                                              Container(
                                                key: const Key(
                                                    "register_user_form__company_phone_field"),
                                                child:
                                                    InternationalPhoneNumberInput(
                                                  key: _fieldData[
                                                      "company_phone"]?["key"],
                                                  textFieldController:
                                                      _fieldData[
                                                              "company_phone"]
                                                          ?["controller"],
                                                  initialValue:
                                                      _buildInitialPhoneNumber(
                                                    isoField: _fieldData[
                                                        "company_phone_iso"],
                                                    phoneField: _fieldData[
                                                        "company_phone"],
                                                    fallbackIso:
                                                        _previousCompanyPhoneIsoCode,
                                                  ),
                                                  selectorConfig:
                                                      const SelectorConfig(
                                                    selectorType:
                                                        PhoneInputSelectorType
                                                            .DROPDOWN,
                                                    setSelectorButtonAsPrefixIcon:
                                                        true,
                                                    trailingSpace: false,
                                                  ),
                                                  inputDecoration:
                                                      InputDecoration(
                                                    hintText: "(123) 555-1234",
                                                    hintStyle: gfieldHintStyle,
                                                    focusedBorder: gfieldRoundedBorder.copyWith(
                                                        borderSide: gfieldRoundedBorder
                                                            .borderSide
                                                            .copyWith(
                                                                color:
                                                                    BeColorSwatch
                                                                        .blue,
                                                                width:
                                                                    gfieldRoundedBorderWidth +
                                                                        0.5)),
                                                    enabledBorder:
                                                        gfieldRoundedBorder,
                                                    errorBorder: gfieldRoundedBorder.copyWith(
                                                        borderSide: gfieldRoundedBorder
                                                            .borderSide
                                                            .copyWith(
                                                                color:
                                                                    BeColorSwatch
                                                                        .red,
                                                                width:
                                                                    gfieldRoundedBorderWidth)),
                                                    filled: true,
                                                    fillColor:
                                                        BeColorSwatch.offWhite,
                                                    contentPadding:
                                                        gfieldHorizontalPadding,
                                                  ),
                                                  autoValidateMode:
                                                      AutovalidateMode.disabled,
                                                  onInputChanged:
                                                      (PhoneNumber number) {
                                                    final isoCode =
                                                        number.isoCode;
                                                    final dialCode =
                                                        _numericDialCode(
                                                            number);

                                                    if (isoCode != null &&
                                                        isoCode !=
                                                            _previousCompanyPhoneIsoCode) {
                                                      _previousCompanyPhoneIsoCode =
                                                          isoCode;
                                                    }

                                                    if (isoCode != null) {
                                                      _fieldData[
                                                              "company_phone_iso"]
                                                          ?[
                                                          "iso_code"] = isoCode;
                                                    } else {
                                                      _fieldData[
                                                              "company_phone_iso"]
                                                          ?.remove("iso_code");
                                                    }

                                                    if (dialCode != null) {
                                                      _fieldData[
                                                              "company_phone_iso"]
                                                          ?["value"] = dialCode;
                                                      _fieldData["company_phone_iso"]
                                                              ?["dial_code"] =
                                                          "+$dialCode";
                                                    } else {
                                                      _fieldData[
                                                              "company_phone_iso"]
                                                          ?.remove("value");
                                                      _fieldData[
                                                              "company_phone_iso"]
                                                          ?.remove("dial_code");
                                                    }

                                                    // Store parsed E.164 phone number without mutating the controller to avoid duplication
                                                    final formatted =
                                                        _formatPhoneWithIsoPrefix(
                                                            number);
                                                    _fieldData["company_phone"]
                                                            ?["value"] =
                                                        formatted.isEmpty
                                                            ? null
                                                            : formatted;
                                                  },
                                                  onInputValidated:
                                                      (bool isValid) {},
                                                  validator: (String? value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return "This field is required.";
                                                    }
                                                    return null;
                                                  },
                                                  selectorTextStyle:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                  formatInput: false,
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                          signed: true,
                                                          decimal: false),
                                                  spaceBetweenSelectorAndTextField:
                                                      8,
                                                  countrySelectorScrollControlled:
                                                      true,
                                                ),
                                              ),

                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8,
                                                    right: 8,
                                                    bottom: 0,
                                                    left: 8),
                                                child: Text(
                                                    "This is required to verify your organization, manage your company account, and interact with leads.",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            color: BeColorSwatch
                                                                .darkGray)),
                                              ),
                                              verticalSpacerMedium,

                                              /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                                     * MARK: Company Website Field
                                                     */
                                              formFieldLabel(
                                                  labelText: "Website"),

                                              Container(
                                                  key: const Key(
                                                      "register_user_form__company_website_field"),
                                                  child: TextFormField(
                                                    controller: _fieldData[
                                                            "company_website"]
                                                        ?["controller"],
                                                    key: _fieldData[
                                                            "company_website"]
                                                        ?["key"],
                                                    autovalidateMode:
                                                        AutovalidateMode
                                                            .onUserInteraction,
                                                    decoration: InputDecoration(
                                                        hintText:
                                                            "https://www.example.com",
                                                        hintStyle:
                                                            gfieldHintStyle),
                                                    enabled: true,
                                                    enableSuggestions: false,
                                                    keyboardType:
                                                        TextInputType.text,
                                                    obscureText: false,
                                                  )),
                                              const SizedBox(height: 64),
                                            ];

                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                             * MARK: Page Logic
                                             */
                                            if (pageIndex == 0) {
                                              output.addAll([
                                                ...contactPageContent,
                                                buildBottomControls()
                                              ]);
                                            }

                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                             *  Page break
                                             */
                                            if (pageIndex == 1) {
                                              output.addAll([
                                                ...companyPageContent,
                                                buildBottomControls()
                                              ]);
                                            }

                                            /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                             *  Page break
                                             */
                                            if (pageIndex == 2) {
                                              output.addAll([
                                                ...addressPageContent,
                                                buildBottomControls()
                                              ]);
                                            }
                                            output.add(SizedBox(
                                                height: isKeyboardVisible
                                                    ? 80
                                                    : 140));
                                            return output;
                                          }()),

                                      /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                         *  Progress bar
                                         */
                                      Transform.translate(
                                          offset: Offset(0, -40),
                                          child: Container(
                                              alignment:
                                                  AlignmentDirectional.center,
                                              decoration:  BoxDecoration(
                                                  gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                    BeColorSwatch.lighterGray,
                                                    BeColorSwatch.lighterGray.withAlpha(0),
                                                  ],
                                                      stops: [
                                                    0.45,
                                                    0.85
                                                  ])),
                                              height: progressBarHeight + 72,
                                              padding: EdgeInsets.only(top: 3),
                                              width: double.maxFinite,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: () {
                                                    List<Widget> output = [];

                                                    output.add(Stack(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        children: () {
                                                          List<Widget> output =
                                                              [];

                                                          // Empty progress bar
                                                          output.add(Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color:
                                                                        BeColorSwatch
                                                                            .red,
                                                                    width: 2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            16),
                                                                color: BeColorSwatch
                                                                    .lightGray,
                                                              ),
                                                              child: SizedBox(
                                                                  height:
                                                                      progressBarHeight,
                                                                  width:
                                                                      progressBarWidth)));

                                                          // Progress indicator
                                                          output.add(ClipPath(
                                                              clipper: SkewCut(
                                                                  left: false,
                                                                  right: true),
                                                              child: Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius: BorderRadius.only(
                                                                        topLeft:
                                                                            Radius.circular(
                                                                                16),
                                                                        bottomLeft:
                                                                            Radius.circular(16)),
                                                                    color:
                                                                        BeColorSwatch
                                                                            .red,
                                                                  ),
                                                                  child: SizedBox(
                                                                      height:
                                                                          (progressBarHeight +
                                                                              2),
                                                                      width: ((progressBarWidth *
                                                                              ((pageIndex + 1) /
                                                                                  totalPageCount) -
                                                                          (pageIndicatorWidth -
                                                                              20 / 2)))))));
                                                          return output;
                                                        }()));

                                                    output.add(Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 4),
                                                        child: RichText(
                                                            text: TextSpan(
                                                                style: beTextTheme
                                                                    .bodyPrimary
                                                                    .merge(TextStyle(
                                                                        color: BeColorSwatch
                                                                            .darkGray,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold)),
                                                                children: [
                                                                  TextSpan(
                                                                    text:
                                                                        "Step ${pageIndex + 1} of ${totalPageCount}",
                                                                  ),
                                                                  // (ref.read(gformValidationMessageProvider)[widget.formId]?.keys.isNotEmpty ?? false) ? TextSpan(text: " | ${ref.read(gformValidationMessageProvider)[widget.formId]?.keys.length ?? 0} Errors", style: TextStyle(color: BeColorSwatch.red)) : null
                                                                ]
                                                                    .nonNulls
                                                                    .toList()))));
                                                    return output;
                                                  }())))
                                    ])))
                          ]))),
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(
                        bottom: isKeyboardVisible ? 8 : 20,
                      ),
                      child: SafeArea(
                          top: false,
                          minimum: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            isKeyboardVisible ? 8 : 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isKeyboardVisible && _showHelpSection) ...[
                                _buildHelpSection(),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ))))
            ])));
  }

  void _handleRegistrationPop(bool didPop) {
    if (!didPop || widget.isFinalizing) {
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) {
      return;
    }

    ref.read(userProvider.notifier).reset();
    ref.read(companyProvider.notifier).update(null);
    ref.read(badgeProvider.notifier).update(null);
    ref.read(showProvider.notifier).update(null);

    unawaited(ApiClient.instance.logout());
  }
}
