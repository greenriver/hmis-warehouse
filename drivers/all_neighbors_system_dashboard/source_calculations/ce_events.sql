SELECT TOP(@MaxRows)
    Service.[ClientID] AS [ClientID],

    Service.[ServiceID] AS [ServiceID],

    Service.[BeginDate] AS [EventDate],

    ReferralServiceCode.[Service] AS [Event],

    CEEvent.[Location] AS [LocationCrisisORPHHousing],

    qview_2000000305_DRTRRProjects.[ProgramName] AS [ProgramName],

    qview_2000000305_DRTRRProjects.[ProgramType] AS [ProgramType],

    CEEventResult.[ReferralResult] AS [ReferralResult],

    ServiceReferral.[ResultDate] AS [ResultDate],

    @Start_Date AS [ReportStartDate],

    @End_Date AS [ReportEndDate],

    GETDATE() AS [RunDate],

    Service.[EnrollID] AS [EnrollID]

FROM Service Service (nolock)
    INNER JOIN CEEvent CEEvent (nolock) ON Service.ServiceID=CEEvent.ServiceID AND CEEvent.ActiveStatus <> 'D'
    INNER JOIN ServiceReferral ServiceReferral (nolock) ON Service.ServiceID=ServiceReferral.ServiceID
    INNER JOIN ServiceCode ReferralServiceCode (nolock) ON ServiceReferral.ServiceCodeID=ReferralServiceCode.ServiceCodeID AND ReferralServiceCode.ActiveStatus <> 'D'
    LEFT JOIN CEEventResult CEEventResult (nolock) ON CEEvent.CEEventID=CEEventResult.CEEventID AND CEEventResult.ActiveStatus <> 'D'
    INNER JOIN qview_2000000305_DRTRRProjects qview_2000000305_DRTRRProjects (nolock) ON CEEvent.Location=qview_2000000305_DRTRRProjects.ProgramID
WHERE ([ServiceReferral].[ServiceCodeID] IN (433,435,436,437,438,439,440,441,443,444,445,446,447,968,974,975,976,1114)
  AND (Service.BeginDate <= dbo.EndOfDayNT(@End_Date)
  AND ([ServiceReferral].[ResultDate] >= @Start_Date
   OR ServiceReferral.ResultDate IS NULL)))
  AND (Service.ActiveStatus <> 'D')
