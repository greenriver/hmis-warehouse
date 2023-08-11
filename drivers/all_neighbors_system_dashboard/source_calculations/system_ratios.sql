SELECT TOP(@MaxRows)
    P.[ProgramType] AS [Program Type],

    CASE
        WHEN P.ProgramType = 14
            THEN 'CAS'
        ELSE 'Homeless'
    END AS [Project Category],

    CASE
        WHEN vCC.RaceList LIKE '%0%'
            THEN CASE
                WHEN RIGHT(vCC.RaceList,1) = '1'
                    THEN 'American Indian, Alaska Native, or Indigenous'
                WHEN RIGHT(vCC.RaceList,1) = '2'
                    THEN 'Asian or Asian American'
                WHEN RIGHT(vCC.RaceList,1) = '3'
                    THEN 'Black, African American, or African'
                WHEN RIGHT(vCC.RaceList,1) = '4'
                    THEN 'Native Hawaiian or Pacific Islander'
                WHEN RIGHT(vCC.RaceList,1) = '5'
                    THEN 'White'
                ELSE 'Unknown'
           END
        WHEN vCC.RaceList IN('7','8','9','99') OR vCC.RaceList IS NULL /*'7' is what Eccovia uses for data not collected in this case*/
            THEN 'Unknown'
        ELSE vCC.RaceDesc
    END AS [RaceDesc],

    CASE
        WHEN C.HUDEthnicity IN('8','9','99')
            THEN 'Unknown'
        WHEN C.HUDEthnicity = 'H'
            THEN 'Hispanic/Non-Latin(a)(o)(x)'
        WHEN C.HUDEthnicity = 'O'
            THEN 'Non-Hispanic/Non-Latin(a)(o)(x)'
        ELSE C.HUDEthnicity
    END AS [Ethnicity],

    COUNT(DISTINCT(C.ClientID)) AS [Clients by DemCat],

    SUM(COUNT(DISTINCT(C.ClientID))) OVER(PARTITION BY P.ProgramType) AS [Clients by Segment],

    COUNT(DISTINCT(CASE
        WHEN E.Relationship = 'SL'
            THEN C.ClientID
        END)) AS [HoHs by DemCat],

    SUM( COUNT(DISTINCT(CASE
        WHEN E.Relationship = 'SL'
            THEN C.ClientID
        END))) OVER(PARTITION BY P.ProgramType) AS [HoHs by Segment],

    @ReportStart AS [ReportStart],

    @ReportEnd AS [ReportEnd]

FROM Programs P (nolock)
    INNER JOIN EnrollmentCase EC (nolock) ON P.ProgramID=EC.ProgramID AND EC.ActiveStatus <> 'D'
    INNER JOIN Enrollment E (nolock) ON EC.CaseID=E.CaseID AND E.ActiveStatus <> 'D'
    INNER JOIN cmClient C (nolock) ON E.ClientID=C.ClientID AND C.ActiveStatus <> 'D'
    INNER JOIN ClientCalculations vCC (nolock) ON C.ClientID=vCC.ClientID
WHERE (([P].[HMISParticipating] = 1
    AND ([P].[ProgramType] IN ('1','2','4','8','14')
    AND (ISNULL(P.EndDate, '12/31/9999') >= @ReportStart
    AND P.StartDate <= dbo.EndOfDayNT(@ReportEnd))))
    AND (E.EnrollDate <= dbo.EndOfDayNT(@ReportEnd)
    AND ISNULL(E.ExitDate, '12/31/9999') >= @ReportEnd))
    AND (P.ActiveStatus <> 'D')
GROUP BY P.[ProgramType],CASE
        WHEN P.ProgramType = 14
        THEN 'CAS'
        ELSE 'Homeless'
    END, CASE
        WHEN vCC.RaceList LIKE '%0%'
            THEN CASE
                WHEN RIGHT(vCC.RaceList,1) = '1'
                    THEN 'American Indian, Alaska Native, or Indigenous'
                WHEN RIGHT(vCC.RaceList,1) = '2'
                    THEN 'Asian or Asian American'
                WHEN RIGHT(vCC.RaceList,1) = '3'
                    THEN 'Black, African American, or African'
                WHEN RIGHT(vCC.RaceList,1) = '4'
                    THEN 'Native Hawaiian or Pacific Islander'
                WHEN RIGHT(vCC.RaceList,1) = '5'
                    THEN 'White'
                ELSE 'Unknown'
            END
        WHEN vCC.RaceList IN('7','8','9','99') OR vCC.RaceList IS NULL /*'7' is what Eccovia uses for data not collected in this case*/
            THEN 'Unknown'
        ELSE vCC.RaceDesc
    END, CASE
        WHEN C.HUDEthnicity IN('8','9','99')
            THEN 'Unknown'
        WHEN C.HUDEthnicity = 'H'
            THEN 'Hispanic/Non-Latin(a)(o)(x)'
        WHEN C.HUDEthnicity = 'O'
            THEN 'Non-Hispanic/Non-Latin(a)(o)(x)'
        ELSE C.HUDEthnicity
    END