import "dart:io";
import "dart:typed_data";
import "dart:convert";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__exhibitor.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/component__booth_tag.dart";
import "package:bmd_flutter_tools/widgets/component__foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/component__updating_indicator.dart";
import "package:bmd_flutter_tools/widgets/component__animated_expand.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__bottom.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__primary.dart";
import "package:dio/dio.dart";
import "package:collection/collection.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:url_launcher/url_launcher.dart";

class ExhibitorsList extends ConsumerStatefulWidget {
  static const Key rootKey = Key('exhibitors_list__root');
  final String? showId;
  final String title;

  ExhibitorsList({Key? key, this.showId, String? title})
      : title = title ?? 'Exhibitors',
        super(key: key);

  @override
  ConsumerState<ExhibitorsList> createState() => _ExhibitorsListState();
}

class _ExhibitorsListState extends ConsumerState<ExhibitorsList> {
  final AppDatabase _db = AppDatabase.instance;
  bool _loadingDb  = false;
  bool _loadingApi = false;

  List<ExhibitorData> _allExhibitors = [];

  // Used to prevent duplicate merges
  final Set<String> _seenIds = {};
  // Tracks which categories are collapsed
  final Set<String> _hiddenCategoryIds = {};

  bool _groupByCategory = false; // default: current behavior

  static const double _kBoothBadgeReserve = 96.0; // width reserved for the top-right booth badge

 /// Builds the booth label for the top right of a ListTile.
Widget? _boothTopRight(ExhibitorData ex) {
  return BoothTag(ex: ex);
}

  @override
  void initState() {
    super.initState();
    _fetchExhibitors();
  }

  Future<void> _fetchExhibitors() async {
    final String? showId = widget.showId ?? ref.read(showProvider)?.id;
    if (showId == null) {
      logPrint('⚠️  ExhibitorsList: No active showId available – aborting fetch.');
      if (mounted) {
        setState(() {
          _loadingDb  = false;
          _loadingApi = false;
          _allExhibitors = const <ExhibitorData>[];
        });
      }
      return;
    }

    // 1) Load from local DB as an initial/offline fallback.
    if (mounted) setState(() => _loadingDb = true);

    final raw = await _db.read(tableName: ExhibitorDataInfo.tableName);
    final List<ExhibitorData> dbList = (raw is List)
        ? raw.whereType<ExhibitorData>().toList()
        : const <ExhibitorData>[];
    // Filter out entries with empty or null companyName
    final List<ExhibitorData> filteredDbList = dbList
        .where((e) => (e.companyName ?? '').trim().isNotEmpty)
        .toList();

    if (!mounted) return;
    setState(() {
      _allExhibitors = filteredDbList;
      _loadingDb = false;
      _seenIds.clear(); // retained if needed later
    });

    // 2) Fetch from API scoped to the current show and REPLACE the in-memory list.
    //    This guarantees we only display exhibitors for the active show, regardless of what’s cached.
    if (mounted) setState(() => _loadingApi = true);
    try {
      final apiList = await ApiClient.instance.getExhibitors(showId: showId);
      // Filter out entries with empty or null companyName
      final List<ExhibitorData> filteredApiList = apiList
          .where((e) => (e.companyName ?? '').trim().isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _allExhibitors = filteredApiList; // ← replace, do NOT merge
          _loadingApi = false;
        });
      }

      // Persist (optional: we keep DB cache for offline; it may include previous shows).
      await _db.write(filteredApiList);
    } catch (e) {
      logPrint('❌  fetching exhibitors: $e');
      if (mounted) setState(() => _loadingApi = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchExhibitors();
  }


Future<Widget?> _safeSvgLogo(String normalizedUrl, String name, double size) async {
  try {
    final storage = const FlutterSecureStorage();
    final token   = await storage.read(key: 'access_token');

    final res = await ApiClient.instance.dio.get<List<int>>(
      normalizedUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (_) => true,
        headers: token != null ? {'authorization': 'Bearer $token'} : null,
      ),
    );

    if (res.statusCode != 200 || res.data == null) return null;

    final bytes = Uint8List.fromList(res.data!);
    // Try to render the SVG directly; any parse error will be caught.
    return SvgPicture.string(
      utf8.decode(bytes, allowMalformed: true),
      fit: BoxFit.contain,
    );
  } catch (e, st) {
    logPrint('❌ SVG load/parse failed: $e\n$st');
    return null;
  }
}



