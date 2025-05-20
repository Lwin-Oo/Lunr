//
//  ProductivityAgent.cpp
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//

#include "ProductivityAgent.h"

ProductivityAgent::ProductivityAgent(int requiredWeeklyCommits) : weeklyGoal(requiredWeeklyCommits) {}

void ProductivityAgent::registerApp(const std::string& appName, AppType type) {
    appTypeMap[appName] = type;
}

void ProductivityAgent::logAppUsage(const std::string& appName, int minutes) {
    currentWeek.appUsageMinutes[appName] += minutes;
}

void ProductivityAgent::logGitCommits(int count) {
    currentWeek.gitCommits = count;
}

std::vector<std::string> ProductivityAgent::getRestrictedApps() const {
    std::vector<std::string> restricted;

    for (const auto& [app, duration] : currentWeek.appUsageMinutes) {
        auto type = appTypeMap.count(app) ? appTypeMap.at(app) : AppType::UNKNOWN;

        if ((type == AppType::ENTERTAINMENT || type == AppType::SOCIAL) && currentWeek.gitCommits < weeklyGoal) {
            if (duration > 180) { // 3 hours/week threshold for example
                restricted.push_back(app);
            }
        }
    }

    return restricted;
}
