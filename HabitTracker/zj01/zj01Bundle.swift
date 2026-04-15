//
//  zj01Bundle.swift
//  zj01
//
//  Created by Soren on 2026/4/14.
//

import WidgetKit
import SwiftUI

@main
struct zj01Bundle: WidgetBundle {
    var body: some Widget {
        TodayTasksSmallWidget()
        TodayTasksMediumWidget()
        zj01LiveActivity()
    }
}
