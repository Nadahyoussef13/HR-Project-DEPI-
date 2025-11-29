SELECT e.EmployeeID,
       e.FirstName,
       e.LastName,
       e.Department,
       p.ReviewDate,
       p.RatingLevel,
       p.SatisfactionLevel
FROM employee_cleaned e
JOIN performance_valid p
    ON e.EmployeeID = p.EmployeeID;

	                                               #Employee_Cleaned#


#What_is_the_total_number_of_employees_by_department_job_role_and_location?#

SELECT Department, COUNT(*) AS NumEmployees
FROM employee_cleaned
GROUP BY Department
ORDER BY NumEmployees DESC;

SELECT JobRole, COUNT(*) AS NumEmployees
FROM employee_cleaned
GROUP BY JobRole
ORDER BY NumEmployees DESC;

SELECT State AS Location, COUNT(*) AS NumEmployees
FROM employee_cleaned
GROUP BY State
ORDER BY NumEmployees DESC;


#What_is_the_gender_and_education_level_distribution_across_departments?#

SELECT Department, Gender, EducationField, COUNT(*) AS Count
FROM employee_cleaned
GROUP BY Department, Gender, EducationField
ORDER BY Department, Gender;


#What_is_the_average_age_years_at_company_and_salary_per_department?#

SELECT Department,
       ROUND(AVG(Age),2) AS AvgAge,
       ROUND(AVG(YearsAtCompany),2) AS AvgYearsAtCompany,
       ROUND(AVG(Salary_Cleaned),2) AS AvgSalary
FROM employee_cleaned
GROUP BY Department
ORDER BY AvgSalary DESC;


#What_is_the_median_salary_per_job_role_and_education_level?#
WITH SalaryRanks AS (
    SELECT 
        JobRole,
        EducationLevel_txt,
        TRY_CAST(Salary_Cleaned AS FLOAT) AS Salary_Cleaned,
        ROW_NUMBER() OVER (
            PARTITION BY JobRole, EducationLevel_txt 
            ORDER BY TRY_CAST(Salary_Cleaned AS FLOAT)
        ) AS rn,
        COUNT(*) OVER (PARTITION BY JobRole, EducationLevel_txt) AS cnt
    FROM employee_cleaned
    WHERE Salary_Cleaned IS NOT NULL
)
SELECT 
    JobRole,
    EducationLevel_txt,
    AVG(1.0 * Salary_Cleaned) AS MedianSalary
FROM SalaryRanks
WHERE rn IN ((cnt + 1) / 2, (cnt + 2) / 2)
GROUP BY JobRole, EducationLevel_txt
ORDER BY JobRole, EducationLevel_txt;


#How_many_employees_were_hired_each_year#
SELECT 
    YEAR(HireDate) AS HireYear,
    COUNT(*) AS Hires
FROM employee_cleaned
WHERE HireDate IS NOT NULL
GROUP BY YEAR(HireDate)
ORDER BY HireYear;

#What_is_the_average_time_in_current_role_per_department?#
SELECT 
    Department,
    ROUND(AVG(YearsInMostRecentRole), 2) AS AvgYearsInMostRecentRole
FROM employee_cleaned
GROUP BY Department
ORDER BY AvgYearsInMostRecentRole DESC;


#What_is_the_average_tenure_YearsAtCompany_by_department_and_jobrole?
SELECT 
    Department,
    JobRole,
    ROUND(AVG(YearsAtCompany), 2) AS AvgTenure
FROM employee_cleaned
GROUP BY Department, JobRole
ORDER BY AvgTenure DESC;


#Which_departments_have_the_highest_average_experience?#
SELECT 
    Department,
    ROUND(AVG(YearsAtCompany), 2) AS AvgExperience
FROM employee_cleaned
GROUP BY Department
ORDER BY AvgExperience DESC;


#How_many_employees_have_>10_years_of_service_vs_<2_years?#
SELECT 
    SUM(CASE WHEN YearsAtCompany > 10 THEN 1 ELSE 0 END) AS CountOver10Years,
    SUM(CASE WHEN YearsAtCompany < 2 THEN 1 ELSE 0 END) AS CountUnder2Years
FROM employee_cleaned;


#How_many_employees_are_currently_active_vs_left?#

SELECT 
    Attrition_str AS Status, 
    COUNT(*) AS Count
FROM employee_cleaned
GROUP BY Attrition_str;


                                                   #Performance_Data#

