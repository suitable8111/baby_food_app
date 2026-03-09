//
//  BabyTrackerWidgetLiveActivity.swift
//  BabyTrackerWidget
//
//  Created by DAEHO KIM on 3/9/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BabyTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BabyTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BabyTrackerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BabyTrackerWidgetAttributes {
    fileprivate static var preview: BabyTrackerWidgetAttributes {
        BabyTrackerWidgetAttributes(name: "World")
    }
}

extension BabyTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: BabyTrackerWidgetAttributes.ContentState {
        BabyTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BabyTrackerWidgetAttributes.ContentState {
         BabyTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BabyTrackerWidgetAttributes.preview) {
   BabyTrackerWidgetLiveActivity()
} contentStates: {
    BabyTrackerWidgetAttributes.ContentState.smiley
    BabyTrackerWidgetAttributes.ContentState.starEyes
}