String _normalizeLogoUrl(String? url) {
  if (url == null) return '';
  final u = url.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;

  // Build an origin (scheme + host[:port]) from your API root
  final root = ApiClient.instance.mobileApiRootUrl(); // e.g. http://192.168.2.221/api/mobile/v1
  final base = Uri.parse(root);
  final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';

  if (u.startsWith('/')) return '$origin$u';           // “/storage/…”
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}').hasMatch(u)) { // “192.168.x.x/…”
    return '${base.scheme}://$u';
  }
  return '$origin/$u'; // relative path like “storage/…”
}




Widget _exhibitorLogo(BuildContext context, String? url, String name, {double size = 44}) {
  if (url == null || url.trim().isEmpty) {
    return _logoPlaceholder(context, name, size);
  }

  // Normalize once, then branch on the lowercased form for detection only.
  final String normalized = _normalizeLogoUrl(url);
  if (normalized.isEmpty) {
    return _logoPlaceholder(context, name, size);
  }
  final String lc = normalized.toLowerCase();

  // SVG path: fetch bytes with Dio (auth if present) and render; fallback to placeholder
  if (lc.endsWith('.svg') || lc.contains('format=svg') || lc.contains('image/svg')) {
    return FutureBuilder<Widget?> (
      future: _safeSvgLogo(normalized, name, size),
      builder: (context, snap) {
        final Widget child = snap.connectionState == ConnectionState.done
            ? (snap.data ?? _logoPlaceholder(context, name, size))
            : _logoPlaceholder(context, name, size);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size * 1.5,
            maxHeight: size * 1.5,
          ),
          child: child,
        );
      },
    );
  }

  // Raster path: use the normalized URL (also supports auth via server config/CORS)
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: size * 1.5, maxHeight: size * 1.5),
    child: Image.network(
      normalized,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (c, _, __) => _logoPlaceholder(c, name, size),
    ),
  );
}


Widget _logoPlaceholder(BuildContext context, String name, double size) {
  final String initial =
      name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : '?';

  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: BeColorSwatch.navy.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: BeColorSwatch.navy.withOpacity(0.15)),
    ),
    child: Text(
      initial,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: BeColorSwatch.navy,
            fontWeight: FontWeight.w600,
          ),
    ),
  );
}





  // --- Exhibitor company/contact helpers ---
  Future<CompanyData?> _loadCompany(String companyId) async {
    // Try local DB first
    final companies = await _db.readCompanies(
      where: '${CompanyDataInfo.id.columnName} = ?',
      whereArgs: [companyId],
    );
    final local = companies.firstWhereOrNull((_) => true);
    if (local != null) return local;

    // Fallback to API
    try {
      final fetched = await ApiClient.instance.getCompanyById(companyId);
      if (fetched != null) {
        await _db.write([fetched]);
      }
      return fetched;
    } catch (_) {
      return null;
    }
  }




  Future<String?> _addressFromDb(String companyId) async {
    final company = await _loadCompany(companyId);
    return _extractAddressOneLine(company);
  }




  String? _extractAddressOneLine(CompanyData? c) {
    if (c == null) return null;
    try {
      final dynamic maybeAddress = (c as dynamic).address;
      if (maybeAddress is AddressData) {
        return maybeAddress.toString(includeCountry: true);
      }
    } catch (_) {}
    // Fallbacks: try common fields if present on CompanyData
    try {
      final dynamic street = (c as dynamic).address1 ?? (c as dynamic).street;
      final dynamic city   = (c as dynamic).city;
      final dynamic state  = (c as dynamic).state;
      final dynamic zip    = (c as dynamic).postalCode ?? (c as dynamic).zip;
      final parts = [street, city, state, zip]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    } catch (_) {}
    return null;
  }





  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: "tel", path: "+1${normalized}");
    if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not place call")));
    }
  }