#Average_SelfRating_and_ManagerRating_by_department#
SELECT
    ec.Department,
    AVG(
        CASE 
            WHEN pv.SelfRatingLevel = 'Above and Beyond' THEN 5
            WHEN pv.SelfRatingLevel = 'Exceeds Expectation' THEN 4
            WHEN pv.SelfRatingLevel = 'Meets Expectation' THEN 3
            WHEN pv.SelfRatingLevel = 'Needs Improvement' THEN 2
            WHEN pv.SelfRatingLevel = 'Below Expectation' THEN 1
            ELSE NULL
        END
    ) AS Avg_SelfRating,
    AVG(
        CASE 
            WHEN pv.RatingLevel = 'Above and Beyond' THEN 5
            WHEN pv.RatingLevel = 'Exceeds Expectation' THEN 4
            WHEN pv.RatingLevel = 'Meets Expectation' THEN 3
            WHEN pv.RatingLevel = 'Needs Improvement' THEN 2
            WHEN pv.RatingLevel = 'Below Expectation' THEN 1
            ELSE NULL
        END
    ) AS Avg_ManagerRating,
    COUNT(*) AS ReviewCount
FROM dbo.performance_valid AS pv
LEFT JOIN dbo.employee_cleaned AS ec
    ON pv.EmployeeID = ec.EmployeeID
GROUP BY ec.Department
ORDER BY Avg_ManagerRating DESC;


#Distribution_of_performance_Ratings_1_to_5_Scale#
WITH RatingMapped AS (
    SELECT
        CASE 
            WHEN RatingLevel = 'Above and Beyond'      THEN 5
            WHEN RatingLevel = 'Exceeds Expectation'   THEN 4
            WHEN RatingLevel = 'Meets Expectation'     THEN 3
            WHEN RatingLevel = 'Needs Improvement'     THEN 2
            WHEN RatingLevel = 'Below Expectation'     THEN 1
            ELSE NULL
        END AS RatingNumeric
    FROM dbo.performance_valid
    WHERE RatingLevel IS NOT NULL
)
SELECT
    RatingNumeric AS Rating_Scale,
    COUNT(*) AS Rating_Count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS Percentage_of_Total
FROM RatingMapped
GROUP BY RatingNumeric
ORDER BY RatingNumeric DESC;

#Departments_with_the_Highest_Average_Performance_Scores#
SELECT
    ec.Department,
    ROUND(AVG(
        CASE 
            WHEN pv.RatingLevel = 'Above and Beyond'      THEN 5
            WHEN pv.RatingLevel = 'Exceeds Expectation'   THEN 4
            WHEN pv.RatingLevel = 'Meets Expectation'     THEN 3
            WHEN pv.RatingLevel = 'Needs Improvement'     THEN 2
            WHEN pv.RatingLevel = 'Below Expectation'     THEN 1
            ELSE NULL
        END
    ), 2) AS Avg_PerformanceScore,
    COUNT(*) AS ReviewCount
FROM dbo.performance_valid AS pv
LEFT JOIN dbo.employee_cleaned AS ec
    ON pv.EmployeeID = ec.EmployeeID
WHERE pv.RatingLevel IS NOT NULL
GROUP BY ec.Department
HAVING COUNT(*) > 5  
ORDER BY Avg_PerformanceScore DESC;


#Year_over_Year_Performance_Change_(Improved/Declined/Same)#
WITH RatingNumeric AS (
    SELECT
        EmployeeID,
        YEAR(ReviewDate) AS ReviewYear,
        CASE 
            WHEN RatingLevel = 'Above and Beyond'      THEN 5
            WHEN RatingLevel = 'Exceeds Expectation'   THEN 4
            WHEN RatingLevel = 'Meets Expectation'     THEN 3
            WHEN RatingLevel = 'Needs Improvement'     THEN 2
            WHEN RatingLevel = 'Below Expectation'     THEN 1
            ELSE NULL
        END AS RatingScore
    FROM dbo.performance_valid
    WHERE RatingLevel IS NOT NULL
),
Ranked AS (
    SELECT
        EmployeeID,
        ReviewYear,
        RatingScore,
        LAG(RatingScore) OVER (PARTITION BY EmployeeID ORDER BY ReviewYear) AS PrevRatingScore
    FROM RatingNumeric
)
SELECT
    CASE 
        WHEN RatingScore > PrevRatingScore THEN 'Improved'
        WHEN RatingScore < PrevRatingScore THEN 'Declined'
        WHEN RatingScore = PrevRatingScore THEN 'No Change'
        ELSE 'First Review'
    END AS Performance_Change,
    COUNT(*) AS Employee_Count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS Percentage_of_Total
