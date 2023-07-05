SELECT TOP(@MaxRows)
    CASE
        WHEN vDRTRRProjects.ProgramType = 9
            THEN 'Emergency Housing Voucher'
        WHEN vDRTRRProjects.ProgramType = 55
            THEN 'Rapid Rehousing'
        ELSE 'ERROR'
    END AS [Intervention],

    EC.[CaseID] AS [Case ID],

    CASE
        WHEN MAX(CAST((DATEDIFF(day,C.aBirthdate,E.EnrollDate) / 365.25) as int)) OVER( PARTITION BY EC.CaseID) < 18
            THEN 'Children Only'
        ELSE
            CASE
                WHEN COUNT(*) OVER(PARTITION BY EC.CaseID) > 1 AND MIN(CAST((DATEDIFF(day,C.Birthdate,E.EnrollDate) / 365.25) as int)) OVER( PARTITION BY E.CaseID) < 18
                    THEN 'Adults and Children'
                ELSE 'Adults Only'
            END
    END AS [Household Type], /*Referenced 2022 Data Dictionary Appendix A. Generally mapped to categories except when noted*/

    MAX(
        CASE
            WHEN UDE.PriorResidence IS NULL
                THEN NULL
            WHEN UDE.PriorResidence IN(30,17,37,8,9,99)
                THEN 'Unknown' /*Includes 'Other'*/
            WHEN UDE.PriorResidence = 16
                THEN 'Unsheltered'
            WHEN UDE.PriorResidence IN(1,18,2)
                THEN 'Sheltered' /*Includes TH b/c more closely corresponds to PIT*/
            WHEN UDE.PriorResidence IN(15,6,7,25,4,5)
                THEN 'Institutional' /*These conform entirely to Data Dict*/
            WHEN UDE.PriorResidence IN(29,14,32,13,12,27,13,12,22,35,36,23,26,28,19,3,31,33,34,10,20,21,11)
                THEN 'Housed' /*These are all 'Temporary and Permanent' but excludes TH*/
            WHEN UDE.PriorResidence = 24
                THEN 'Deceased' /*This is retained as own category b/c there will because doesn't fit into categories and will enable exclusion from recordset if desired.*/
            ELSE 'ERROR'
        END
    ) OVER(PARTITION BY EC.CaseID) AS [HH Prior Living Situation],

    E.[EnrollID] AS [Enroll ID],

    E.[EnrollDate] AS [Enroll Date],

    MIN(HMI.DateOfMoveIn) OVER(PARTITION BY EC.CaseID) AS [Move In Date],

    CASE
        WHEN E.ExitDate > @ReportEnd
            THEN NULL
        ELSE E.ExitDate
    END AS [Exit Date],

    ISNULL(
        CASE
            WHEN E.ExitDate > @ReportEnd
                THEN NULL
            ELSE E.ExitDate
        END,
        @ReportEnd
    ) AS [Adjusted Exit Date],

    CASE
        WHEN E.ExitDestination IS NULL
            THEN NULL
        WHEN E.ExitDestination IN(26,11,21,3,10,28,20,19,22,23,31,33,34)
            THEN 'Permanent'
        WHEN E.ExitDestination IN(6,24,15)
            THEN 'Excludable'
        WHEN E.ExitDestination IN(8,9,99,30,17)
            THEN 'Unknown'
        ELSE 'Non-Permanent'
    END AS [APR_ExitType],

    E.[ExitDestination] AS [ExitDestination_Int],

    (SELECT Description FROM dbo.ListItemsByID(1507) WHERE Item=E.ExitDestination) AS [ExitDestination_Val],

    E.[Relationship] AS [Relationship],

    E.[ClientID] AS [Client ID],

    CAST((DATEDIFF(day,C.Birthdate,E.EnrollDate) / 365.25) as int) AS [Age],

    vCC.[GenderDesc] AS [Gender],

    vCC.[RaceDesc] AS [Race],

    vCC.[RaceDescList] AS [RaceDescList],

    cbEthnicity.[ItemDesc] AS [Ethnicity],
