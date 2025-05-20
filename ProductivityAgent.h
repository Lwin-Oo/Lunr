//
//  ProductivityAgent.h
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//

#pragma once
#include <string>
#include <unordered_map>
#include <vector>

enum class AppType { PRODUCTIVE, ENTERTAINMENT, SOCIAL, UNKNOWN };

struct WeeklyStats {
    int gitCommits = 0;
    std::unordered_map<std::string, int> appUsageMinutes;
};

class ProductivityAgent {
public:
    ProductivityAgent(int requiredWeeklyCommits);

    void registerApp(const std::string& appName, AppType type);
    void logAppUsage(const std::string& appName, int minutes);
    void logGitCommits(int count);

    std::vector<std::string> getRestrictedApps() const;

private:
    int weeklyGoal;
    WeeklyStats currentWeek;
    std::unordered_map<std::string, AppType> appTypeMap;
};
