//
//  zj01LiveActivity.swift
//  zj01
//
//  Created by Soren on 2026/4/14.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct zj01Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct zj01LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: zj01Attributes.self) { context in
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

extension zj01Attributes {
    fileprivate static var preview: zj01Attributes {
        zj01Attributes(name: "World")
    }
}

extension zj01Attributes.ContentState {
    fileprivate static var smiley: zj01Attributes.ContentState {
        zj01Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: zj01Attributes.ContentState {
         zj01Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: zj01Attributes.preview) {
   zj01LiveActivity()
} contentStates: {
    zj01Attributes.ContentState.smiley
    zj01Attributes.ContentState.starEyes
}