/*Main Query REQUIREMENTS:
- @ReportStart variable
- @ReportEnd variable
- Inclusion of EnrollmentCase table in data model and EnrollmentCase.CaseID in query table
-- Alternately, change the EnrollmentCase.CaseID to Enrollment.CaseID in the final WHERE clause below and you don't have to have EnrollmentCase table
and just need Enrollment.CaseID in your query's table.
*/
    /*MIN is used to get the earliest enroll date for the case, but the most recent CAS enrollment case is returned based on the Rank in the subquery*/
    (SELECT MIN(X.CE_EnrollDate)
        FROM
            (SELECT
                XEC.CaseID AS CaseID,
                XE.ClientID AS ClientID,
                CASXE.EnrollID AS CE_EnrollID,
                CASXE.EnrollDate AS CE_EnrollDate,
                DENSE_RANK() OVER(PARTITION BY XE.ClientID ORDER BY CASXE.EnrollDate DESC, CASXE.EnrollID DESC) AS RankNum
            FROM
                /*This enrollment table is meant to mirror your main query (fine if it's more inclusive)*/
                Enrollment XE (nolock) INNER JOIN EnrollmentCase XEC (nolock) ON XE.CaseID = XEC.CaseID AND XEC.ActiveStatus <> 'D'
                /*This restricts to DRTRR Housing Enrollments for the lookup*/
                INNER JOIN qview_2000000305_DRTRRProjects XvP(nolock) ON XEC.ProgramID = XvP.ProgramID
                /*This block is the connection to a copy of Enrollments table filtered for CAS*/
                INNER JOIN Enrollment CASXE (nolock) ON XE.ClientID = CASXE.ClientID AND CASXE.EnrollDate <= XE.EnrollDate AND CASXE.ActiveStatus <> 'D'
                INNER JOIN EnrollmentCase CASXEC (nolock) ON CASXE.CaseID = CASXEC.CaseID AND CASXEC.ProgramID = 721
            WHERE XE.ActiveStatus <> 'D' AND XE.EnrollDate <= dbo.EndOfDayNT(@ReportEnd) AND ISNULL(XE.ExitDate, '12/31/9999') >= @ReportStart) AS X
        WHERE X.CaseID = EC.CaseID /*Make sure this matches the CaseID table you're using in your main query*/
        AND X.RankNum = 1
        ) AS [CAS Enroll Date],

    (SELECT MAX(X.EventDate)
        FROM
            (SELECT
                XEC.CaseID AS CaseID,
                XE.ClientID AS ClientID,
                XS.ServiceID AS ServiceID,
                XS.BeginDate AS EventDate,
                XX.Location AS Location,
                DENSE_RANK() OVER(PARTITION BY XEC.CaseID ORDER BY XS.BeginDate DESC, XS.ServiceID DESC) AS RankNum
            FROM
                Enrollment XE (nolock)
                LEFT JOIN EnrollmentCase XEC (nolock) ON XE.CaseID = XEC.CaseID AND XEC.ActiveStatus <> 'D'
                INNER JOIN qview_2000000305_DRTRRProjects XvP(nolock) ON XEC.ProgramID = XvP.ProgramID
                INNER JOIN Service XS (nolock) ON XE.ClientID = XS.ClientID AND XS.ActiveStatus <> 'D'
                INNER JOIN ServiceReferral XSR (nolock) ON XS.ServiceID = XSR.ServiceID AND XSR.ServiceCodeID IN(433,435,436,437,438,439,440,441,443,444,445,446,447,968,974,975,976,1114)
                INNER JOIN CEEvent XX (nolock) ON XS.ServiceID = XX.ServiceID
            WHERE XE.ActiveStatus <> 'D' AND XE.EnrollDate <= dbo.EndOfDayNT(@ReportEnd)
                AND ISNULL(XE.ExitDate, '12/31/9999') >= @ReportStart
                AND XX.Location = XvP.ProgramID
                AND XS.BeginDate <= XE.EnrollDate) AS X
        WHERE X.CaseID = EC.CaseID
        AND X.RankNum = 1
    ) AS [CAS Referral Date],

    (SELECT MAX(X.ServiceID)
        FROM
            (SELECT
                XEC.CaseID AS CaseID,
                XE.ClientID AS ClientID,
                XS.ServiceID AS ServiceID,
                XS.BeginDate AS EventDate,
                XX.Location AS Location,
                DENSE_RANK() OVER(PARTITION BY XEC.CaseID ORDER BY XS.BeginDate DESC, XS.ServiceID DESC) AS RankNum
            FROM
                Enrollment XE (nolock)
                LEFT JOIN EnrollmentCase XEC (nolock) ON XE.CaseID = XEC.CaseID AND XEC.ActiveStatus <> 'D'
                INNER JOIN qview_2000000305_DRTRRProjects XvP(nolock) ON XEC.ProgramID = XvP.ProgramID
                INNER JOIN Service XS (nolock) ON XE.ClientID = XS.ClientID AND XS.ActiveStatus <> 'D'
                INNER JOIN ServiceReferral XSR (nolock) ON XS.ServiceID = XSR.ServiceID AND XSR.ServiceCodeID IN(433,435,436,437,438,439,440,441,443,444,445,446,447,968,974,975,976,1114)
                INNER JOIN CEEvent XX (nolock) ON XS.ServiceID = XX.ServiceID
            WHERE XE.ActiveStatus <> 'D'
                AND XE.EnrollDate <= dbo.EndOfDayNT(@ReportEnd)
                AND ISNULL(XE.ExitDate, '12/31/9999') >= @ReportStart
                AND XX.Location = XvP.ProgramID
                AND XS.BeginDate <= XE.EnrollDate
            ) AS X
        WHERE X.CaseID = EC.CaseID
        AND X.RankNum = 1
    ) AS [CAS Referral ID],

    (SELECT MAX(X.ReturnDate)
        FROM
            (SELECT
                XE.EnrollID AS EnrollID,
                RE.EnrollDate AS ReturnDate,
                RE.EnrollID AS ReturnID,
                /*Change above RE table field to return different information*/
                DENSE_RANK() OVER(PARTITION BY XE.EnrollID ORDER BY RE.EnrollDate ASC, RE.EnrollID ASC) AS RankNum
            FROM
                Enrollment XE (nolock)
                LEFT JOIN EnrollmentCase XEC (nolock) ON XE.CaseID = XEC.CaseID AND XEC.ActiveStatus <> 'D'
                INNER JOIN qview_2000000305_DRTRRProjects XvP(nolock) ON XEC.ProgramID = XvP.ProgramID
                INNER JOIN Enrollment RE (nolock) ON XE.ClientID = RE.ClientID AND RE.EnrollDate >= XE.ExitDate AND RE.EnrollDate <= dbo.EndOfDayNT(@ReportEnd) AND RE.ActiveStatus <> 'D'
                INNER JOIN EnrollmentCase REC (nolock) ON RE.CaseID = REC.CaseID
                INNER JOIN Programs RP (nolock) ON REC.ProgramID = RP.ProgramID
                AND RP.ProgramType IN(1,2,3,4,8,9,10,55) /*Matches SPM 2 universe. 55 is QueryDesigner code for RRH.*/
            WHERE XE.ActiveStatus <> 'D'
                AND XE.EnrollDate <= dbo.EndOfDayNT(@ReportEnd)
                AND XE.ExitDate >= @ReportStart
                AND XE.ExitDate <= dbo.EndOfDayNT(@ReportEnd)
                AND XE.ExitDestination IN(26,11,21,3,10,28,20,19,22,23,31,33,34) /*Permanent destination definition taken from SPM 2*/
                AND( DATEDIFF(day, XE.ExitDate, RE.EnrollDate) > 14
                    OR NOT(RP.ProgramType IN(3,9,10,55))) /*Deviates from SPMs in that returns to TH not subject to exemption*/
            ) AS X
        WHERE X.EnrollID = E.EnrollID
            AND X.RankNum = 1
    ) AS [Return Date],

    @ReportStart AS [Report Start],

    @ReportEnd AS [Report End], /*Also use this as linker field to the Date Dimension if scaffolding*/

    1 AS [Enrollments],

    CASE
        WHEN NOT(MIN(HMI.DateOfMoveIn) OVER(PARTITION BY EC.CaseID)) IS NULL
            THEN 1
    END AS [Move Ins],

    1 AS [ScaffoldLink],

    vDRTRRProjects.[ProgramID] AS [Program ID],

    vDRTRRProjects.[ProgramName] AS [Program Name],

    vDRTRRProjects.[ProgramType] AS [Program Type INT]