FROM Ranked
WHERE PrevRatingScore IS NOT NULL
GROUP BY
    CASE 
        WHEN RatingScore > PrevRatingScore THEN 'Improved'
        WHEN RatingScore < PrevRatingScore THEN 'Declined'
        WHEN RatingScore = PrevRatingScore THEN 'No Change'
        ELSE 'First Review'
    END
ORDER BY Percentage_of_Total DESC;

#Employees_with_Consistent_Performance_Across_Review_Cycles#
WITH RatingNumeric AS (
    SELECT
        pv.EmployeeID,
        CASE 
            WHEN pv.RatingLevel = 'Above and Beyond'      THEN 5
            WHEN pv.RatingLevel = 'Exceeds Expectation'   THEN 4
            WHEN pv.RatingLevel = 'Meets Expectation'     THEN 3
            WHEN pv.RatingLevel = 'Needs Improvement'     THEN 2
            WHEN pv.RatingLevel = 'Below Expectation'     THEN 1
            ELSE NULL
        END AS RatingScore
    FROM dbo.performance_valid pv
    WHERE pv.RatingLevel IS NOT NULL
),
Stats AS (
    SELECT
        EmployeeID,
        MIN(RatingScore) AS MinRating,
        MAX(RatingScore) AS MaxRating,
        AVG(RatingScore) AS AvgRating,
        COUNT(*) AS ReviewCount
    FROM RatingNumeric
    GROUP BY EmployeeID
)
SELECT
    s.EmployeeID,
    ec.FirstName,
    ec.Department,
    s.MinRating,
    s.MaxRating,
    s.AvgRating,
    s.ReviewCount,
    CASE 
        WHEN s.MaxRating - s.MinRating <= 1 THEN 'Consistent'
        ELSE 'Variable'
    END AS PerformanceConsistency
FROM Stats s
LEFT JOIN dbo.employee_cleaned ec
    ON s.EmployeeID = ec.EmployeeID
WHERE s.ReviewCount >= 2  -- Only employees with 2+ review cycles
ORDER BY s.AvgRating DESC;


#Average_Time_Since_Last_Performance_Review__in_days#
WITH LastReview AS (
    SELECT
        pv.EmployeeID,
        MAX(pv.ReviewDate) AS LastReviewDate
    FROM dbo.performance_valid pv
    WHERE pv.ReviewDate IS NOT NULL
    GROUP BY pv.EmployeeID
)
SELECT
    ROUND(AVG(DATEDIFF(DAY, lr.LastReviewDate, GETDATE()) * 1.0), 2) AS Avg_Days_Since_Last_Review,
    COUNT(lr.EmployeeID) AS Employee_Count
FROM LastReview lr;

                                            #Attrition#

#Overall_Attrition_Rate#
ALTER TABLE dbo.employee_cleaned 
ALTER COLUMN Attrition VARCHAR(10);
SELECT
    COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Terminated', 'Left', '1') THEN 1 END) AS Employees_Left,
    COUNT(*) AS Total_Employees,
    ROUND(100.0 * COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Terminated', 'Left', '1') THEN 1 END) 
           / COUNT(*), 2) AS Attrition_Rate_Percent
FROM dbo.employee_cleaned ec;


#Attrition_Rate_by_Department#
SELECT
    ec.Department,
    COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Terminated', 'Left', '1') THEN 1 END) AS Employees_Left,
    COUNT(*) AS Total_Employees,
    ROUND(100.0 * COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Terminated', 'Left', '1') THEN 1 END) 
           / COUNT(*), 2) AS Attrition_Rate_Percent
FROM dbo.employee_cleaned ec
GROUP BY ec.Department
ORDER BY Attrition_Rate_Percent DESC;

#Attrition_Rate_by_Job_Role#
SELECT
    JobRole,
    COUNT(*) AS Total_Employees,
    COUNT(CASE WHEN Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 1 END) AS Employees_Left,
    ROUND(100.0 * COUNT(CASE WHEN Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 1 END) 
           / COUNT(*), 2) AS Attrition_Rate_Percent
