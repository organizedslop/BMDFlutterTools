
import 'package:bmd_flutter_tools/utilities/utilities__theme.dart';
import 'package:bmd_flutter_tools/widgets/components/enclosed_text.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class ExpandableContainer extends StatelessWidget {

    Widget content;

    ExpandableContainer({
        required this.content
    });


    @override
    Widget build(BuildContext context) {
        return ExpandableNotifier(
            child: Expandable(
                collapsed: ExpandableButton(
                    child: Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children: [
                            SizedBox(
                                height: 100,
                                child:  content
                            ),
                            EnclosedText(
                                "Tap to expand",
                                backgroundColor: BeColorSwatch.white,
                                style:           beTextTheme.bodySecondary,
                            )
                        ]
                    )
                ),
                expanded: ExpandableButton(
                    child: content,
                ),
            ),
        );
    }
}