FROM qview_2000000305_DRTRRProjects vDRTRRProjects (nolock)
INNER JOIN EnrollmentCase EC (nolock) ON vDRTRRProjects.ProgramID=EC.ProgramID AND EC.ActiveStatus <> 'D'
INNER JOIN Enrollment E (nolock) ON EC.CaseID=E.CaseID  AND E.ActiveStatus <> 'D'
INNER JOIN cmClient C (nolock) ON E.ClientID=C.ClientID AND C.ActiveStatus <> 'D'
INNER JOIN ClientCalculations vCC (nolock) ON C.ClientID=vCC.ClientID
LEFT JOIN EnrollmentRRH HMI (nolock) ON E.EnrollID=HMI.EnrollID
LEFT JOIN cmComboBoxItem cbEthnicity (nolock) ON C.HUDEthnicity=cbEthnicity.Item AND ([cbEthnicity].[Combobox] = 'HUDEthnicity' AND [cbEthnicity].[ComboboxGrp] = 'Homeless') AND cbEthnicity.ActiveStatus <> 'D'
LEFT JOIN Assessment A (nolock) ON E.EnrollAssessmentID=A.AssessmentID AND [E].[Relationship] = 'SL' AND A.ActiveStatus <> 'D'
LEFT JOIN HmisDataAssessment UDE (nolock) ON A.AssessmentID=UDE.AssessmentID    AND UDE.ActiveStatus <> 'D'

WHERE (vDRTRRProjects.StartDate <= dbo.EndOfDayNT(@ReportEnd) AND (ISNULL(vDRTRRProjects.EndDate, '12/31/9999') >= @ReportStart AND (E.EnrollDate <= dbo.EndOfDayNT(@ReportEnd) AND ISNULL(E.ExitDate, '12/31/9999') >= @ReportStart)))