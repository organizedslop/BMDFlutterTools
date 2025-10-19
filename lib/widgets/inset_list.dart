/*
 * Inset List
 *
 * Created by:  Blake Davis
 * Description: Inset list widget
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/widgets/inset_list_section.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Inset List Box Decoration
 * ------------------------------------------------------------------------------------------------------------------ */
BoxDecoration insetListBoxDecoration =
    BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color:        Colors.white
    );




/* ======================================================================================================================
 * MARK: Inset List
 * ------------------------------------------------------------------------------------------------------------------ */
class InsetList extends StatelessWidget {

    final bool shrinkWrap;

    final BoxBorder? border;

    final Color backgroundColor;

    final EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 9);

    final List<InsetListSection> children;

    ScrollController? scrollController;


    InsetList({ super.key,
                 this.backgroundColor   = Colors.transparent,
                 this.border,
                 this.scrollController,
                 this.shrinkWrap        = false,
        required this.children,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            alignment:  Alignment.center,
            decoration: BoxDecoration(
                border: border,
                color:  backgroundColor
            ),

            // Padding for screen edge to list outer edges
            child: Padding(
                padding: margin,
                child:

                ListView(
                    controller: scrollController ?? ScrollController(),
                    padding:    EdgeInsets.zero,
                    shrinkWrap: shrinkWrap,
                    children:   <Widget>[...children]
                )
            )
        );
    }
}
