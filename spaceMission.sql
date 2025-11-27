--getting the country names

SELECT 
    LTRIM(RTRIM(
        RIGHT(Location, CHARINDEX(',', REVERSE(Location)) - 1)
    )) AS Country
FROM space_missions

--Adding country names

ALTER TABLE space_missions
ADD Country VARCHAR(100);

UPDATE space_missions
SET Country = LTRIM(RTRIM(
                    RIGHT(Location, CHARINDEX(',', REVERSE(Location)) - 1)
                ))

SELECT * FROM space_missions

--Extracting Year
ALTER TABLE space_missions ADD LaunchYear INT

UPDATE space_missions
SET LaunchYear = YEAR(CAST(Date AS DATE))

-- Launch Count by Country
SELECT Country, COUNT(*) AS TotalLaunches
FROM space_missions
GROUP BY Country
ORDER BY TotalLaunches DESC

--Success Rate by Country
SELECT 
    Country,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 100.0 /
    COUNT(*) AS SuccessRate
FROM space_missions
GROUP BY Country
ORDER BY SuccessRate DESC

--Longetivity
SELECT 
    Country,
    MIN(LaunchYear) AS FirstYear,
    MAX(LaunchYear) AS LastYear,
    MAX(LaunchYear) - MIN(LaunchYear) + 1 AS TotalYearsOfOps
FROM space_missions
GROUP BY Country
ORDER BY TotalYearsOfOps DESC

--Organization Dominance
SELECT 
    Company,
    Country,
    COUNT(*) AS Launches,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS sucessRate
FROM space_missions
GROUP BY Company, Country
ORDER BY sucessRate DESC

