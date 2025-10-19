/*
 * Finalize Account Form
 *
 * Created by:  Blake Davis
 * Description: A form that lets a first-time user finish filling out their profile info.
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_bar__primary.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Finalize Account Form
 * ------------------------------------------------------------------------------------------------------------------ */
class FinalizeAccountForm extends ConsumerStatefulWidget {

    static const Key rootKey = Key("finalize_account_form__root");

    final String title = "Finish Setting Up Your Account";


    const FinalizeAccountForm({super.key});


    @override
    ConsumerState<FinalizeAccountForm> createState() => _FinalizeAccountFormState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _FinalizeAccountFormState extends ConsumerState<FinalizeAccountForm> {

    AppDatabase appDatabase = AppDatabase.instance;

    final _formKey = GlobalKey<FormState>();

    final Map<String, Map<String, dynamic>> _fieldData = {
        "first_name": { "controller": TextEditingController(), "key": GlobalKey<FormFieldState>() },
        "last_name":  { "controller": TextEditingController(), "key": GlobalKey<FormFieldState>() },
        "phone":      { "controller": TextEditingController(), "key": GlobalKey<FormFieldState>() },
    };

    bool isBusy = false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
        final user = ref.read(userProvider);
        if (user != null) {
            _fieldData["first_name"]!["controller"].text = user.name.first    ??  "";
            _fieldData["last_name"]!["controller"].text  = user.name.last     ??  "";
            _fieldData["phone"]!["controller"].text      = user.phone.primary ??  "";
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        for (var entry in _fieldData.entries) {
            (entry.value["controller"] as TextEditingController).dispose();
        }
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Helpers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child:   Row(
            children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (required) const Text(" *", style: TextStyle(color: Colors.red)),
            ],
        ),
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Save
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> _save(BuildContext context) async {
        if (!_formKey.currentState!.validate()) {
            return;
        }

        setState(() => isBusy = true);

        try {
            final user = ref.read(userProvider);

            if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No current user was found")));
                return;
            }

            user.name.first    = _fieldData["first_name"]!["controller"].text.trim();
            user.name.last     = _fieldData["last_name"]!["controller"].text.trim();
            user.phone.primary = _fieldData["phone"]!["controller"].text.trim();

            // Save the user to the local database
            await appDatabase.write(user);

            // Update the global state
            ref.read(userProvider.notifier).update(user);

            if (context.mounted) {
                context.pop();
            }

        } finally {
            if (mounted) {
                setState(() => isBusy = false);
            }
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Scaffold(
            appBar: PrimaryNavigationBar(title: widget.title),
            key:    FinalizeAccountForm.rootKey,
            body:   AbsorbPointer(
                absorbing: isBusy,
                child:     Stack(
                    children:  [
                        Form(
                            key:   _formKey,
                            child: ListView(
                                padding:  const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                                children: [
                                    _label("First name", required: true),
                                    TextFormField(
                                        controller: _fieldData["first_name"]!["controller"],
                                        key:        _fieldData["first_name"]!["key"],
                                        validator:  (validator) => (validator == null || validator.isEmpty) ? "Required" : null,
                                    ),

                                    const SizedBox(height: 24),

                                    _label("Last name", required: true),
                                    TextFormField(
                                        controller: _fieldData["last_name"]!["controller"],
                                        key:        _fieldData["last_name"]!["key"],
                                        validator:  (validator) => (validator == null || validator.isEmpty) ? "Required" : null,
                                    ),

                                    const SizedBox(height: 24),

                                    _label("Phone (optional)"),
                                    TextFormField(
                                        controller: _fieldData["phone"]!["controller"],
                                        key:        _fieldData["phone"]!["key"],
                                        keyboardType: TextInputType.phone,
                                    ),

                                    const SizedBox(height: 24),

                                    const SizedBox(height: 48),

                                    ElevatedButton(
                                        onPressed: () => _save(context),
                                        child: const Text("Save"),
                                    ),
                                ],
                            ),
                        ),
                        if (isBusy) const Center(child: CircularProgressIndicator()),
                    ],
                ),
            ),
        );
    }
}