FROM dbo.employee_cleaned
GROUP BY JobRole
ORDER BY Attrition_Rate_Percent DESC;

#Average_Tenure_of_Employees_Who_Left_vs_Stayed#
SELECT
    CASE 
        WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 'Left Company'
        ELSE 'Still Employed'
    END AS EmploymentStatus,
    ROUND(AVG(
        CASE 
            WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') 
                 AND ec.AttritionDate IS NOT NULL THEN 
                 DATEDIFF(DAY, ec.HireDate, ec.AttritionDate) / 365.0
            ELSE 
                 DATEDIFF(DAY, ec.HireDate, GETDATE()) / 365.0
        END
    ), 2) AS Avg_Tenure_Years,
    COUNT(*) AS EmployeeCount
FROM dbo.employee_cleaned AS ec
WHERE ec.HireDate IS NOT NULL
GROUP BY 
    CASE 
        WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 'Left Company'
        ELSE 'Still Employed'
    END;

#Job_Roles_with_Highest_Early_Attrition_(<1_Year)#
	SELECT
    ec.JobRole,
    COUNT(*) AS Total_Employees,
    COUNT(CASE 
              WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') 
                   AND DATEDIFF(DAY, ec.HireDate, ISNULL(ec.AttritionDate, GETDATE())) / 365.0 < 1
              THEN 1 
          END) AS Early_Leavers,
    ROUND(
        100.0 * COUNT(CASE 
                          WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') 
                               AND DATEDIFF(DAY, ec.HireDate, ISNULL(ec.AttritionDate, GETDATE())) / 365.0 < 1
                          THEN 1 
                      END)
        / COUNT(*),
        2
    ) AS Early_Attrition_Rate_Percent
FROM dbo.employee_cleaned ec
GROUP BY ec.JobRole
ORDER BY Early_Attrition_Rate_Percent DESC;

