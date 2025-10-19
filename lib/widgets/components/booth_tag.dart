import 'package:bmd_flutter_tools/data/model/data__exhibitor.dart';
import 'package:bmd_flutter_tools/utilities/theme_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

/// Builds the booth label for the top right of a ListTile, or returns null if none.
class BoothTag extends StatelessWidget {

    final ExhibitorData? ex;
    final String? boothNumber;
    final bool small;

    const BoothTag({
      super.key,
      this.ex,
      this.boothNumber,
      this.small = false,
    }) : assert(ex != null || boothNumber != null, 'Provide either ex or boothNumber.');


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final List<String> booths = () {
          if ((boothNumber ?? '').trim().isNotEmpty) {
            return [boothNumber!.trim()];
          }
          if (ex != null) {
            return ex!.booths
                .map(  (b) => b.number.trim())
                .where((n) => n.isNotEmpty)
                .toList();
          }
          return <String>[];
        }();

        return Container(
            decoration: BoxDecoration(
                color:        (booths.isNotEmpty ? BeColorSwatch.red : BeColorSwatch.gray),
                borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
                onPressed: null,
                style:     ButtonStyle(
                    padding:       WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: (small ? 4 : 6), vertical: (small ? 0 : 2))),
                    visualDensity: VisualDensity(horizontal: (small ? -4 : -2), vertical: (small ? -4 : -3.5)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                        Padding(
                            padding: EdgeInsets.only(bottom: (small ? 1 : 0)),
                            child:   SFIcon(
                                SFIcons.sf_storefront_fill,
                                color:    BeColorSwatch.lighterGray,
                                fontSize: small ? 10 : 12,
                            ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                            padding: EdgeInsets.only(top: (small ? 1 : 0)),
                            child:   Text(
                                (booths.isNotEmpty ? booths.join(", ") : "TBD"),
                                style: TextStyle(
                                    color:      BeColorSwatch.lighterGray,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   small ? 14 : 16,
                                )
                            )
                        ),
                    ],
                ),
            ),
        );
    }
}