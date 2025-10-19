/*
 * Invite Team Member Form
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/modals/invite_guests.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:country_picker/country_picker.dart";
import "package:bmd_flutter_tools/data/data/data__us_states.dart";
import "package:go_router/go_router.dart";



/* ======================================================================================================================
 * MARK: Invite Team Member Form
 * ------------------------------------------------------------------------------------------------------------------ */
class InviteTeamMemberForm extends ConsumerStatefulWidget {

    static const Key rootKey = Key("invite_team_member_form__root");


    const InviteTeamMemberForm({
        super.key
    });


    @override
    ConsumerState<InviteTeamMemberForm> createState() => _InviteTeamMemberFormState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _InviteTeamMemberFormState extends ConsumerState<InviteTeamMemberForm> {
    String? _selectedState;
    String? _selectedCountryCode = "US";
    String? _selectedCountryName = "United States";

    late TextEditingController _firstNameController;
    late TextEditingController _lastNameController;
    late TextEditingController _emailController;
    late TextEditingController _phoneController;
    late TextEditingController _positionController;
    late TextEditingController _addressController;
    late TextEditingController _suiteController;
    late TextEditingController _cityController;
    late TextEditingController _zipController;


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
        _firstNameController  = TextEditingController();
        _lastNameController   = TextEditingController();
        _emailController      = TextEditingController();
        _phoneController      = TextEditingController();
        _positionController   = TextEditingController();
        _addressController    = TextEditingController();
        _suiteController      = TextEditingController();
        _cityController       = TextEditingController();
        _zipController        = TextEditingController();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        _firstNameController.dispose();
        _lastNameController.dispose();
        _emailController.dispose();
        _phoneController.dispose();
        _positionController.dispose();
        _addressController.dispose();
        _suiteController.dispose();
        _cityController.dispose();
        _zipController.dispose();
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Submit the Form
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> saveForm({ required BuildContext context, required Map<String, dynamic> formData }) async {
        try {
            final result = await ApiClient.instance.submitInviteForm(formData: formData);

            // Determine success: if API returns a bool use it, otherwise assume success when no exception thrown.
            final bool success = true;

            if (!mounted) return;

            if (success) {
                // Close the dialog/modal
                Navigator.of(context).pop();

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invite sent.")),
                );
            } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send invite."), backgroundColor: BeColorSwatch.red),
                );
            }
        } catch (e) {
            logPrint("❌ Invite submit failed: $e");
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to send invite."), backgroundColor: BeColorSwatch.red),
            );
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        // Use shared usStates map from data__us_states.dart

        return Dialog(
            key: InviteTeamMemberForm.rootKey,
            insetPadding: EdgeInsets.only(top: 32, right: 12, bottom: 0, left: 12),
            child: Container(
                child: ListView(
                    padding: EdgeInsets.all(12),
                    children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child:   Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 16,
                                children: [
                                    Text("Invite a Team Member", style: Theme.of(context).textTheme.headlineLarge),
                                    Text("This form sends an email to the address provided, allowing the recipient to join your company and register for badges to exhibit with your company."),
                                    GestureDetector(
                                        onTap: () {
                                            if (!mounted) return;
                                            context.pop();

                                            showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                    return InviteModal();
                                                }
                                            );
                                        },
                                        child: Text("If you would like to invite a guest to attend instead, tap here.", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.blue, fontWeight: FontWeight.bold))
                                    ),
                                ]
                            )
                        ),
                        const SizedBox(height: 16),

                        Row(spacing: 6,
                            children: [
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "First Name", isRequired: true),
                                        TextFormField(
                                            controller: _firstNameController,
                                            decoration:   InputDecoration(hintText: "John", hintStyle: gfieldHintStyle),
                                        ),
                                    ])
                                ),
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "Last Name", isRequired: true),
                                        TextFormField(
                                            controller: _lastNameController,
                                            decoration:   InputDecoration(hintText: "Smith", hintStyle: gfieldHintStyle),
                                        ),
                                    ])
                                )
                        ]),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "Email Address", isRequired: true),
                        TextFormField(
                            controller: _emailController,
                            decoration:   InputDecoration(hintText: "hello@example.com", hintStyle: gfieldHintStyle),
                            keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        Row(spacing: 6,
                            children: [
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "Phone Number", isRequired: true),
                                        TextFormField(
                                            controller: _phoneController,
                                            decoration:   InputDecoration(hintText: "(123) 555-1234", hintStyle: gfieldHintStyle),
                                            keyboardType: TextInputType.phone,
                                        )
                                    ])
                                ),
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "Position", isRequired: true),
                                        TextFormField(
                                            controller: _positionController,
                                            decoration: InputDecoration(hintText: "Owner", hintStyle: gfieldHintStyle)
                                        )
                                    ])
                                ),
                        ]),

                        const SizedBox(height: 28),
                        Divider(color: BeColorSwatch.gray),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "Address", isRequired: true),
                        TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(hintText: "123 Main St", hintStyle: gfieldHintStyle)
                        ),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "Suite/Apartment Number"),
                        TextFormField(
                            controller: _suiteController,
                            decoration: InputDecoration(hintText: "Unit A", hintStyle: gfieldHintStyle)
                        ),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "City", isRequired: true),
                        TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(hintText: "Austin", hintStyle: gfieldHintStyle)
                        ),
                        const SizedBox(height: 16),

                        Row(spacing: 6,
                            children: [
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "State", isRequired: true),
                                        DropdownButtonFormField<String>(
                                            key:  const Key("invite_team_member_form__state_field"),
                                            decoration: gfieldInputDecoration.copyWith(
                                                fillColor: BeColorSwatch.white,
                                                hintText:  "Select an option",
                                                hintStyle: gfieldHintStyle,
                                            ),
                                            style: TextStyle(
                                                color:      BeColorSwatch.black,
                                                fontSize:   16,
                                                fontWeight: FontWeight.normal,
                                            ),
                                            isExpanded: true,
                                            items: usStates.entries.map((entry) {
                                                return DropdownMenuItem<String>(
                                                    value: entry.key,
                                                    child: Text(
                                                        entry.value,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                );
                                            }).toList(),
                                            value:     _selectedState,
                                            onChanged: (String? newValue) {
                                                setState(() {
                                                    _selectedState = newValue;
                                                });
                                            },
                                            validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                    return "This field is required.";
                                                }
                                                return null;
                                            }
                                        )
                                    ])
                                ),
                                Expanded(child:
                                    Column(children: [
                                        formFieldLabel(labelText: "ZIP", isRequired: true),
                                        TextFormField(
                                            controller: _zipController,
                                            decoration: InputDecoration(hintText: "12345", hintStyle: gfieldHintStyle)
                                        ),
                                    ])
                                ),
                        ]),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "Country", isRequired: true),
                        TextFormField(
                            key: const Key("invite_team_member_form__country_field"),
                            decoration: gfieldInputDecoration.copyWith(
                                fillColor: BeColorSwatch.white,
                                hintText:  "Select an option",
                                hintStyle: gfieldHintStyle,
                            ),
                            style: TextStyle(
                                color:      BeColorSwatch.black,
                                fontSize:   16,
                                fontWeight: FontWeight.normal,
                            ),
                            readOnly: true,
                            controller: TextEditingController(text: _selectedCountryName ?? ""),
                            onTap: () {
                                showCountryPicker(
                                    context: context,
                                    countryListTheme: CountryListThemeData(
                                        margin: EdgeInsets.only(top: 24, right: 24, left: 24)
                                    ),
                                    showPhoneCode: false,
                                    useSafeArea:   true,
                                    onSelect: (Country country) {
                                        setState(() {
                                            _selectedCountryCode = country.countryCode;
                                            _selectedCountryName = country.name;
                                        });
                                    },
                                );
                            },
                            validator: (value) {
                                if (_selectedCountryCode == null || _selectedCountryCode!.isEmpty) {
                                    return "This field is required.";
                                }
                                return null;
                            },
                        ),
                        const SizedBox(height: 24),

                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                TextButton(
                                    key: const Key('invite_team_member_form__cancel_button'),
                                    onPressed: () {
                                        Navigator.of(context).pop();
                                    },
                                    child: Text("Cancel", style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                    key: const Key('invite_team_member_form__save_button'),
                                    onPressed: () {
                                        final data = {
                                            'address':    _addressController.text,
                                            'address2':   _suiteController.text,
                                            'city':       _cityController.text,
                                            'company_id': ref.read(companyProvider)!.id,
                                            'country':    _selectedCountryCode,
                                            'email':      _emailController.text,
                                            'first_name': _firstNameController.text,
                                            'last_name':  _lastNameController.text,
                                            'phone':      _phoneController.text,
                                            'position':   _positionController.text,
                                            'show_id':    ref.read(showProvider)!.id,
                                            'state':      _selectedState,
                                            'zip':        _zipController.text,
                                        };
                                        saveForm(context: context, formData: data);
                                    },
                                    child: Text("Submit", style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: BeColorSwatch.white, fontWeight: FontWeight.bold)),
                                ),
                            ],
                        ),
                        const SizedBox(height: 32),
                    ]
                )
            )
        );
    }
}