--Weighted Success Rate
--Used log for weighthed measure
SELECT
    Country,
    COUNT(*) AS TotalLaunches,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS TotalSuccesses,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS RawSuccessRate,
    (SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
        * LOG10(COUNT(*)) AS WeightedSuccessRate
FROM space_missions
GROUP BY Country
ORDER BY WeightedSuccessRate DESC

--Organization Dominance Weighted
SELECT 
    Company,
    Country,
    COUNT(*) AS Launches,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,
    SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS sucessRate,
    (SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
        * LOG10(COUNT(*)) AS WeightedSuccessRate
FROM space_missions
GROUP BY Company, Country
ORDER BY WeightedSuccessRate DESC


--Market share for launches
SELECT
    Country,
    COUNT(*) AS TotalLaunches,
    COUNT(*) * 1.0 /
        (SELECT COUNT(*) FROM space_missions) AS GlobalLaunchShare
FROM space_missions
GROUP BY Country
ORDER BY TotalLaunches DESC


-- Dominance Score

WITH stats AS (
    SELECT
        Country,
        COUNT(*) AS TotalLaunches,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS RawSuccessRate,
        (SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
            * LOG10(COUNT(*)) AS WeightedSuccessRate,
        MIN(LaunchYear) AS FirstYear,
        MAX(LaunchYear) AS LastYear,
        (MAX(LaunchYear) - MIN(LaunchYear) + 1) AS YearsActive
    FROM space_missions
    GROUP BY Country
),
ranks AS (
    SELECT
        Country,
        TotalLaunches,
        WeightedSuccessRate,
        YearsActive,
        RANK() OVER (ORDER BY TotalLaunches DESC) AS RankLaunches,
        RANK() OVER (ORDER BY WeightedSuccessRate DESC) AS RankWeightedSuccess,
        RANK() OVER (ORDER BY YearsActive DESC) AS RankLongevity
    FROM stats
)
SELECT
    Country,
    TotalLaunches,
    WeightedSuccessRate,
    YearsActive,
    RankLaunches,
    RankWeightedSuccess,
    RankLongevity,
    -- Final Dominance Score (lower = better)
    (RankLaunches * 0.5) +
    (RankWeightedSuccess * 0.3) +
    (RankLongevity * 0.2) AS DominanceScore
FROM ranks
ORDER BY DominanceScore ASC


--Decade wise dominance
WITH stats AS (
    SELECT
        Country,
        COUNT(*) AS TotalLaunches,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS RawSuccessRate,
        (SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
            * LOG10(COUNT(*)) AS WeightedSuccessRate,
        MIN(LaunchYear) AS FirstYear,
        MIN(LaunchYear) + 10 AS LastYear,
        (MAX(LaunchYear) - MIN(LaunchYear) + 1) AS YearsActive
    FROM space_missions
    WHERE MIN(LaunchYear) <= 1959
    GROUP BY Country
),
ranks AS (
    SELECT
        Country,
        TotalLaunches,
        WeightedSuccessRate,
        YearsActive,
        RANK() OVER (ORDER BY TotalLaunches DESC) AS RankLaunches,
        RANK() OVER (ORDER BY WeightedSuccessRate DESC) AS RankWeightedSuccess,
        RANK() OVER (ORDER BY YearsActive DESC) AS RankLongevity
    FROM stats
)
SELECT
    Country,
    TotalLaunches,
    WeightedSuccessRate,
    YearsActive,
    RankLaunches,
    RankWeightedSuccess,
    RankLongevity,
    -- Final Dominance Score (lower = better)
    (RankLaunches * 0.5) +
    (RankWeightedSuccess * 0.3) +
    (RankLongevity * 0.2) AS DominanceScore
FROM ranks
ORDER BY DominanceScore ASC

-- Decade Wise Dominance

WITH decade_base AS (
    SELECT
        Country,
        (LaunchYear / 10) * 10 AS Decade,
        COUNT(*) AS TotalLaunches,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,
        
        -- Longevity within decade = only years inside that decade
        MIN(LaunchYear) AS FirstYearInDecade,
        MAX(LaunchYear) AS LastYearInDecade
    FROM space_missions
    GROUP BY Country, (LaunchYear / 10) * 10
),

metrics AS (
    SELECT
        Country,
        Decade,
        TotalLaunches,

        CASE
            WHEN TotalLaunches = 0 THEN 0
            ELSE Successes * 1.0 / TotalLaunches
        END AS SuccessRate,

        -- Weighted success uses only decade data
        CASE
            WHEN TotalLaunches = 0 THEN 0
            ELSE (Successes * 1.0 / TotalLaunches) * LOG10(TotalLaunches + 1)
        END AS WeightedSuccess,

        -- Longevity inside decade (max 10 years)
        CASE 
            WHEN TotalLaunches = 0 THEN 0
            ELSE (LastYearInDecade - FirstYearInDecade) + 1
        END AS Longevity
    FROM decade_base
),

ranked AS (
    SELECT
        Country,
        Decade,
        TotalLaunches,
        SuccessRate,
        WeightedSuccess,
        Longevity,

        RANK() OVER (PARTITION BY Decade ORDER BY TotalLaunches DESC) AS RankLaunches,
        RANK() OVER (PARTITION BY Decade ORDER BY WeightedSuccess DESC) AS RankWeightedSuccess,
        RANK() OVER (PARTITION BY Decade ORDER BY Longevity DESC) AS RankLongevity
    FROM metrics
)

SELECT
    Country,
    Decade,
    TotalLaunches,
    SuccessRate,
    WeightedSuccess,
    Longevity,
    (RankLaunches * 0.5) +
    (RankWeightedSuccess * 0.3) +
    (RankLongevity * 0.2) AS DominanceScore
FROM ranked
ORDER BY Decade, DominanceScore


-- Organization Dominances


WITH stats AS (
    SELECT
        [Company] AS Organization,
        COUNT(*) AS TotalLaunches,
        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) AS Successes,

        SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS RawSuccessRate,

        (SUM(CASE WHEN [MissionStatus] = 'Success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
            * LOG10(COUNT(*)) AS WeightedSuccessRate,

        MIN(LaunchYear) AS FirstYear,
        MAX(LaunchYear) AS LastYear,
        (MAX(LaunchYear) - MIN(LaunchYear) + 1) AS YearsActive
    FROM space_missions
    WHERE [Company] IS NOT NULL
    GROUP BY [Company]
),
ranks AS (
    SELECT
        Organization,
        TotalLaunches,
        WeightedSuccessRate,
        YearsActive,

        RANK() OVER (ORDER BY TotalLaunches DESC) AS RankLaunches,
        RANK() OVER (ORDER BY WeightedSuccessRate DESC) AS RankWeightedSuccess,
        RANK() OVER (ORDER BY YearsActive DESC) AS RankLongevity
    FROM stats
)
SELECT
    Organization,
    TotalLaunches,
    WeightedSuccessRate,
    YearsActive,
    RankLaunches,
    RankWeightedSuccess,
    RankLongevity,

    -- Final Dominance Score (lower = better)
    (RankLaunches * 0.5) +
    (RankWeightedSuccess * 0.3) +
    (RankLongevity * 0.2) AS DominanceScore
FROM ranks
ORDER BY DominanceScore ASC