Future<void> _launchEmail(String? email) async {
  // Trim & quick-validate
  final raw = email?.trim();
  if (raw == null || raw.isEmpty) return;

  // If caller already passed a mailto: URL, respect it
  final isMailto = raw.toLowerCase().startsWith('mailto:');
  final Uri uri = isMailto
      ? Uri.parse(raw)
      : Uri(scheme: 'mailto', path: raw);

  // Try to launch; if the platform/mail app can’t handle it, show a message
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Could not send an email to this address.')),
    );
  }
}




  Future<void> _launchMaps(String? address) async {
    if (address == null || address.trim().isEmpty) return;
      final query   = Uri.encodeComponent(address);
      String url;

      if (Platform.isIOS) {
          url = "maps://?q=${query}";
      } else if (Platform.isAndroid) {
          url = "geo:0,0?q=${query}";
      } else {
          url = "https://www.google.com/maps/search/?api=1&query=${query}";
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
          await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
          );
      } else {
          scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text("Could not open maps for this address.")),
          );
      }
  }







  Future<void> _showExhibitorDialog(ExhibitorData ex) async {
    // Preload company so we can determine which actions are available.
    final CompanyData? company = await _loadCompany(ex.companyId);

    // Pull contact details safely.
    final String? phone = (() {
      try {
        return (company as dynamic).phone as String?;
      } catch (_) {
        return null;
      }
    })();

    final String? email = (() {
      try {
        return (company as dynamic).email as String?;
      } catch (_) {
        return null;
      }
    })();

    final String? address = _extractAddressOneLine(company);

    final bool hasPhone   = phone != null && phone.trim().isNotEmpty;
    final bool hasEmail   = email != null && email.trim().isNotEmpty;
    final bool hasAddress = address != null && address.trim().isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final Color enabledColor  = BeColorSwatch.blue;
        final Color disabledColor = theme.disabledColor;

        Color _colorFor(bool enabled) => enabled ? enabledColor : disabledColor;

        return AlertDialog(
          title: Text(ex.companyName, style: theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _exhibitorLogo(ctx, ex.logoUrl, ex.companyName, size: 72),
                ),

                // Description
                Text('Description', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                if ((ex.companyDescription ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      ex.companyDescription!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                // Categories
                if (ex.categories.isNotEmpty) ...[
                  Text('Categories', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ex.categories.map((c) => Text(c)).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Booths
                if (ex.booths.isNotEmpty) ...[
                  Text('Booths', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text(ex.booths.map((booth) => booth.number).join(', '), style: theme.textTheme.bodyMedium),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryNavigationBar(
        title: widget.title,
        subtitle: ref.read(showProvider)?.title,
        showMenu: false,
      ),
      bottomNavigationBar: QuickNavigationBar(),
      floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
      body: RefreshIndicator.adaptive(
        onRefresh: () async { _handleRefresh(); },
        child: () {
          // Show loading state with a scrollable container so pull-to-refresh works.
          if (_loadingDb || (_allExhibitors.isEmpty && _loadingApi)) {
            return
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                      Text(
                        "Loading exhibitors...",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

            );
          }

          // Empty state, still scrollable so the user can pull to refresh
          if (_allExhibitors.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                Center(child: Text('No exhibitors found.', style: beTextTheme.bodyPrimary)),
                const SizedBox(height: 48),
              ],
            );
          }

          // Populated state – preserve existing formatting
          final exhibitors = _allExhibitors;

          final Map<String, List<ExhibitorData>> byCategory = {};
          for (var exhibitor in exhibitors) {
            final category = exhibitor.categories.isNotEmpty ? exhibitor.categories.first : 'Uncategorized';
            (byCategory[category] ??= []).add(exhibitor);
          }
          final categories = byCategory.keys.toList()..sort();

          return ListView(
            key: ExhibitorsList.rootKey,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
                /*
                 * Group by category toggle
                 */
                Padding(
                    padding: const EdgeInsets.only(top: 8, right: 24, left: 24),
                    child: Text(
                        "sort by",
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.gray),
                    )
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child:   LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth.clamp(0, 280);
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: CupertinoSlidingSegmentedControl<String>(
                          padding: EdgeInsets.zero,
                          groupValue: _groupByCategory ? "category" : "company",
                          children: <String, Widget>{
                            "company": Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Company name",
                                  style: TextStyle(color: _groupByCategory ? BeColorSwatch.darkGray : BeColorSwatch.blue),
                                ),
                              ),
                            ),
                            "category": Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Category",
                                  style: TextStyle(color: _groupByCategory ? BeColorSwatch.blue : BeColorSwatch.darkGray),
                                ),
                              ),
                            ),
                          },
                          onValueChanged: (String? value) {
                            if (value == null) return;
                            setState(() => _groupByCategory = (value == 'category'));
                          },
                        ),
                      );
                    },
            ),
          ),

              // Spacer
              if (!_loadingApi) const SizedBox(height: 16),

              /*
               * Updating indicator
               */
              if (_loadingApi) ...[
                const SizedBox(height: 4),
                const UpdatingIndicator(),
              ],

              if (_groupByCategory) ...[
                // --- EXISTING BEHAVIOR: grouped under category headers ---
                for (var category in categories) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_hiddenCategoryIds.contains(category)) {
                          _hiddenCategoryIds.remove(category);
                        } else {
                          _hiddenCategoryIds.add(category);
                        }
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: BeColorSwatch.lightGray)),
                        color: BeColorSwatch.navy
                        ),
                      padding: const EdgeInsets.only(top: 10, right: 16, bottom: 10, left: 4),
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: BeColorSwatch.white),
                      ),
                    ),
                  ),
                  AnimatedExpand(
                    expanded: !_hiddenCategoryIds.contains(category),
                    childKey: 'category-' + category,
                    child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < byCategory[category]!.length; i++) ...[
                      InkWell(
                        onTap: () => _showExhibitorDialog(byCategory[category]![i]),
                        child: Container(
                          padding: const EdgeInsets.only(top: 8, right: 16, bottom: 16, left: 12),
                          child: Stack(
                            children: [
                              // Main content
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _exhibitorLogo(
                                    context,
                                    byCategory[category]![i].logoUrl,
                                    byCategory[category]![i].companyName,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Reserve right-side space only for the top line so the badge doesn't overlap the title.
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 4,
                                            right: _boothTopRight(byCategory[category]![i]) != null ? _kBoothBadgeReserve : 0,
                                          ),
                                          child: Text(
                                            byCategory[category]![i].companyName,
                                            style: Theme.of(context).textTheme.labelMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if ((byCategory[category]![i].companyDescription ?? '').trim().isNotEmpty)
                                          Text(
                                            byCategory[category]![i].companyDescription!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(height: 0.95),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Floating booth badge in the top-right
                              if (_boothTopRight(byCategory[category]![i]) != null)
                                Positioned(
                                  top:   0,
                                  right: 0,
                                  child: _boothTopRight(byCategory[category]![i])!,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (byCategory[category]!.length > 1 && i < byCategory[category]!.length - 1)
                        const Divider(height: 1, color: BeColorSwatch.gray, indent: 6, endIndent: 6),
                              ],
                            ],
                          ),
                  ),
                ],
                const SizedBox(height: 32),
              ] else ...[
                // --- NEW BEHAVIOR: flat, alphabetically sorted by company name ---
                ...(() {
                  final List<ExhibitorData> sorted = List<ExhibitorData>.from(exhibitors)
                    ..sort((a, b) => (a.companyName).toLowerCase().compareTo((b.companyName).toLowerCase()));

                  return [
                    for (int i = 0; i < sorted.length; i++) ...[
                      InkWell(
                        onTap: () => _showExhibitorDialog(sorted[i]),
                        child: Container(
                          padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 16),
                          child: Stack(
                            children: [
                              // Main content
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _exhibitorLogo(
                                    context,
                                    sorted[i].logoUrl,
                                    sorted[i].companyName,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Reserve right-side space only for the top line so the badge doesn't overlap the title/category.
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: _boothTopRight(sorted[i]) != null ? _kBoothBadgeReserve : 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                sorted[i].companyName,
                                                style:    Theme.of(context).textTheme.labelMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (sorted[i].categories.isNotEmpty
                                                    ? sorted[i].categories.first
                                                    : 'Uncategorized'),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(color: BeColorSwatch.darkGray),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if ((sorted[i].companyDescription ?? '').trim().isNotEmpty)
                                          Text(
                                            sorted[i].companyDescription!,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(height: 1.1),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Floating booth badge in the top-right
                              if (_boothTopRight(sorted[i]) != null)
                                Positioned(
                                  top:   0,
                                  right: 0,
                                  child: _boothTopRight(sorted[i])!,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (i < sorted.length - 1) const Divider(height: 1, color: BeColorSwatch.gray, indent: 6, endIndent: 6),
                    ],
                    const SizedBox(height: 32),
                  ];
                })(),
              ],
            ],
          );
        }(),
      ),
    );
  }
}
