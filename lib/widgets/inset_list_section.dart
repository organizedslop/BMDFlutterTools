/*
 * Inset List Section
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying a scrollable list of Widgets, separated by dividers
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:io";

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/inset_list.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Inset List Section
 * ------------------------------------------------------------------------------------------------------------------ */
class InsetListSection extends StatelessWidget {

    final Axis           direction;

    final bool           showBackground,
                         isVisible;

    final Color?         backgroundColor;

    final dynamic        title;

    final EdgeInsets     padding;

    final Function?      onTap;

    final ImageProvider? backgroundImage;

    final List<Widget>   children;


    InsetListSection({ super.key,
                        this.backgroundColor,
                        this.backgroundImage,
                        this.direction        = Axis.vertical,
                        this.isVisible        = true,
                        this.onTap,
                        this.padding          = const EdgeInsets.only(top: 2, right: 16, bottom: 4, left: 16),
                        this.showBackground   = true,
                        this.title,
               required this.children,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Plain-Formatted Inset List Section
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory InsetListSection.plain({ title,
                            required children
    }) {
        return InsetListSection(
            title:          title,
            children:       children,
            padding:        const EdgeInsets.all(0),
            showBackground: false,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        Widget titleAsWidget = title is Widget ? title :
                                                 Text((title is String) ? (title ?? "").toUpperCase() : "",
                                                     style: beTextTheme.captionPrimary);
        return Visibility(
            maintainState: true,
            visible:       isVisible,
            child:         Container(
                child:
                InkWell(
                    hoverColor:    Colors.transparent,
                    onTap: () {
                        if (onTap is Function) {
                            onTap!();
                        }
                    },
                    overlayColor:  WidgetStateColor.transparent,
                    splashColor:   Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    child:         Flex(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        direction:          Axis.vertical,
                        mainAxisAlignment:  MainAxisAlignment.start,
                        children: [
                            Padding(
                                padding: EdgeInsets.only(top: 16, left: beDimensions.insetListTitleLeadingMargin),
                                child:   titleAsWidget
                            ),

                            Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: (showBackground && backgroundImage == null) ? (backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer) : Colors.transparent),
                                child:      Stack(
                                    children: [
                                        (backgroundImage != null) ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image(image: backgroundImage!, fit: BoxFit.cover)) : const SizedBox.shrink(),
                                        Padding(
                                            padding: padding,
                                                child: ListView.separated(
                                                    /*
                                                    * List is used here for its separatorBuilder, but is playing the role of a Column.
                                                    * The outer List this is nested in is handling the scrolling
                                                    */
                                                    itemCount:        children.length,
                                                    itemBuilder:      (context, index) { return children[index]; },
                                                    physics:          const NeverScrollableScrollPhysics(),
                                                    scrollDirection:  Axis.vertical,
                                                    separatorBuilder: (context, index) => Divider(color: BeColorSwatch.lighterGray, height: double.minPositive),
                                                    shrinkWrap:       true,
                                                )
                                        )
                                    ]
                                )
                            )
                        ]
                    )
                )
            )
        );
    }
}