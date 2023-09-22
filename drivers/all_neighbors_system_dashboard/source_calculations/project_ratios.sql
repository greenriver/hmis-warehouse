SELECT TOP(@MaxRows)
    vDRTRRProjects.[ProgramType] AS [Program Type],

    vDRTRRProjects.[ProgramID] AS [Program ID],

    vDRTRRProjects.[ProgramName] AS [Program Name],

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

    COUNT(DISTINCT(C.ClientID)) AS [Clients by DemCat]

    SUM(COUNT(DISTINCT(C.ClientID))) OVER(PARTITION BY vDRTRRProjects.ProgramID) AS [Clients by Segment],

    COUNT(DISTINCT(CASE
        WHEN E.Relationship = 'SL'
            THEN C.ClientID
        END)) AS [HoHs by DemCat],

    SUM(COUNT(DISTINCT(CASE
        WHEN E.Relationship = 'SL'
            THEN C.ClientID
    END))) OVER(PARTITION BY vDRTRRProjects.ProgramID) AS [HoHs by Segment],

    'Project' AS [Project Category],

    @ReportStart AS [ReportStart],

    @ReportEnd AS [ReportEnd]

FROM qview_2000000305_DRTRRProjects vDRTRRProjects (nolock)
    INNER JOIN EnrollmentCase EC (nolock) ON vDRTRRProjects.ProgramID=EC.ProgramID AND EC.ActiveStatus <> 'D'
    INNER JOIN Enrollment E (nolock) ON EC.CaseID=E.CaseID AND E.ActiveStatus <> 'D'
    INNER JOIN cmClient C (nolock) ON E.ClientID=C.ClientID AND C.ActiveStatus <> 'D'
    INNER JOIN ClientCalculations vCC (nolock) ON C.ClientID=vCC.ClientID
WHERE (vDRTRRProjects.StartDate <= dbo.EndOfDayNT(@ReportEnd)
    AND (ISNULL(vDRTRRProjects.EndDate, '12/31/9999') >= @ReportStart
    AND (E.EnrollDate <= dbo.EndOfDayNT(@ReportEnd)
    AND ISNULL(E.ExitDate, '12/31/9999') >= @ReportEnd)))
    GROUP BY vDRTRRProjects.[ProgramType],vDRTRRProjects.[ProgramID],vDRTRRProjects.[ProgramName],CASE
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
        WHEN vCC.RaceList IN('7','8','9','99')  OR vCC.RaceList IS NULL /*'7' is what Eccovia uses for data not collected in this case*/
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