#Attrition_Rate_by_Performance_Level#
SELECT
    pv.RatingLevel,
    COUNT(*) AS Total_Reviews,
    COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 1 END) AS Employees_Left,
    ROUND(
        100.0 * COUNT(CASE WHEN ec.Attrition IN ('Yes', 'Left', '1', 'Terminated') THEN 1 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate_Percent
FROM dbo.performance_valid pv
JOIN dbo.employee_cleaned ec
    ON pv.EmployeeID = ec.EmployeeID
WHERE pv.RatingLevel IS NOT NULL
GROUP BY pv.RatingLevel
ORDER BY Attrition_Rate_Percent DESC;

#How_does_attrition_vary_by_performance_level#
SELECT
    pv.RatingLevel,
    COUNT(*) AS Total_Employees,
    COUNT(
        CASE 
            WHEN (   (TRY_CAST(ec.Attrition AS INT) = 1) 
                  OR (ec.Attrition IN ('Yes', '1', 'Left', 'Terminated')) )
            THEN 1 
        END
    ) AS Employees_Left,
    ROUND(
        100.0 * COUNT(
            CASE 
                WHEN (   (TRY_CAST(ec.Attrition AS INT) = 1) 
                      OR (ec.Attrition IN ('Yes', '1', 'Left', 'Terminated')) )
                THEN 1 
            END
        ) / COUNT(*),
        2
    ) AS Attrition_Rate_Percent
FROM dbo.performance_valid AS pv
INNER JOIN dbo.employee_cleaned AS ec
    ON pv.EmployeeID = ec.EmployeeID
WHERE pv.RatingLevel IS NOT NULL
GROUP BY pv.RatingLevel
ORDER BY Attrition_Rate_Percent DESC;

                                                         #Diagnostic_Analysis#
														 #Employee_Insights#

#Does salary correlate with tenure or education?#
SELECT
    ec.EducationLevel_txt AS EducationLevel,
    ROUND(AVG(ec.Salary_Cleaned), 2) AS Avg_Salary,
    ROUND(AVG(DATEDIFF(DAY, ec.HireDate, GETDATE()) / 365.0), 2) AS Avg_Tenure_Years,
    COUNT(*) AS EmployeeCount
FROM dbo.employee_cleaned ec
WHERE ec.Salary_Cleaned IS NOT NULL
GROUP BY ec.EducationLevel_txt
ORDER BY Avg_Salary DESC;


#Are higher education levels linked to longer retention or higher pay?#
SELECT
    ec.EducationLevel_txt AS EducationLevel,
    ROUND(AVG(DATEDIFF(DAY, ec.HireDate, ISNULL(ec.AttritionDate, GETDATE())) / 365.0), 2) AS Avg_Tenure_Years,
    ROUND(AVG(ec.Salary_Cleaned), 2) AS Avg_Salary,
    ROUND(
        100.0 * COUNT(CASE 
                          WHEN (TRY_CAST(ec.Attrition AS INT) = 1 
                                OR ec.Attrition IN ('Yes','1','Left','Terminated')) 
                          THEN 1 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate_Percent
FROM dbo.employee_cleaned ec
GROUP BY ec.EducationLevel_txt
ORDER BY Avg_Salary DESC;

#Are salary gaps influencing attrition or dissatisfaction?#
SELECT
    ec.Department,
    ROUND(AVG(ec.Salary_Cleaned), 2) AS Avg_Salary,
    ROUND(STDEV(ec.Salary_Cleaned), 2) AS Salary_StdDev,
    ROUND(
        100.0 * COUNT(CASE 
                          WHEN (TRY_CAST(ec.Attrition AS INT) = 1 
                                OR ec.Attrition IN ('Yes','1','Left','Terminated'))
                          THEN 1 END)
        / COUNT(*),
        2
    ) AS Attrition_Rate_Percent
FROM dbo.employee_cleaned ec
WHERE ec.Salary_Cleaned IS NOT NULL
GROUP BY ec.Department
ORDER BY Salary_StdDev DESC;

#Do older employees earn more than peers with similar tenure?#
WITH AgeBands AS (
    SELECT 
        CASE 
            WHEN Age < 25 THEN '<25'
            WHEN Age BETWEEN 25 AND 34 THEN '25–34'
            WHEN Age BETWEEN 35 AND 44 THEN '35–44'
            WHEN Age BETWEEN 45 AND 54 THEN '45–54'
            WHEN Age >= 55 THEN '55+'
            ELSE 'Unknown'
        END AS AgeGroup,
        DATEDIFF(DAY, HireDate, GETDATE()) / 365.0 AS Tenure_Years,
        Salary_Cleaned
    FROM dbo.employee_cleaned
    WHERE Salary_Cleaned IS NOT NULL AND Age IS NOT NULL
)
SELECT
    AgeGroup,
    ROUND(AVG(Salary_Cleaned), 2) AS Avg_Salary,
    ROUND(AVG(Tenure_Years), 2) AS Avg_Tenure,
    ROUND(AVG(Salary_Cleaned / NULLIF(Tenure_Years, 0)), 2) AS Avg_Salary_Per_TenureYear
FROM AgeBands
GROUP BY AgeGroup
ORDER BY Avg_Salary DESC;



                                                     #Performance_Insights#

#Does_higher_performance_correlate_with_higher_salary_or_promotions?#
SELECT
    pv.RatingLevel,
    COUNT(*) AS EmployeeCount,

    -- Average salary by performance level
    ROUND(AVG(TRY_CAST(ec.Salary_Cleaned AS FLOAT)), 2) AS Avg_Salary,

    -- Average time to last promotion (in years)
    ROUND(AVG(
        CASE 
            WHEN ec.YearsSinceLastPromotion IS NOT NULL 
                 AND ec.HireDate IS NOT NULL 
            THEN DATEDIFF(DAY, ec.HireDate, ec.YearsSinceLastPromotion) / 365.0
        END
    ), 2) AS Avg_Years_To_Promotion,

 
    ROUND(100.0 * 
        SUM(
            CASE 
                WHEN ec.YearsSinceLastPromotion IS NOT NULL 
                     AND DATEDIFF(YEAR, ec.HireDate, ec.YearsSinceLastPromotion) <= 3 
                THEN 1 ELSE 0 END
        ) / COUNT(*), 2) AS Promoted_Within_3Y_Percent
FROM dbo.performance_valid pv
JOIN dbo.employee_cleaned ec
    ON pv.EmployeeID = ec.EmployeeID
WHERE pv.RatingLevel IS NOT NULL
GROUP BY pv.RatingLevel
ORDER BY Avg_Salary DESC;


#Performance_by_Gender,_Department,_and_Education#
SELECT
    ec.Department,
    ec.Gender,
    ec.EducationLevel_txt AS EducationLevel,
    COUNT(*) AS ReviewCount,
    -- Convert textual ratings to numeric scores for averaging
    ROUND(AVG(
        CASE 
            WHEN pv.RatingLevel = 'Above and Beyond'     THEN 5
            WHEN pv.RatingLevel = 'Exceeds Expectation'  THEN 4
            WHEN pv.RatingLevel = 'Meets Expectation'    THEN 3
            WHEN pv.RatingLevel = 'Needs Improvement'    THEN 2
            WHEN pv.RatingLevel = 'Below Expectation'    THEN 1
        END
    ), 2) AS Avg_PerformanceScore,
    -- Optional: distribution of each rating type
    SUM(CASE WHEN pv.RatingLevel = 'Above and Beyond'     THEN 1 ELSE 0 END) AS Count_AboveAndBeyond,
    SUM(CASE WHEN pv.RatingLevel = 'Exceeds Expectation'  THEN 1 ELSE 0 END) AS Count_Exceeds,
    SUM(CASE WHEN pv.RatingLevel = 'Meets Expectation'    THEN 1 ELSE 0 END) AS Count_Meets,
    SUM(CASE WHEN pv.RatingLevel = 'Needs Improvement'    THEN 1 ELSE 0 END) AS Count_NeedsImprovement,
    SUM(CASE WHEN pv.RatingLevel = 'Below Expectation'    THEN 1 ELSE 0 END) AS Count_Below
FROM dbo.performance_valid pv
JOIN dbo.employee_cleaned ec
    ON pv.EmployeeID = ec.EmployeeID
WHERE pv.RatingLevel IS NOT NULL
GROUP BY ec.Department, ec.Gender, ec.EducationLevel_txt
ORDER BY ec.Department, Avg_PerformanceScore DESC;

#Do_performance_trends_predict_future_attrition?#
WITH PerformanceTrend AS (
    SELECT
        pv.EmployeeID,
        ec.Department,
        ec.Gender,
        ec.JobRole,
        ec.EducationLevel_txt AS EducationLevel,
        ec.Attrition,
        CASE 
            WHEN pv.RatingLevel = 'Above and Beyond'     THEN 5
            WHEN pv.RatingLevel = 'Exceeds Expectation'  THEN 4
            WHEN pv.RatingLevel = 'Meets Expectation'    THEN 3
            WHEN pv.RatingLevel = 'Needs Improvement'    THEN 2
            WHEN pv.RatingLevel = 'Below Expectation'    THEN 1
        END AS RatingScore,
        pv.ReviewDate
    FROM dbo.performance_valid pv
    JOIN dbo.employee_cleaned ec
        ON pv.EmployeeID = ec.EmployeeID
    WHERE pv.RatingLevel IS NOT NULL),
PerformanceStats AS (
    SELECT
        EmployeeID,
        Department,
        Gender,
        JobRole,
        EducationLevel,
        MAX(TRY_CAST(Attrition AS NVARCHAR(20))) AS Attrition,
        COUNT(*) AS ReviewCount,
        MIN(RatingScore) AS MinScore,
        MAX(RatingScore) AS MaxScore,
        ROUND(AVG(RatingScore), 2) AS AvgScore
    FROM PerformanceTrend
    GROUP BY EmployeeID, Department, Gender, JobRole, EducationLevel)
SELECT
    Department,
    COUNT(*) AS TotalEmployees,
    SUM(CASE WHEN Attrition IN ('Yes','1','Left','Terminated') THEN 1 ELSE 0 END) AS EmployeesLeft,
    ROUND(100.0 * SUM(CASE WHEN Attrition IN ('Yes','1','Left','Terminated') THEN 1 ELSE 0 END) / COUNT(*), 2) AS AttritionRate,
    ROUND(AVG(CASE WHEN Attrition IN ('Yes','1','Left','Terminated') THEN AvgScore END), 2) AS AvgScore_Left,
    ROUND(AVG(CASE WHEN Attrition NOT IN ('Yes','1','Left','Terminated') THEN AvgScore END), 2) AS AvgScore_Stayed,
    SUM(CASE 
            WHEN Attrition IN ('Yes','1','Left','Terminated') 
                 AND MinScore < MaxScore THEN 1 ELSE 0 END
    ) AS DeclinedBeforeLeaving
FROM PerformanceStats
GROUP BY Department
ORDER BY AttritionRate DESC;


