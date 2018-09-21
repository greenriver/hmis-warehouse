require_relative 'sql_server_base'
module LsaSqlServer
  class LSAReport

    def steps
      @steps ||= [
        :clear,
        :insert_projects,
        :four_three,
        :four_four,
        :four_five,
        :four_six,
        :four_seven,
        :four_eight,
        :four_nine,
        :four_ten,
        :four_eleven,
        :four_twelve,
        :four_thirteen,
        :four_fourteen,
        :four_fifteen,
        :four_sixteen,
        :four_seventeen,
        :four_eighteen,
        :four_nineteen,
        :four_twenty,
        :four_twenty_one,
        :four_twenty_two,
        :four_twenty_thee,
        :four_twenty_four_and_five,
        :four_twenty_six,
        :four_twenty_seven,
        :four_twenty_eight,
        :four_twenty_nine,
        :four_thirty,
        :four_thirty_one,
        :four_thirty_two,
        :four_thirty_three,
        :four_thirty_four,
        :four_thirty_five,
        :four_thirty_six,
        :four_thrity_seven,
        :four_thirty_eight,
        :four_thirty_nine,
        :four_forty,
        :four_forty_one,
        :four_forty_one_and_two,
        :four_forty_three,
        :four_forty_four,
        :four_forty_five,
        :four_forty_six,
        :four_forty_seven_to_fifty_one,
        :four_fifty_two,
        :four_fifty_three,
        :four_fifty_four,
        :four_fifty_five_and_six,
        :four_fifty_seven,
        :four_fifty_eight,
        :four_fifty_nine,
        :four_sixty,
        :four_sixty_one,
        :four_sixty_two,
        :four_sixty_three,
        :four_sixty_four,
        :four_sixty_five,
        :four_sixty_six,
        :four_sixty_seven,
        :four_sixty_eight,
        :four_sixty_nine,
        :four_seventy,
        :four_seventy_one,
        :four_seventy_two,
        :four_seventy_three,
      ]
    end

    def clear

      SqlServerBase.connection.execute (<<~SQL);
        delete from lsa_Inventory
        delete from lsa_Geography
        delete from lsa_Funder
        delete from lsa_Project
        delete from lsa_Organization
      SQL
    end

    def insert_projects
      SqlServerBase.connection.execute (<<~SQL);
        insert into lsa_Project
          (ProjectID, OrganizationID, ProjectName
           , OperatingStartDate, OperatingEndDate
           , ContinuumProject, ProjectType, TrackingMethod
           , TargetPopulation, VictimServicesProvider, HousingType
           , DateCreated, DateUpdated, ExportID)
        select distinct
          hp.ProjectID, hp.OrganizationID, left(hp.ProjectName, 50)
          , hp.OperatingStartDate, hp.OperatingEndDate
          , hp.ContinuumProject, hp.ProjectType, hp.TrackingMethod
          , hp.TargetPopulation, hp.VictimServicesProvider, hp.HousingType
          , hp.DateCreated, hp.DateUpdated, convert(varchar,rpt.ReportID)
        from hmis_Project hp
        inner join lsa_Report rpt on hp.OperatingStartDate <= rpt.ReportEnd
        inner join hmis_ProjectCoC coc on coc.CoCCode = rpt.ReportCoC
        where hp.ContinuumProject = 1
          --include only projects that were operating during the report period
          and (hp.OperatingEndDate is null or hp.OperatingEndDate >= rpt.ReportStart)
          and hp.ProjectType in (1,2,3,8,9,10,13)
      SQL
    end

    def four_three
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.3 Get Organization Records / lsa_Organization
        **********************************************************************/
        insert into lsa_Organization
          (OrganizationID, OrganizationName, DateCreated, DateUpdated, ExportID)
        select distinct ho.OrganizationID
              ,left(ho.OrganizationName, 50)
              ,ho.DateCreated, ho.DateUpdated, convert(varchar,rpt.ReportID)
        from hmis_Organization ho
        inner join lsa_Report rpt on rpt.ReportDate >= ho.DateUpdated
        --include only organizations associated with active projects
        inner join lsa_Project lp on lp.OrganizationID = ho.OrganizationID
        where ho.DateDeleted is null
      SQL
    end

    def four_four
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.4 Get Funder Records / lsa_Funder
        **********************************************************************/
        insert into lsa_Funder
          (FunderID, ProjectID, Funder, StartDate, EndDate, DateCreated, DateUpdated, ExportID)
        select distinct hf.FunderID, hf.ProjectID, hf.Funder, hf.StartDate, hf.EndDate
          , hf.DateCreated, hf.DateUpdated, convert(varchar, rpt.ReportID)
        from hmis_Funder hf
        inner join lsa_Report rpt on hf.StartDate <= rpt.ReportEnd
        inner join lsa_Project lp on lp.ProjectID = hf.ProjectID
        where hf.DateDeleted is null
          --get only funding sources active in the report period
          and (hf.EndDate is null or hf.EndDate >= rpt.ReportStart)
      SQL
    end

    def four_five
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.5 Get Inventory Records / lsa_Inventory
        **********************************************************************/
        insert into lsa_Inventory
          (InventoryID, ProjectID, CoCCode, InformationDate, HouseholdType
           , Availability, UnitInventory, BedInventory
           , CHBedInventory, VetBedInventory, YouthBedInventory, BedType
           , InventoryStartDate, InventoryEndDate, HMISParticipatingBeds
           , DateCreated, DateUpdated, ExportID)
        select distinct hi.InventoryID, hi.ProjectID, hi.CoCCode
          , hi.InformationDate, hi.HouseholdType
          , case when lp.ProjectType = 1 then hi.Availability else null end
          , hi.UnitInventory, hi.BedInventory
          , case when lp.ProjectType = 3 then hi.CHBedInventory else null end
          , hi.VetBedInventory, hi.YouthBedInventory
          , case when lp.ProjectType = 1 then hi.BedType else null end
          , hi.InventoryStartDate, hi.InventoryEndDate, hi.HMISParticipatingBeds
          , hi.DateCreated, hi.DateUpdated, convert(varchar, rpt.ReportID)
        from hmis_Inventory hi
        inner join lsa_Report rpt on hi.InventoryStartDate <= rpt.ReportEnd
          --get only inventory associated with the report CoC...
          and hi.CoCCode = rpt.ReportCoC
        inner join lsa_Project lp on lp.ProjectID = hi.ProjectID
        where hi.DateDeleted is null and
          --...and active during the report period
          (hi.InventoryEndDate is null or hi.InventoryEndDate >= rpt.ReportStart)
      SQL
    end

    def four_six
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.6 Get Geography Records / lsa_Geography
        **********************************************************************/
        insert into lsa_Geography
          (GeographyID, ProjectID, CoCCode, InformationDate
          , Geocode, GeographyType
          , Address1, Address2, City, State, ZIP
          , DateCreated, DateUpdated, ExportID)
        select distinct hg.GeographyID, hg.ProjectID, hg.CoCCode, hg.InformationDate
          , hg.Geocode, hg.GeographyType
          , hg.Address1, hg.Address2, hg.City, hg.State, hg.ZIP
          , hg.DateCreated, hg.DateUpdated, convert(varchar, rpt.ReportID)
        from hmis_Geography hg
        --limit to records that are associated with the report CoC...
        inner join lsa_Report rpt on hg.InformationDate <= rpt.ReportEnd and hg.CoCCode = rpt.ReportCoC
        inner join lsa_Project lp on lp.ProjectID = hg.ProjectID
        left outer join hmis_Geography later on later.ProjectID = hg.ProjectID
          and later.DateDeleted is null
          and (later.InformationDate > hg.InformationDate
            or (later.InformationDate = hg.InformationDate
              and later.DateUpdated > hg.DateUpdated))
        where hg.DateDeleted is null and
          --and only the most recent record for each project dated before ReportEnd
          later.GeographyID is null
      SQL
    end

    def four_seven
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.7 Get Active Household IDs
        **********************************************************************/
        delete from active_Household

        insert into active_Household (HouseholdID, HoHID, MoveInDate
          , ProjectID, ProjectType, TrackingMethod)
        select distinct hn.HouseholdID
          --CHANGE 9/17/2018 - remove 'WHERE RelationshipToHoH = 1' from
          --2nd COALESCE parameter.  COALESCE is used to ensure that all HHIDs
          --have an identified HoH, even in systems that do not enforce the
          --requirement
          , coalesce ((select min(PersonalID)
              from hmis_Enrollment
              where HouseholdID = hn.HouseholdID and RelationshipToHoH = 1)
            , (select min(PersonalID)
              from hmis_Enrollment
              where HouseholdID = hn.HouseholdID))
          , case when p.ProjectType in (3,13) then
              (select min(MoveInDate)
              from hmis_Enrollment
              where HouseholdID = hn.HouseholdID) else null end
          , p.ProjectID, p.ProjectType, p.TrackingMethod
        from lsa_Report rpt
        inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
        inner join lsa_Project p on p.ProjectID = hn.ProjectID
        left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID
          and x.ExitDate <= rpt.ReportEnd
        left outer join hmis_Services bn on bn.EnrollmentID = hn.EnrollmentID
          and bn.DateProvided between rpt.ReportStart and rpt.ReportEnd
          and bn.RecordType = 200
        -- CHANGE 9/17/2018: was x.ExitDate > rpt.ReportStart
        -- corrected to x.ExitDate >= rpt.ReportStart
        where ((x.ExitDate >= rpt.ReportStart and x.ExitDate > hn.EntryDate)
            or x.ExitDate is null)
          and p.ProjectType in (1,2,3,8,13)
          and p.ContinuumProject = 1
          and ((p.TrackingMethod is null or p.TrackingMethod <> 3) or bn.DateProvided is not null)
          and (select top 1 coc.CoCCode
            from hmis_EnrollmentCoC coc
            where coc.EnrollmentID = hn.EnrollmentID
              and coc.InformationDate <= rpt.ReportEnd
            order by coc.InformationDate desc) = rpt.ReportCoC
      SQL
    end
    def four_eight
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.8 Get Active Enrollments and Associated AgeDates
        **********************************************************************/
        delete from active_Enrollment

        insert into active_Enrollment
          (EnrollmentID, PersonalID, HouseholdID
          , RelationshipToHoH, AgeDate
          , EntryDate, MoveInDate, ExitDate
          , ProjectID, ProjectType, TrackingMethod)
        select distinct hn.EnrollmentID, hn.PersonalID, hn.HouseholdID
          , case when hn.PersonalID = hhid.HoHID then 1
            when hn.RelationshipToHoH = 1 and hn.PersonalID <> hhid.HoHID then 99
            when hn.RelationshipToHoH not in (1,2,3,4,5) then 99
            else hn.RelationshipToHoH end
          , case when hn.EntryDate >= rpt.ReportStart then hn.EntryDate
            else rpt.ReportStart end
          , hn.EntryDate
          , hhid.MoveInDate
          , x.ExitDate
          , hhid.ProjectID, hhid.ProjectType, hhid.TrackingMethod
        from lsa_Report rpt
        inner join hmis_Enrollment hn on hn.EntryDate <= rpt.ReportEnd
        inner join active_Household hhid on hhid.HouseholdID = hn.HouseholdID
        left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID
          and x.ExitDate <= rpt.ReportEnd
        where ((x.ExitDate > rpt.ReportStart and x.ExitDate > hn.EntryDate)
            or x.ExitDate is null)

      SQL
    end

    def four_nine
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.9 Set Age Group for Each Active Enrollment
        **********************************************************************/
        update n
        set n.AgeGroup = case
          when c.DOBDataQuality in (8,9) then 98
          when c.DOB is null
            --NOTE 9/4/2018 - if database default date value is not 1/1/1900,
            --use database default
            or c.DOB = '1/1/1900'
            or c.DOB > n.EntryDate
            or (n.RelationshipToHoH = 1 and c.DOB = n.EntryDate)
            or DATEADD(yy, 105, c.DOB) <= n.AgeDate
            or c.DOBDataQuality is null
            or c.DOBDataQuality not in (1,2) then 99
          when DATEADD(yy, 65, c.DOB) <= n.AgeDate then 65
          when DATEADD(yy, 55, c.DOB) <= n.AgeDate then 64
          when DATEADD(yy, 45, c.DOB) <= n.AgeDate then 54
          when DATEADD(yy, 35, c.DOB) <= n.AgeDate then 44
          when DATEADD(yy, 25, c.DOB) <= n.AgeDate then 34
          when DATEADD(yy, 22, c.DOB) <= n.AgeDate then 24
          when DATEADD(yy, 18, c.DOB) <= n.AgeDate then 21
          when DATEADD(yy, 6, c.DOB) <= n.AgeDate then 17
          when DATEADD(yy, 3, c.DOB) <= n.AgeDate then 5
          when DATEADD(yy, 1, c.DOB) <= n.AgeDate then 2
          else 0 end
        from active_Enrollment n
        inner join hmis_Client c on c.PersonalID = n.PersonalID

      SQL
    end

    def four_ten
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.10 Set HHType for Active HouseholdIDs
        **********************************************************************/
        update hhid
        set hhid.HHAdult = (select count(distinct an.PersonalID)
            from active_Enrollment an
            where an.HouseholdID = hhid.HouseholdID
              and an.AgeGroup between 18 and 65)
          , HHChild  = (select count(distinct an.PersonalID)
            from active_Enrollment an
            where an.HouseholdID = hhid.HouseholdID
              and an.AgeGroup < 18)
          , HHNoDOB  = (select count(distinct an.PersonalID)
            from active_Enrollment an
            where an.HouseholdID = hhid.HouseholdID
              and an.AgeGroup in (98,99))
        from active_Household hhid

        update hhid
        set hhid.HHType = case
          when HHAdult > 0 and HHChild > 0 then 2
          when HHNoDOB > 0 then 99
          when HHAdult > 0 then 1
          else 3 end
        from active_Household hhid

        update an
        set an.HHType = hhid.HHType
        from active_Enrollment an
        inner join active_Household hhid on hhid.HouseholdID = an.HouseholdID
      SQL
    end

    def four_eleven
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.11 Get Active Clients for tmp_Person
        **********************************************************************/
        delete from tmp_Person

        insert into tmp_Person (PersonalID, HoHAdult, Age, LastActive, ReportID)
        select distinct an.PersonalID
          --Ever served as an adult = 1...
          , max(case when an.AgeGroup between 18 and 65 then 1
            else 0 end)
          --Plus ever served-as-HoH = 2
            + max(case when hhid.HoHID is null then 0
            else 2 end)
          --Equals:  0=Not HoH or Adult, 1=Adult, 2=HoH, 3=Both
          , min(an.AgeGroup)
          --LastActive date in report period is used for CH
          , max(case when an.ExitDate is null then rpt.ReportEnd else an.ExitDate end)
          , rpt.ReportID
        from lsa_Report rpt
        inner join active_Enrollment an on an.EntryDate <= rpt.ReportEnd
        left outer join active_Household hhid on hhid.HoHID = an.PersonalID
        group by an.PersonalID, rpt.ReportID
      SQL
    end

    def four_twelve
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.12 Set Demographic Values in tmp_Person
        **********************************************************************/
        update lp
        set
          lp.Gender = case
            when lp.HoHAdult = 0 then -1
            when c.Gender in (8,9) then 98
            when c.Gender in (0,1,2) then c.Gender + 1
            when c.Gender in (3,4) then c.Gender
            else 99 end
          , lp.Ethnicity = case
            when lp.HoHAdult = 0 then -1
            when c.Ethnicity in (8,9) then 98
            when c.Ethnicity in (0,1) then c.Ethnicity
            else 99 end
          , lp.Race = case
            when lp.HoHAdult = 0 then -1
            when c.RaceNone in (8,9) then 98
            when c.AmIndAkNative + Asian + BlackAfAmerican +
              NativeHIOtherPacific + White > 1 then 6
            when White = 1 and c.Ethnicity = 1 then 1
            when White = 1 then 0
            when BlackAfAmerican = 1 then 2
            when Asian = 1 then 3
            when c.AmIndAkNative = 1 then 4
            when NativeHIOtherPacific = 1 then 5
            else 99 end
          , lp.VetStatus = case
            when lp.HoHAdult in (0, 2) then -1
            when c.VeteranStatus in (8,9) then 98
            when c.VeteranStatus in (0,1) then c.VeteranStatus
            else 99 end
          --To make it possible to select the minimum value
          --from all associated Disability and DVStatus records --
          --i.e., select according to priority order -- 0 is
          --selected as 97 in the subquery and reset to 0 here.
          , lp.DisabilityStatus = case
          --CHANGE 9/17/2018 - DisabilityStatus = -1 for non-HoH not identified as an adult
            when lp.HoHAdult = 0 then -1
            when dis.dis = 97 then 0
            else dis.dis end
          , lp.DVStatus = case
          --CHANGE 9/17/2018 - DVStatus = -1 for non-HoH not identified as an adult
            when lp.HoHAdult = 0 then -1
            when dv.DV = 97 then 0
            when dv.DV is null then 99
            else dv.dv end
        from tmp_Person lp
        inner join hmis_Client c on c.PersonalID = lp.PersonalID
        inner join (select alldis.PersonalID, min(alldis.dis) as dis
                from (select distinct hn.PersonalID
                  , case
                    when hn.DisablingCondition = 1 then 1
                    when hn.DisablingCondition = 0 then 97
                    --CHANGE 9/17/2018 delete case when DisablingCondition in (8,9)
                    --because DisablingCondition doesn't include a separate category
                    --for those values
                    else 99 end as dis
                  from hmis_Enrollment hn
                  inner join active_Enrollment ln
                    on ln.EnrollmentID = hn.EnrollmentID
                  ) alldis
                group by alldis.PersonalID
                ) dis on dis.PersonalID = lp.PersonalID
        left outer join (select alldv.PersonalID, min(alldv.DV) as DV
                from
                  (select distinct hdv.PersonalID, case
                    when hdv.DomesticViolenceVictim = 1
                      and hdv.CurrentlyFleeing = 1 then 1
                    when hdv.DomesticViolenceVictim = 1
                      and hdv.CurrentlyFleeing = 0 then 2
                    when hdv.DomesticViolenceVictim = 1
                      and (hdv.CurrentlyFleeing is null or
                      hdv.CurrentlyFleeing not in (0,1)) then 3
                    when hdv.DomesticViolenceVictim = 0 then 97
                    when hdv.DomesticViolenceVictim in (8,9) then 98
                    else 99 end as DV
                    from hmis_HealthAndDV hdv
                    inner join active_Enrollment ln on
                      ln.EnrollmentID = hdv.EnrollmentID
                  ) alldv
                group by alldv.PersonalID) dv on dv.PersonalID = lp.PersonalID

      SQL
    end

    def four_thirteen
      SqlServerBase.connection.execute (<<~SQL);
      /*************************************************************************
      4.13 Get Chronic Homelessness Date Range for Each Head of Household/Adult
      **********************************************************************/
      --The three year period ending on a HoH/adult's last active date in the report
      --period is relevant for determining chronic homelessness.
      --The start of the period is:
      --  LastActive minus (3 years) plus (1 day)
      update lp
      set lp.CHStart = dateadd(dd, 1, (dateadd(yyyy, -3, lp.LastActive)))
      from tmp_Person lp
      where HoHAdult > 0

      SQL
    end

    def four_fourteen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.14 Get Enrollments Relevant to Chronic Homelessness
        **********************************************************************/
        delete from ch_Enrollment

        --NOTE 9/4/2018 regarding code methodology compared to specs document:
        --Enrollments in night-by-night shelters without bed night dates between CHStart
        --and LastActive are not relevant to CH.
        --In this step, ALL enrollments with entry/exit dates that overlap the CH date range
        --are inserted into ch_Enrollment, but StartDate and StopDate are set to NULL when
        --TrackingMethod = 3.
        --In section 4.16, only dates with records of a bednight are included in ch_Time when
        --StartDate and StopDate are NULL, which effectively excludes any enrollment in a
        --night-by-night shelter without bednights.
        --This approach produces the same result without requiring a join to hmis_Services
        --in both steps.

        insert into ch_Enrollment(PersonalID, EnrollmentID, ProjectType
          , StartDate, MoveInDate, StopDate)
        select distinct lp.PersonalID, hn.EnrollmentID, p.ProjectType
          , case
            when p.TrackingMethod = 3 then null
            when hn.EntryDate < lp.CHStart then lp.CHStart
            else hn.EntryDate end
          , case when p.ProjectType in (3,13) and hoh.MoveInDate >= hn.EntryDate
            and hoh.MoveInDate < coalesce(x.ExitDate, lp.LastActive)
            then hoh.MoveInDate else null end
          , case
            when p.TrackingMethod = 3 then null
            when x.ExitDate is null then lp.LastActive
            else x.ExitDate end
        from tmp_Person lp
        inner join lsa_Report rpt on rpt.ReportID = lp.ReportID
        inner join hmis_Enrollment hn on hn.PersonalID = lp.PersonalID
          and hn.EntryDate <= lp.LastActive
        left outer join hmis_Exit x on x.EnrollmentID = hn.EnrollmentID
          and x.ExitDate <= lp.LastActive
        inner join (select hhinfo.HouseholdID, min(hhinfo.MoveInDate) as MoveInDate
              , coc.CoCCode
            from hmis_Enrollment hhinfo
            inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
            group by hhinfo.HouseholdID, coc.CoCCode
          ) hoh on hoh.HouseholdID = hn.HouseholdID and hoh.CoCCode = rpt.ReportCoC
        inner join hmis_Project p on p.ProjectID = hn.ProjectID
          and p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
        where lp.HoHAdult > 0
          and (x.ExitDate is null or x.ExitDate > lp.CHStart)

      SQL
    end

    def four_fifteen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.15 Get Dates to Exclude from Counts of ES/SH/Street Days
        **********************************************************************/
        delete from ch_Exclude

        insert into ch_Exclude (PersonalID, excludeDate)
        select distinct lp.PersonalID, cal.theDate
        from tmp_Person lp
        inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
        inner join ref_Calendar cal on cal.theDate >=
            case when chn.ProjectType in (3,13) then chn.MoveInDate
            else chn.StartDate end
          and cal.theDate < chn.StopDate
        where chn.ProjectType in (2,3,13)
      SQL
    end

    def four_sixteen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.16 Get Dates to Include in Counts of ES/SH/Street Days
        **********************************************************************/
        delete from ch_Time

        --Dates enrolled in ES entry/exit or SH are counted if the
        --client was not housed in RRH/PSH or enrolled in TH at the time.
        insert into ch_Time (PersonalID, chDate)
        select distinct lp.PersonalID, cal.theDate
        from tmp_Person lp
        inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
        left outer join hmis_Services bn on bn.EnrollmentID = chn.EnrollmentID
          and bn.RecordType = 200
          and bn.DateProvided between lp.CHStart and lp.LastActive
        inner join ref_Calendar cal on
          cal.theDate >= coalesce(chn.StartDate, bn.DateProvided)
          and cal.theDate < coalesce(chn.StopDate, dateadd(dd,1,bn.DateProvided))
        left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
          and chx.PersonalID = chn.PersonalID
        where chn.ProjectType in (1,8) and chx.excludeDate is null

        --ESSHStreet dates from 3.917 collected for an EntryDate > CHStart
        -- are counted if client was not housed in RRH/PSH or in TH at the time.
        --For RRH/PSH, LivingSituation is assumed to extend to MoveInDate
        --or ExitDate (if there is no MoveInDate) and that time is also counted.
        insert into ch_Time (PersonalID, chDate)
        select distinct lp.PersonalID, cal.theDate
        from tmp_Person lp
        inner join ch_Enrollment chn on chn.PersonalID = lp.PersonalID
        --CHANGE 9/6/2018 – EntryDate must be > lp.CHStart and not
        --[lp.LastActive – 1 year]
        inner join hmis_Enrollment hn on hn.EnrollmentID = chn.EnrollmentID
          and hn.EntryDate > lp.CHStart
        inner join ref_Calendar cal on cal.theDate >= hn.DateToStreetESSH
          and cal.theDate < coalesce(chn.MoveInDate, chn.StopDate)
        left outer join ch_Exclude chx on chx.excludeDate = cal.theDate
          and chx.PersonalID = chn.PersonalID
        left outer join ch_Time cht on cht.chDate = cal.theDate
          and cht.PersonalID = chn.PersonalID
        where chx.excludeDate is null
          and cht.chDate is null
          and (chn.ProjectType in (1,8)
          --CHANGE 7/9/2018 omit hn.LivingSituation 27 (was 1,18,16,27)
            or hn.LivingSituation in (1,18,16)
            or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11))
            or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
              and hn.LivingSituation in (4,5,6,7,15,24) )
            )

        --Gaps of less than 7 nights between two ESSHStreet dates are counted
        insert into ch_Time (PersonalID, chDate)
        select gap.PersonalID, cal.theDate
        from (select distinct s.PersonalID, s.chDate as StartDate, min(e.chDate) as EndDate
          from ch_Time s
          inner join ch_Time e on e.PersonalID = s.PersonalID and e.chDate > s.chDate
            and dateadd(dd, -7, e.chDate) <= s.chDate
          where s.PersonalID not in
            (select PersonalID
            from ch_Time
            where chDate = dateadd(dd, 1, s.chDate))
          group by s.PersonalID, s.chDate) gap
        inner join ref_Calendar cal on cal.theDate between gap.StartDate and gap.EndDate
        left outer join ch_Time cht on cht.PersonalID = gap.PersonalID
          and cht.chDate = cal.theDate
        where cht.chDate is null

      SQL
    end

    def four_seventeen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.17 Get ES/SH/Street Episodes
        **********************************************************************/
        delete from ch_Episodes

        insert into ch_Episodes (PersonalID, episodeStart, episodeEnd)
        select distinct s.PersonalID, s.chDate, min(e.chDate)
        from ch_Time s
        inner join ch_Time e on e.PersonalID = s.PersonalID  and e.chDate > s.chDate
        where s.PersonalID not in (select PersonalID from ch_Time where chDate = dateadd(dd, -1, s.chDate))
          and e.PersonalID not in (select PersonalID from ch_Time where chDate = dateadd(dd, 1, e.chDate))
        group by s.PersonalID, s.chDate

        update chep
        set episodeDays = datediff(dd, chep.episodeStart, chep.episodeEnd) + 1
        from ch_Episodes chep

      SQL
    end

    def four_eighteen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.18 Set Initial CHTime and CHTimeStatus Values
        **********************************************************************/

        update tmp_Person set CHTime = null, CHTimeStatus = null

        update lp
        set CHTime = -1, CHTimeStatus = -1
        from tmp_Person lp
        where HoHAdult = 0

        --Any client with a 365+ day episode that overlaps with their
        --last year of activity
        --will be reported as CH by the HDX (if DisabilityStatus = 1)
        update lp
        set CHTime = 365, CHTimeStatus = 1
        from tmp_Person lp
        inner join ch_Episodes chep on chep.PersonalID = lp.PersonalID
          and chep.episodeDays >= 365
          and chep.episodeEnd between dateadd(dd, -364, lp.LastActive) and lp.LastActive
        where HoHAdult > 0

        --Episodes of 365+ days prior to the client's last year of activity must
        --be part of a series of at least four episodes in order to
        --meet time criteria for CH
        update lp
        set CHTime = case
            when ep.episodeDays >= 365 then 365
            when ep.episodeDays between 270 and 364 then 270
            else 0 end
          , CHTimeStatus = case
            when ep.episodes >= 4 then 2
            else 3 end
        from tmp_Person lp
        inner join (select chep.PersonalID
          , sum(chep.episodeDays) as episodeDays, count(distinct chep.episodeStart) as episodes
          from ch_Episodes chep
          group by chep.PersonalID) ep on ep.PersonalID = lp.PersonalID
        where HoHAdult > 0 and CHTime is null
      SQL
    end

    def four_nineteen
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.19 Update Selected CHTime and CHTimeStatus Values
        **********************************************************************/
        --Anyone not CH based on system use data + 3.917 date ranges
        --will be counted as chronically homeless if an *active* enrollment shows
        --12 or more ESSHSTreet months and 4 or more times homeless
        --(and DisabilityStatus = 1)
        update lp
        set CHTime = 400
          --CHANGE 9/6/2018 - CHTimeStatus = 2 when CHTime = 400
          , CHTimeStatus = 2
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
        inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
          and hn.MonthsHomelessPastThreeYears in (112,113)
          and hn.TimesHomelessPastThreeYears = 4
          --CHANGE 9/6/2018 - per specs, limit to 3.917 data collected in
          --the year ending on LastActive
          and hn.EntryDate >= dateadd(dd, -364, lp.LastActive)
        where --CHANGE 9/6/2018 - add parentheses to WHERE clause
          (HoHAdult > 0 and CHTime is null) or CHTime <> 365 or chTimeStatus = 3

        --Anyone who doesn't meet CH time criteria and is missing data in 3.917
        --for an active enrollment should be identified as missing data.
        update lp
        set CHTime = coalesce(lp.CHTime, 0)
          , CHTimeStatus = 99
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
        inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
          --CHANGE 9/6/2018 – updated join criteria below to correct
          --inconsistencies with the specifications
          and ((hn.DateToStreetESSH > hn.EntryDate)
            or (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null)
            or (hn.LengthOfStay in (8,9,99) or hn.LengthOfStay is null)
            or (an.ProjectType in (1,8) and (hn.DateToStreetESSH is null))
            or (hn.MonthsHomelessPastThreeYears in (8,9,99))
            or (hn.MonthsHomelessPastThreeYears is null)
            or (hn.TimesHomelessPastThreeYears in (8,9,99))
            or (hn.TimesHomelessPastThreeYears is null)
            or (hn.LivingSituation in (1,16,18) and hn.DateToStreetESSH is null)
            or (hn.LengthOfStay in (10,11) and ((hn.PreviousStreetESSH is null)
                or (hn.PreviousStreetESSH = 1 and hn.DateToStreetESSH is null)))
            or (hn.LivingSituation in (4,5,6,7,15,24)
                and hn.LengthOfStay in (2,3)
                and ((hn.PreviousStreetESSH is NULL)
                  or (hn.PreviousStreetESSH = 1
                    and hn.DateToStreetESSH is null))))
        where CHTime <> 400
          and CHTimeStatus not in (1,2)
          and HoHAdult > 0

        update tmp_Person
        set CHTime = 0, CHTimeStatus = -1
        where HoHAdult > 0 and CHTime is null

      SQL
    end

    def four_twenty
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.20 Set tmp_Person Project Group / Household Type Identifiers
        **********************************************************************/
        update tmp_Person
        set HHTypeEST = null, HHTypeRRH = null, HHTypePSH = null

        --set EST HHType
        update lp
        set lp.HHTypeEST =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for EST
                 (select distinct an.PersonalID
                  , case when an.HHType = 1 then 100
                    when an.HHType = 2 then 20
                    when an.HHType = 3 then 3
                    else 0 end as HHTypeEach
                  from active_Enrollment an
                  where an.ProjectType in (1,2,8)) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID

        --set RRH HHType
        update lp
        set lp.HHTypeRRH =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach
              ) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for RRH
                 (select distinct an.PersonalID
                  , case when an.HHType = 1 then 100
                    when an.HHType = 2 then 20
                    when an.HHType = 3 then 3
                    else 0 end as HHTypeEach
                  from active_Enrollment an
                  where an.ProjectType = 13) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID

        --set PSH HHType
        update lp
        set lp.HHTypePSH =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for PSH
                 (select distinct an.PersonalID
                  , case when an.HHType = 1 then 100
                    when an.HHType = 2 then 20
                    when an.HHType = 3 then 3
                    else 0 end as HHTypeEach
                  from active_Enrollment an
                  where an.ProjectType = 3) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID

      SQL
    end

    def four_twenty_one
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.21 Set tmp_Person Head of Household Identifiers for Each Project Group
        **********************************************************************/
        update tmp_Person
        set HoHEST = null, HoHRRH = null, HoHPSH = null

        --set EST HHType
        update lp
        set lp.HoHEST =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for EST
              (select distinct an.PersonalID
              , case when an.HHType = 1 then 100
                when an.HHType = 2 then 20
                when an.HHType = 3 then 3
                else 0 end as HHTypeEach
              from active_Enrollment an
              inner join active_Household hhid on hhid.HoHID = an.PersonalID
              where an.ProjectType in (1,2,8)) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID

        --set RRH HHType
        update lp
        set lp.HoHRRH =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach
              ) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for RRH
              (select distinct an.PersonalID
              , case when an.HHType = 1 then 100
                when an.HHType = 2 then 20
                when an.HHType = 3 then 3
                else 0 end as HHTypeEach
              from active_Enrollment an
              inner join active_Household hhid on hhid.HoHID = an.PersonalID
              where an.ProjectType = 13) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID

        --set PSH HHType
        update lp
        set lp.HoHPSH =
          case when hh.HHTypeCombined is null then -1
          else hh.HHTypeCombined end
        from tmp_Person lp
        left outer join --Level 2 – combine HHTypes into a single value
           (select HHTypes.PersonalID, case sum(HHTypes.HHTypeEach)
              when 100 then 1
              when 120 then 12
              when 103 then 13
              when 20 then 2
              when 0 then 99
              else sum(HHTypes.HHTypeEach) end as HHTypeCombined
            from --Level 1 – get distinct HHTypes for PSH
              (select distinct an.PersonalID
              , case when an.HHType = 1 then 100
                when an.HHType = 2 then 20
                when an.HHType = 3 then 3
                else 0 end as HHTypeEach
              from active_Enrollment an
              inner join active_Household hhid on hhid.HoHID = an.PersonalID
              where an.ProjectType = 3) HHTypes
            group by HHTypes.PersonalID
            ) hh on hh.PersonalID = lp.PersonalID


      SQL
    end

    def four_twenty_two
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.22 Set Population Identifiers for Active HouseholdIDs
        **********************************************************************/
        --CHANGE 9/17/2018 - In response to vendor questions and to better illustrate
        --the business logic / reduce confusion:
        ---- This code has been restructured with a single separate sub-query for each
        ---- population identifier to better illustrate the business logic.
        ---- Also, filters for HHType -- which were previously only applied in 4.24 and 4.25
        ---- have been added here.
        --The following bug fixes are also included:
        --  HHChronic - records where CHTime = 400 and CHTimeStatus = 2 were
        --    previously omitted from consideration for CH status
        --  HHAdultAge for some records was being set to 0, which is not valid.
        --    Logic for age categories has also been corrected consistent with
        --    corresponding update to v1.2 of the specs document.
        --  HHParent population includes only HHs with at least 1 child of HoH
        --    who is under 18 (age filter previously omitted)

        update ahh
        set ahh.HHChronic = (select max(
                case when (n.AgeGroup not between 18 and 65
                  and n.PersonalID <> hh.HoHID)
                  or lp.DisabilityStatus <> 1
                  or hh.HHType not in (1,2,3) then 0
                when (lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
                  or (lp.CHTime = 400 and lp.CHTimeStatus = 2) then 1
                else 0 end)
            from tmp_Person lp
            inner join active_Enrollment n on n.PersonalID = lp.PersonalID
            inner join active_Household hh on hh.HouseholdID = n.HouseholdID
            where n.HouseholdID = ahh.HouseholdID)
          , ahh.HHVet = (select max(
                case when lp.VetStatus = 1
                  and n.AgeGroup between 18 and 65
                  and hh.HHType in (1,2) then 1
                else 0 end)
            from tmp_Person lp
            inner join active_Enrollment n on n.PersonalID = lp.PersonalID
            inner join active_Household hh on hh.HouseholdID = n.HouseholdID
            where n.HouseholdID = ahh.HouseholdID)
          , ahh.HHDisability = (select max(
              case when lp.DisabilityStatus = 1
                and (n.AgeGroup between 18 and 65
                  or n.PersonalID = hh.HoHID)
                and hh.HHType in (1,2,3) then 1
              else 0 end)
            from tmp_Person lp
            inner join active_Enrollment n on n.PersonalID = lp.PersonalID
            inner join active_Household hh on hh.HouseholdID = n.HouseholdID
            where n.HouseholdID = ahh.HouseholdID)
          , ahh.HHFleeingDV = (select max(
              case when lp.DVStatus = 1
                and (n.AgeGroup between 18 and 65
                  or n.PersonalID = hh.HoHID)
                and hh.HHType in (1,2,3) then 1
              else 0 end)
            from tmp_Person lp
            inner join active_Enrollment n on n.PersonalID = lp.PersonalID
            inner join active_Household hh on hh.HouseholdID = n.HouseholdID
            where n.HouseholdID = ahh.HouseholdID)
          , ahh.HHAdultAge = coalesce((select
              --HHTypes 3 and 99 are excluded by the CASE statement
              case when max(n.AgeGroup) >= 98 then -1
                when max(n.AgeGroup) <= 17 then -1
                when max(n.AgeGroup) = 21 then 18
                when max(n.AgeGroup) = 24 then 24
                when min(n.AgeGroup) between 64 and 65 then 55
                else 25 end
            from active_Enrollment n
            where n.HouseholdID = ahh.HouseholdID), -1)
          , ahh.HHParent = (select max(
              case when n.RelationshipToHoH = 2
                and n.AgeGroup <= 17
                and hh.HHType in (2,3) then 1
                else 0 end)
            from active_Enrollment n
            inner join active_Household hh on hh.HouseholdID = n.HouseholdID
            where n.HouseholdID = ahh.HouseholdID)
          , ahh.AC3Plus = (select case sum(case when n.AgeGroup <= 17 and hh.HHType = 2 then 1
                      else 0 end)
                    when 0 then 0
                    when 1 then 0
                    when 2 then 0
                    else 1 end
              from active_Enrollment n
              inner join active_Household hh on hh.HouseholdID = n.HouseholdID
              where n.HouseholdID = ahh.HouseholdID)
        from active_Household ahh
      SQL
    end

    def four_twenty_three
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.23 Set tmp_Person Population Identifiers from Active Households
        **********************************************************************/
        update lp
        --CHANGE 9/17/2018
        --  HHAdultAge moved from subquery to main and value selection corrected
        set lp.HHAdultAge = coalesce ((select case
                when min(hhid.HHAdultAge) in (18,24)
                  then min(hhid.HHAdultAge)
                when max(hhid.HHAdultAge) = 55 then 55
                else 25 end
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where hhid.HHAdultAge between 18 and 55
                and n.PersonalID = lp.PersonalID), -1)
        --CHANGE 9/17/2018
        --  AC3Plus moved from subquery to main (no HHType required)
           , lp.AC3Plus = (select max(hhid.AC3Plus)
            from active_Household hhid
            inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
            where n.PersonalID = lp.PersonalID)
        --CHANGE 9/17/2018
        --  HHVet, HHDisability, HHFleeingDV and HHParent should be set to -1 (not 0)
        --  for people not served in those populations
           , lp.HHChronic = case popHHTypes.HHChronic
            when '0' then -1
            else convert(int,replace(popHHTypes.HHChronic, '0', '')) end
           , lp.HHVet = case popHHTypes.HHVet
            when '0' then -1
            else convert(int,replace(popHHTypes.HHVet, '0', '')) end
           , lp.HHDisability = case popHHTypes.HHDisability
            when '0' then -1
            else convert(int,replace(popHHTypes.HHDisability, '0', '')) end
           , lp.HHFleeingDV = case popHHTypes.HHFleeingDV
            when '0' then -1
            else convert(int,replace(popHHTypes.HHFleeingDV, '0', '')) end
           , lp.HHParent = case popHHTypes.HHParent
            when '0' then -1
            else convert(int,replace(popHHTypes.HHParent, '0', '')) end
        from tmp_Person lp
        inner join (select distinct lp.PersonalID
            , HHChronic = (select convert(varchar(3),sum(distinct
                case when hhid.HHChronic = 0 then 0
                  when hhid.HHType = 1 then 100
                  when hhid.HHType = 2 then 20
                  when hhid.HHType = 3 then 3
                  else 0 end))
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where n.PersonalID = lp.PersonalID)
            , HHVet = (select convert(varchar(3),sum(distinct
                case when hhid.HHVet = 0 then 0
                  when hhid.HHType = 1 then 100
                  when hhid.HHType = 2 then 20
                  else 0 end))
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where n.PersonalID = lp.PersonalID)
            , HHDisability = (select convert(varchar(3),sum(distinct
                case when hhid.HHDisability = 0 then 0
                  when hhid.HHType = 1 then 100
                  when hhid.HHType = 2 then 20
                  when hhid.HHType = 3 then 3
                  else 0 end))
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where n.PersonalID = lp.PersonalID)
            , HHFleeingDV = (select convert(varchar(3),sum(distinct
                case when hhid.HHFleeingDV = 0 then 0
                  when hhid.HHType = 1 then 100
                  when hhid.HHType = 2 and hhid.HHAdultAge in (18,24) then 20
                  when hhid.HHType = 3 then 3
                  else 0 end))
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where n.PersonalID = lp.PersonalID)
            , HHParent = (select convert(varchar(3),sum(distinct
                case when hhid.HHParent = 0 then 0
                  when hhid.HHType = 2 then 20
                  when hhid.HHType = 3 then 3
                  else 0 end))
              from active_Household hhid
              inner join active_Enrollment n on hhid.HouseholdID = n.HouseholdID
              where n.PersonalID = lp.PersonalID)
            from tmp_Person lp
        ) popHHTypes on popHHTypes.PersonalID = lp.PersonalID

      SQL
    end

    def four_twenty_four_and_five
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.24-25 Get Unique Households and Population Identifiers for tmp_Household
        **********************************************************************/
        delete from tmp_Household

        --  CHANGE 7/9/2018
        --  Remove HHChild, HHAdult, HHNoDOB, and HHAdultAge from insert statement
        --  -- now in separate update statements below.
        insert into tmp_Household (HoHID, HHType
          , HHChronic, HHVet, HHDisability, HHFleeingDV
          , HoHRace, HoHEthnicity
          , HHParent, ReportID, FirstEntry, LastActive)
        select distinct hhid.HoHID, hhid.HHType
          , max(hhid.HHChronic)
          , max(hhid.HHVet)
          , max(hhid.HHDisability)
          , max(hhid.HHFleeingDV)
          , lp.Race, lp.Ethnicity
          , max(case when hhid.HHParent <> 1 then 0
              when hhid.HHType = 2 and hhid.HHAdultAge not in (18,24) then 0
              else hhid.HHParent end)
          , lp.ReportID
          , min(an.EntryDate)
          , max(coalesce(an.ExitDate, rpt.ReportEnd))
        from active_Household hhid
        inner join active_Enrollment an on an.HouseholdID = hhid.HouseholdID
          and an.PersonalID = hhid.HoHID
        inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
        inner join tmp_Person lp on lp.PersonalID = hhid.HoHID
        group by hhid.HoHID, hhid.HHType, lp.Race, lp.Ethnicity
          , lp.ReportID

        --   CHANGE 7/9/2018
        --   Split out counts for HHChild, HHAdult, and HHNoDOB from insert statement
        --   above to correct bug which created separate records in tmp_Household
        --   for unique HoHID/HHType if counts varied from enrollment to enrollment.
        --   CHANGE 9/6/2018 set value to 3 for any count greater than 3
        update hh
        set HHChild = (select case when count(distinct n.PersonalID) >= 3 then 3
                else count(distinct n.PersonalID) end
              from active_Household hhid
              inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
              where n.AgeGroup < 18
              and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID)
          , HHAdult = (select case when count(distinct n.PersonalID) >= 3 then 3
                else count(distinct n.PersonalID) end
              from active_Household hhid
              inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
              where n.AgeGroup between 18 and 65
                and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID
                and n.PersonalID not in
                  (select n17.PersonalID
                   from active_Household hh17
                   --CHANGE 9/14/2018 correct join criteria (was n.HouseholdID and not n17)
                   inner join active_Enrollment n17 on n17.HouseholdID = hhid.HouseholdID
                   where hh17.HoHID = hhid.HoHID and hh17.HHType = hhid.HHType
                    and n17.AgeGroup < 18))
          , HHNoDOB = (select case when count(distinct n.PersonalID) >= 3 then 3
                else count(distinct n.PersonalID) end
            from active_Household hhid
            inner join active_Enrollment n on n.HouseholdID = hhid.HouseholdID
            where n.AgeGroup > 65
              and hhid.HHType = hh.HHType and hhid.HoHID = hh.HoHID)
        from tmp_Household hh

        --   CHANGE 7/9/2018
        --   Split out setting HHAdultAge from insert statement above to correct bug
        --   -- households should be included in the AO 55+ population if all members
        --   were 55+ on any enrollment.
        update hh
        set hh.HHAdultAge = -1
        from tmp_Household hh
        where hh.HHType not in (1,2)

        update hh
        set hh.HHAdultAge = (select min(ahh.HHAdultAge)
            from active_Household ahh
          where ahh.HoHID = hh.HoHID and ahh.HHType = hh.HHType
            and ahh.HHAdultAge in (18,24))
        from tmp_Household hh
        where hh.HHType in (1,2)
          and hh.HHAdultAge is null

        update hh
        set hh.HHAdultAge = (select max(ahh.HHAdultAge)
            from active_Household ahh
          where ahh.HoHID = hh.HoHID and ahh.HHType = hh.HHType
            and ahh.HHAdultAge in (25,55))
        from tmp_Household hh
        where hh.HHType in (1,2)
          and (hh.HHAdultAge is null or hh.HHAdultAge not in (18,24))
      SQL
    end

    def four_twenty_six
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.26 Set tmp_Household Project Group Status Indicators
        **********************************************************************/

        update hh
        set ESTStatus = coalesce ((select
            min(case when an.ExitDate is null then 1
              else 2 end)
            from active_Enrollment an
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType in (1,2,8)), 0)
        from tmp_Household hh

        update hh
        set ESTStatus = ESTStatus + (select
            min(case when an.EntryDate < rpt.ReportStart then 10
              else 20 end)
            from active_Enrollment an
            inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType in (1,2,8))
        from tmp_Household hh
        where ESTStatus > 0

        update hh
        set RRHStatus = coalesce ((select
            min(case when an.ExitDate is null then 1
              else 2 end)
            from active_Enrollment an
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType = 13), 0)
        from tmp_Household hh

        update hh
        set RRHStatus = RRHStatus + (select
            min(case when an.EntryDate < rpt.ReportStart then 10
              else 20 end)
            from active_Enrollment an
            inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType = 13)
        from tmp_Household hh
        where RRHStatus > 0

        update hh
        set PSHStatus = coalesce ((select
            min(case when an.ExitDate is null then 1
              else 2 end)
            from active_Enrollment an
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType = 3), 0)
        from tmp_Household hh

        update hh
        set PSHStatus = PSHStatus + (select
            min(case when an.EntryDate < rpt.ReportStart then 10
              else 20 end)
            from active_Enrollment an
            inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
            where an.PersonalID = hh.HoHID
              and hh.HHType = an.HHType and an.RelationshipToHoH = 1
            and an.ProjectType = 3)
        from tmp_Household hh
        where PSHStatus > 0
      SQL
    end

    def four_twenty_seven
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.27 Set tmp_Household RRH and PSH Move-In Status Indicators
        **********************************************************************/
        update hh
        set hh.RRHMoveIn = case when hh.RRHStatus = 0 then -1
            else stat.RRHMoveIn end
          , hh.PSHMoveIn = case when hh.PSHStatus = 0 then -1
            else stat.PSHMoveIn end
        from tmp_Household hh
        left outer join (select distinct hhid.HoHID, hhid.HHType
            , RRHMoveIn = (select min(case when an.MoveInDate is null
                then 0
                when an.MoveInDate >= rpt.ReportStart then 1
                else 2 end)
              from active_Enrollment an
              inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
              where an.PersonalID = hhid.HoHID
                and an.HouseholdID = hhid.HouseholdID
                and hhid.ProjectType = 13)
            , PSHMoveIn = (select min(case when an.MoveInDate is null
                then 0
                when an.MoveInDate >= rpt.ReportStart then 1
                else 2 end)
              from active_Enrollment an
              inner join lsa_Report rpt on rpt.ReportEnd >= an.EntryDate
              where an.PersonalID = hhid.HoHID
                and an.HouseholdID = hhid.HouseholdID
                and hhid.ProjectType = 3)
          from active_Household hhid) stat on
            stat.HoHID = hh.HoHID and stat.HHType = hh.HHType

      SQL
    end

    def four_twenty_eight
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.28.a Get Most Recent Enrollment in Each ProjectGroup for HoH
        ***********************************************************************/
        update active_Enrollment set MostRecent = null

        update an
        set an.MostRecent =
          case when mr.EnrollmentID is null then 1
          else 0 end
        from active_Enrollment an
        left outer join (select later.PersonalID, later.EnrollmentID
            , later.EntryDate, later.HHType
            , case when later.ProjectType in (1,2,8) then 1
              else later.ProjectType end as PT
          from active_Enrollment later
          where later.RelationshipToHoH = 1
          ) mr on mr.PersonalID = an.PersonalID
            and mr.HHType = an.HHType
            and mr.PT = case when an.ProjectType in (1,2,8) then 1 else an.ProjectType end
            and (mr.EntryDate > an.EntryDate
              or (mr.EntryDate = an.EntryDate and mr.EnrollmentID > an.EnrollmentID))
        where an.RelationshipToHoH = 1
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.28.b Set tmp_Household Geography for Each Project Group
        **********************************************************************/
        update lhh
        set ESTGeography = -1
        from tmp_Household lhh
        where ESTStatus <= 10

        update lhh
        set ESTGeography = coalesce(
          (select top 1 lg.GeographyType
          from active_Enrollment an
          inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
          where an.MostRecent = 1 and an.ProjectType in (1,2,8)
            and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
            and an.HHType = lhh.HHType
          order by lg.InformationDate desc), 99)
        from tmp_Household lhh where ESTGeography is null

        update lhh
        set RRHGeography = -1
        from tmp_Household lhh
        where RRHStatus <= 10

        update lhh
        set RRHGeography = coalesce(
          (select top 1 lg.GeographyType
          from active_Enrollment an
          inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
          where an.MostRecent = 1 and an.ProjectType = 13
            and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
            and an.HHType = lhh.HHType
          order by lg.InformationDate desc), 99)
        from tmp_Household lhh where RRHGeography is null

        update lhh
        set PSHGeography = -1
        from tmp_Household lhh
        where PSHStatus <= 10

        update lhh
        set PSHGeography = coalesce(
          (select top 1 lg.GeographyType
          from active_Enrollment an
          inner join lsa_Geography lg on lg.ProjectID = an.ProjectID
          where an.MostRecent = 1 and an.ProjectType = 3
            and an.RelationshipToHoH = 1 and an.PersonalID = lhh.HoHID
            and an.HHType = lhh.HHType
          order by lg.InformationDate desc), 99)
        from tmp_Household lhh where PSHGeography is null

      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.28.c Set tmp_Household Living Situation for Each Project Group
        **********************************************************************/

        update lhh
        set ESTLivingSit = -1
        from tmp_Household lhh
        where ESTStatus <= 10

        update lhh
        set ESTLivingSit =
          case when hn.LivingSituation = 16 then 1 --Homeless - Street
            when hn.LivingSituation in (1,18) then 2  --Homeless - ES/SH
            when hn.LivingSituation = 27 then 3 --Interim Housing
            when hn.LivingSituation = 2 then 4  --Homeless - TH
            when hn.LivingSituation = 14 then 5 --Hotel/Motel - no voucher
            when hn.LivingSituation = 26 then 6 --Residential project
            when hn.LivingSituation = 12 then 7 --Family
            when hn.LivingSituation = 13 then 8 --Friends
            when hn.LivingSituation = 3 then 9  --PSH
            when hn.LivingSituation in (21,23) then 10  --PH - own
            when hn.LivingSituation = 22 then 11  --PH - rent no subsidy
            when hn.LivingSituation in (19,20,25) then 12 --PH - rent with subsidy
            when hn.LivingSituation = 15 then 13  --Foster care
            when hn.LivingSituation = 24 then 14  --Long-term care
            when hn.LivingSituation = 7 then 15 --Institutions - incarceration
            when hn.LivingSituation in (4,5,6) then 16  --Institutions - medical
            else 99 end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1
          and an.MostRecent = 1 and an.ProjectType in (1,2,8)

        update lhh
        set RRHLivingSit = -1
        from tmp_Household lhh
        where RRHStatus <= 10

        update lhh
        set RRHLivingSit =
          case when hn.LivingSituation = 16 then 1 --Homeless - Street
            when hn.LivingSituation in (1,18) then 2  --Homeless - ES/SH
            when hn.LivingSituation = 27 then 3 --Interim Housing
            when hn.LivingSituation = 2 then 4  --Homeless - TH
            when hn.LivingSituation = 14 then 5 --Hotel/Motel - no voucher
            when hn.LivingSituation = 26 then 6 --Residential project
            when hn.LivingSituation = 12 then 7 --Family
            when hn.LivingSituation = 13 then 8 --Friends
            when hn.LivingSituation = 3 then 9  --PSH
            when hn.LivingSituation in (21,23) then 10  --PH - own
            when hn.LivingSituation = 22 then 11  --PH - rent no subsidy
            when hn.LivingSituation in (19,20,25) then 12 --PH - rent with subsidy
            when hn.LivingSituation = 15 then 13  --Foster care
            when hn.LivingSituation = 24 then 14  --Long-term care
            when hn.LivingSituation = 7 then 15 --Institutions - incarceration
            when hn.LivingSituation in (4,5,6) then 16  --Institutions - medical
            else 99 end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1
          and an.MostRecent = 1 and an.ProjectType = 13

        update lhh
        set PSHLivingSit = -1
        from tmp_Household lhh
        where PSHStatus <= 10

        update lhh
        set PSHLivingSit =
          case when hn.LivingSituation = 16 then 1 --Homeless - Street
            when hn.LivingSituation in (1,18) then 2  --Homeless - ES/SH
            when hn.LivingSituation = 27 then 3 --Interim Housing
            when hn.LivingSituation = 2 then 4  --Homeless - TH
            when hn.LivingSituation = 14 then 5 --Hotel/Motel - no voucher
            when hn.LivingSituation = 26 then 6 --Residential project
            when hn.LivingSituation = 12 then 7 --Family
            when hn.LivingSituation = 13 then 8 --Friends
            when hn.LivingSituation = 3 then 9  --PSH
            when hn.LivingSituation in (21,23) then 10  --PH - own
            when hn.LivingSituation = 22 then 11  --PH - rent no subsidy
            when hn.LivingSituation in (19,20,25) then 12 --PH - rent with subsidy
            when hn.LivingSituation = 15 then 13  --Foster care
            when hn.LivingSituation = 24 then 14  --Long-term care
            when hn.LivingSituation = 7 then 15 --Institutions - incarceration
            when hn.LivingSituation in (4,5,6) then 16  --Institutions - medical
            else 99 end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1
          and an.MostRecent = 1 and an.ProjectType = 3

      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.28.d Set tmp_Household Destination for Each Project Group
        **********************************************************************/

        update lhh
        set ESTDestination = -1
        from tmp_Household lhh
        where ESTStatus not in (12,22)

        update lhh
        set ESTDestination =
          case when hx.Destination = 3 then 1 --PSH
           when hx.Destination = 31 then 2  --PH - rent/temp subsidy
           when hx.Destination in (19,20,21,26,28) then 3 --PH - rent/own with subsidy
           when hx.Destination in (10,11) then 4  --PH - rent/own no subsidy
           when hx.Destination = 22 then 5  --Family - perm
           when hx.Destination = 23 then 6  --Friends - perm
           when hx.Destination in (15,25) then 7  --Institutions - group/assisted
           when hx.Destination in (4,5,6) then 8  --Institutions - medical
           when hx.Destination = 7 then 9 --Institutions - incarceration
           when hx.Destination in (14,29) then 10 --Temporary - not homeless
           when hx.Destination in (1,2,18,27) then 11 --Homeless - ES/SH/TH
           when hx.Destination = 16 then 12 --Homeless - Street
           when hx.Destination = 12 then 13 --Family - temp
           when hx.Destination = 13 then 14 --Friends - temp
           when hx.Destination = 24 then 15 --Deceased
           else 99  end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Exit hx on hx.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1 and an.ExitDate is not null
          and an.MostRecent = 1 and an.ProjectType in (1,2,8)


        update lhh
        set RRHDestination = -1
        from tmp_Household lhh
        where RRHStatus not in (12,22)

        update lhh
        set RRHDestination =
          case when hx.Destination = 3 then 1 --PSH
           when hx.Destination = 31 then 2  --PH - rent/temp subsidy
           when hx.Destination in (19,20,21,26,28) then 3 --PH - rent/own with subsidy
           when hx.Destination in (10,11) then 4  --PH - rent/own no subsidy
           when hx.Destination = 22 then 5  --Family - perm
           when hx.Destination = 23 then 6  --Friends - perm
           when hx.Destination in (15,25) then 7  --Institutions - group/assisted
           when hx.Destination in (4,5,6) then 8  --Institutions - medical
           when hx.Destination = 7 then 9 --Institutions - incarceration
           when hx.Destination in (14,29) then 10 --Temporary - not homeless
           when hx.Destination in (1,2,18,27) then 11 --Homeless - ES/SH/TH
           when hx.Destination = 16 then 12 --Homeless - Street
           when hx.Destination = 12 then 13 --Family - temp
           when hx.Destination = 13 then 14 --Friends - temp
           when hx.Destination = 24 then 15 --Deceased
           else 99  end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Exit hx on hx.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1 and an.ExitDate is not null
          and an.MostRecent = 1 and an.ProjectType = 13

        update lhh
        set PSHDestination = -1
        from tmp_Household lhh
        where PSHStatus not in (12,22)

        update lhh
        set PSHDestination =
          case when hx.Destination = 3 then 1 --PSH
           when hx.Destination = 31 then 2  --PH - rent/temp subsidy
           when hx.Destination in (19,20,21,26,28) then 3 --PH - rent/own with subsidy
           when hx.Destination in (10,11) then 4  --PH - rent/own no subsidy
           when hx.Destination = 22 then 5  --Family - perm
           when hx.Destination = 23 then 6  --Friends - perm
           when hx.Destination in (15,25) then 7  --Institutions - group/assisted
           when hx.Destination in (4,5,6) then 8  --Institutions - medical
           when hx.Destination = 7 then 9 --Institutions - incarceration
           when hx.Destination in (14,29) then 10 --Temporary - not homeless
           when hx.Destination in (1,2,18,27) then 11 --Homeless - ES/SH/TH
           when hx.Destination = 16 then 12 --Homeless - Street
           when hx.Destination = 12 then 13 --Family - temp
           when hx.Destination = 13 then 14 --Friends - temp
           when hx.Destination = 24 then 15 --Deceased
           else 99  end
        from active_Enrollment an
        inner join tmp_Household lhh on lhh.HoHID = an.PersonalID
          and lhh.HHType = an.HHType
        inner join hmis_Exit hx on hx.EnrollmentID = an.EnrollmentID
        where an.RelationshipToHoH = 1 and an.ExitDate is not null
          and an.MostRecent = 1 and an.ProjectType = 3

      SQL
    end

    def four_twenty_nine
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.29.a Get Earliest EntryDate from Active Enrollments
        **********************************************************************/
        --CHANGE 9/17/2018 - add step to set FirstEntry
        update lhh
        set lhh.FirstEntry = (select min(an.EntryDate)
          from active_Enrollment an
          where an.PersonalID = lhh.HoHID and an.HHType = lhh.HHType)
        from tmp_Household lhh
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.29.b Get EnrollmentID for Latest Exit in Two Years Prior to FirstEntry
        **********************************************************************/
        update lhh
        set lhh.StatEnrollmentID =
          (select top 1 prior.EnrollmentID
          from hmis_Enrollment prior
          inner join hmis_Exit hx on hx.EnrollmentID = prior.EnrollmentID
            and hx.ExitDate > prior.EntryDate
            --CHANGE 9/17/2018 - add check to ensure exit is before FirstEntry
            and hx.ExitDate between dateadd(dd,-730,lhh.FirstEntry) and lhh.FirstEntry
          inner join --Get enrollments for the same HoH and HHType prior to FirstEntry
            (select HouseholdID
              , case
              when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0 then 2
              when AgeStatus/100 > 0 then 99
              when AgeStatus%10 > 0 then 3
              when (AgeStatus/10)%100 > 0 then 1
              else 99 end as HHType
            from
              --get AgeStatus for household members on previous enrollment
              (select hn.HouseholdID
                , sum(case when c.DOBDataQuality in (8,9)
                  or c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                  --age for non-active enrollments is always based on EntryDate
                  or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 100
                when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                else 1 end) as AgeStatus
              from hmis_Enrollment hn
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              inner join --get project type and CoC info for prior enrollments
                  (select distinct hhinfo.HouseholdID
                  from hmis_Enrollment hhinfo
                  inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                  inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                  inner join hmis_EnrollmentCoC coc on
                    coc.EnrollmentID = hhinfo.EnrollmentID
                    and coc.CoCCode = rpt.ReportCoC
                  where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                      group by hhinfo.HouseholdID, coc.CoCCode
                      ) hoh on hoh.HouseholdID = hn.HouseholdID
                  group by hn.HouseholdID
                  ) hhid) hh on hh.HouseholdID = prior.HouseholdID
            where prior.PersonalID = lhh.HoHID and prior.RelationshipToHoH = 1
                and hh.HHType = lhh.HHType
            order by hx.ExitDate desc)
        from tmp_Household lhh
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.29.c Set System Engagement Status for tmp_Household
        **********************************************************************/
        update lhh
        set lhh.Stat = case
        --CHANGE 9/17/2018 set 5 based on PSH/RRH/ESTStatus in (11,12)
          when PSHStatus in (11,12) or RRHStatus in (11,12) or ESTStatus in (11,12)
            then 5
          when lhh.StatEnrollmentID is null then 1
          when dateadd(dd, 15, hx.ExitDate) >= lhh.FirstEntry then 5
          when hx.Destination in (3,31,19,20,21,26,28,10,11,22,23) then 2
          when hx.Destination in (15,25,4,5,6,7,14,29,1,2,18,27,16,12,13) then 3
          else 4 end
        from tmp_Household lhh
        left outer join hmis_Exit hx on hx.EnrollmentID = lhh.StatEnrollmentID
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*************************************************************************
        4.29.d Set ReturnTime for tmp_Household
        **********************************************************************/
        --CHANGE 9/17/2018 - add step to set ReturnTime
        update lhh
        set lhh.ReturnTime = case
          when lhh.Stat in (1, 5) then -1
          else datediff(dd, hx.ExitDate, lhh.FirstEntry) end
        from tmp_Household lhh
        left outer join hmis_Exit hx on hx.EnrollmentID = lhh.StatEnrollmentID
      SQL
    end

    def four_thirty
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.30 Get Days In RRH Pre-Move-In
        *****************************************************************/
        update lhh
        set RRHPreMoveInDays = case when RRHStatus < 10 then -1
          else (select count(distinct cal.theDate)
            from tmp_Person lp
            inner join lsa_Report rpt on rpt.ReportID = lp.ReportID
            inner join active_Enrollment an on an.PersonalID = lp.PersonalID
            inner join ref_Calendar cal on cal.theDate >= an.EntryDate
              and cal.theDate <= coalesce(
                    dateadd(dd, -1, an.MoveInDate)
                  , dateadd(dd, -1, an.ExitDate)
                  , rpt.ReportEnd)
            where an.ProjectType = 13 and an.HHType = lhh.HHType
              and lp.PersonalID = lhh.HoHID) end
        from tmp_Household lhh

      SQL
    end

    def four_thirty_one
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.31 Get Dates Housed in PSH or RRH
        *****************************************************************/
        delete from sys_Time

        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct an.PersonalID, an.HHType, cal.theDate
          , min(case an.ProjectType
              when 3 then 1
              else 2 end)
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
          and an.RelationshipToHoH = 1
        inner join ref_Calendar cal on cal.theDate >= an.MoveInDate
          and (cal.theDate < an.ExitDate
              or (an.ExitDate is null and cal.theDate <= lp.LastActive))
        where an.ProjectType in (3,13)
        group by an.PersonalID, an.HHType, cal.theDate
      SQL
    end

    def four_thirty_two
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.32 Get Enrollments Relevant to Last Inactive Date and Other System Use Days
        *****************************************************************/
        delete from sys_Enrollment

        insert into sys_Enrollment (HoHID, HHType, EnrollmentID, ProjectType
          , EntryDate
          , MoveInDate
          , ExitDate
          , Active)
        select distinct hn.PersonalID, hh.HHType, hn.EnrollmentID, p.ProjectType
          , case when p.TrackingMethod = 3 then null else hn.EntryDate end
          , case when p.ProjectType in (3,13) then hn.MoveInDate else null end
          , case when p.TrackingMethod = 3 then null else hx.ExitDate end
          , case when an.EnrollmentID is not null then 1 else 0 end
        from tmp_Household lhh
        inner join lsa_Report rpt on rpt.ReportID = lhh.ReportID
        --CHANGE 9/72018 remove unneeded join to sys_Time
        inner join hmis_Enrollment hn on hn.PersonalID = lhh.HoHID
          and hn.RelationshipToHoH = 1
        left outer join active_Enrollment an on an.EnrollmentID = hn.EnrollmentID
        left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
          and hx.ExitDate <= rpt.ReportEnd
        inner join hmis_Project p on p.ProjectID = hn.ProjectID
        inner join (select HouseholdID, case
              --if at least 1 adult and 1 child, HHType = 2
            when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0
              then 2
            --If not adult/child, any unknown age means HHType = 99
            when AgeStatus/100 > 0
              then 99
            --child only HHType = 3
            when AgeStatus%10 > 0
              then 3
            --adult only HHType = 1
            when (AgeStatus/10)%100 > 0
              then 1
            else 99 end as HHType
            from (select hn.HouseholdID
              , sum(case when c.DOBDataQuality in (8,9)
                  or c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                  or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 100
                when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                else 1 end) as AgeStatus
              from hmis_Enrollment hn
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              inner join (select distinct hhinfo.HouseholdID
                  from hmis_Enrollment hhinfo
                  inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                  inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                  inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
                    and coc.CoCCode = rpt.ReportCoC
                  where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                  group by hhinfo.HouseholdID, coc.CoCCode
                  ) hoh on hoh.HouseholdID = hn.HouseholdID
              group by hn.HouseholdID
              ) hhid) hh on hh.HouseholdID = hn.HouseholdID
        where
          an.EnrollmentID is not null --All active enrollments are relevant.
          or (hx.ExitDate >= '10/1/2012'-- Inactive enrollments potentially relevant...
            and lhh.Stat = 5 --... if HH was 'continously engaged' at ReportStart...
            and lhh.PSHMoveIn <> 2) --...and not housed in PSH at ReportStart.
      SQL
    end

    def four_thirty_three
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.33 Get Last Inactive Date
        *****************************************************************/
        update lhh
        -- CHANGE 7/9/2018 coalesce lastDay.inactive or 9/30/2012 to ensure that
        --households active on 10/1/2012 have a LastInactive date.
        set lhh.LastInactive = coalesce(lastDay.inactive, '9/30/2012')
        from tmp_Household lhh
        inner join (select lhh.HoHID, lhh.HHType, max(cal.theDate) as inactive
          from tmp_Household lhh
          inner join lsa_Report rpt on rpt.ReportID = lhh.ReportID
          inner join ref_Calendar cal on cal.theDate <= rpt.ReportEnd
            and cal.theDate >= '10/1/2012'
          left outer join
             (select distinct sn.HoHID as HoHID
              , sn.HHType as HHType
              , bn.DateProvided as StartDate
              , case when bn.DateProvided < rpt.ReportStart
                --CHANGE 7/9/2018 add 6 days to DateProvided (was 7)
                then dateadd(dd,6,bn.DateProvided)
                else rpt.ReportEnd end as EndDate
            from sys_Enrollment sn
            inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
              and bn.RecordType = 200
            inner join lsa_Report rpt on rpt.ReportEnd >= bn.DateProvided
            where sn.EntryDate is null
            union select sn.HoHID, sn.HHType, sn.EntryDate
              , case when sn.ExitDate < rpt.ReportStart
                then dateadd(dd,6,sn.ExitDate)
                else rpt.ReportEnd end
            from sys_Enrollment sn
            inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
            where sn.ProjectType in (1,8,2) or sn.MoveInDate is null
            ) padded on padded.HoHID = lhh.HoHID and padded.HHType = lhh.HHType
              and cal.theDate between padded.StartDate and padded.EndDate
          where padded.HoHID is null
            --CHANGE 7/9/2018 LastInactive must be before FirstEntry
            and cal.theDate < lhh.FirstEntry
        group by lhh.HoHID, lhh.HHType
          ) lastDay on lastDay.HoHID = lhh.HoHID and lastDay.HHType = lhh.HHType
      SQL
    end

    def four_thirty_four
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.34 Get Dates of Other System Use
        *****************************************************************/
        --Transitional Housing (sys_Time.sysStatus = 3)
        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct sn.HoHID, sn.HHType, cal.theDate, 3
        from sys_Enrollment sn
        inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
        inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
        inner join ref_Calendar cal on
          cal.theDate >= sn.EntryDate
          and cal.theDate > lhh.LastInactive
          and cal.theDate < coalesce(sn.ExitDate, rpt.ReportEnd)
        left outer join sys_Time housed on housed.HoHID = sn.HoHID and housed.HHType = sn.HHType
          and housed.sysDate = cal.theDate
        where housed.sysDate is null and sn.ProjectType = 2
        group by sn.HoHID, sn.HHType, cal.theDate

        --Emergency Shelter (Entry/Exit) (sys_Time.sysStatus = 4)
        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct sn.HoHID, sn.HHType, cal.theDate, 4
        from sys_Enrollment sn
        inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
        inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
        inner join ref_Calendar cal on
          cal.theDate >= sn.EntryDate
          and cal.theDate < coalesce(sn.ExitDate, rpt.ReportEnd)
        left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
          and other.sysDate = cal.theDate
        where (cal.theDate > lhh.LastInactive)
          and other.sysDate is null and sn.ProjectType = 1

        --Emergency Shelter (Night-by-Night) (sys_Time.sysStatus = 4)
        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct sn.HoHID, sn.HHType, cal.theDate, 4
        from sys_Enrollment sn
        inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
          and bn.RecordType = 200
        inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
        inner join lsa_Report rpt on rpt.ReportEnd >= bn.DateProvided
        inner join ref_Calendar cal on cal.theDate = bn.DateProvided
        left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
          and other.sysDate = cal.theDate
        where (cal.theDate > lhh.LastInactive)
          and other.sysDate is null and sn.ProjectType = 1

        --Homeless (Time prior to Move-In) in PSH or RRH (sys_Time.sysStatus = 5 or 6)
        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct sn.HoHID, sn.HHType, cal.theDate
          , min (case when sn.ProjectType = 3 then 5 else 6 end)
        from sys_Enrollment sn
        inner join tmp_Household lhh on lhh.HoHID = sn.HoHID and lhh.HHType = sn.HHType
        inner join lsa_Report rpt on rpt.ReportEnd >= sn.EntryDate
        inner join ref_Calendar cal on
          cal.theDate >= sn.EntryDate
          and cal.theDate < coalesce(sn.MoveInDate, sn.ExitDate, rpt.ReportEnd)
        left outer join sys_Time other on other.HoHID = sn.HoHID and other.HHType = sn.HHType
          and other.sysDate = cal.theDate
        where (sn.Active = 1 or sn.MoveInDate is null)
          and cal.theDate > lhh.LastInactive
          and other.sysDate is null and sn.ProjectType in (3,13)
        group by sn.HoHID, sn.HHType, cal.theDate
      SQL
    end

    def four_thirty_five
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.35 Get Other Dates Homeless from 3.917 Living Situation
        *****************************************************************/
        --If there are enrollments in sys_Enrollment where EntryDate >= LastInactive,
        -- dates between the earliest DateToStreetESSH and LastInactive --
        -- i.e., dates without a potential status conflict based on other system use --
        -- populate Other3917Days as the difference in days between DateToStreetESSH
        -- and LastInactive + 1.
        --
        update lhh
        set lhh.Other3917Days = (select datediff (dd,
            (select top 1 hn.DateToStreetESSH
            from sys_Enrollment sn
            inner join hmis_Enrollment hn on hn.EnrollmentID = sn.EnrollmentID
            where sn.HHType = lhh.HHType
              and sn.HoHID = lhh.HoHID
              and dateadd(dd, 1, lhh.LastInactive) between hn.DateToStreetESSH and hn.EntryDate
            order by hn.DateToStreetESSH asc)
          , lhh.LastInactive))
        from tmp_Household lhh


        insert into sys_Time (HoHID, HHType, sysDate, sysStatus)
        select distinct sn.HoHID, sn.HHType, cal.theDate, 7
        from sys_Enrollment sn
        inner join hmis_Enrollment hn on hn.EnrollmentID = sn.EnrollmentID
        inner join sys_Time contiguous on contiguous.sysDate = hn.EntryDate
          and contiguous.HoHID = sn.HoHID and contiguous.HHType = sn.HHType
        inner join ref_Calendar cal on cal.theDate >= hn.DateToStreetESSH
          and cal.theDate < hn.EntryDate
        left outer join sys_Time st on st.HoHID = sn.HoHID and st.HHType = sn.HHType
          and st.sysDate = cal.theDate
        where st.sysDate is null
          and (sn.ProjectType in (1,8)
          or hn.LivingSituation in (1,18,16)
          or (hn.LengthOfStay in (10,11) and hn.PreviousStreetESSH = 1)
          or (hn.LivingSituation in (4,5,6,7,15,24)
            and hn.LengthOfStay in (2,3) and hn.PreviousStreetESSH = 1))
      SQL

    def four_thirty_six
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.36 Set System Use Days for LSAHousehold
        *****************************************************************/
        update lhh
        set ESDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus = 4
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , THDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus = 3
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , ESTDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus in (3,4)
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , RRHPSHPreMoveInDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus in (5,6)
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , RRHHousedDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus = 2
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , SystemDaysNotPSHHoused = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus in (2,3,4,5,6)
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , SystemHomelessDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus in (3,4,5,6)
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , Other3917Days = Other3917Days + (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus = 7
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , TotalHomelessDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus in (3,4,5,6,7)
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
          , PSHHousedDays = (select count(distinct st.sysDate)
            from sys_Time st
            where st.sysStatus = 1
            and st.HoHID = lhh.HoHID and st.HHType = lhh.HHType)
        from tmp_Household lhh

        --CHANGE 9/19/2018
        --Set counts of days in project type to -1 for households with no
        --active enrollment in the relevant project type.
        update lhh
        set lhh.ESDays = -1
        from tmp_Household lhh
        where lhh.ESDays = 0 and lhh.ESTStatus = 0

        update lhh
        set lhh.THDays = -1
        from tmp_Household lhh
        where lhh.THDays = 0 and lhh.ESTStatus = 0

        update lhh
        set lhh.ESTDays = -1
        from tmp_Household lhh
        where lhh.ESDays = -1 and lhh.THDays = -1

        update lhh
        set lhh.RRHPSHPreMoveInDays = -1
        from tmp_Household lhh
        where lhh.RRHPSHPreMoveInDays = 0
          and lhh.RRHStatus = 0 and lhh.PSHStatus = 0

        update lhh
        set lhh.RRHHousedDays = -1
        from tmp_Household lhh
        where lhh.RRHHousedDays = 0 and lhh.RRHStatus = 0

        update lhh
        set lhh.PSHHousedDays = -1
        from tmp_Household lhh
        where lhh.PSHHousedDays = 0 and lhh.PSHStatus = 0
      SQL
    end

    def four_thrity_seven
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.37 Update ESTStatus and RRHStatus
        *****************************************************************/
        update lhh
        set lhh.ESTStatus = 2
        from tmp_Household lhh
        where lhh.ESTStatus = 0
          and (lhh.ESTDays > 0)

        update lhh
        set lhh.RRHStatus = 2
        from tmp_Household lhh
        where lhh.RRHStatus = 0
          and (RRHPreMoveInDays > 0 or RRHHousedDays > 0)

      SQL
    end

    def four_thirty_eight
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.38 Set SystemPath for LSAHousehold
        *****************************************************************/
        update lhh
        set SystemPath =
          case when ESTStatus not in (21,22) and RRHStatus not in (21,22) and PSHMoveIn = 2
            then -1
          when ESDays >= 1 and THDays <= 0 and RRHStatus = 0 and PSHStatus = 0
            then 1
          when ESDays <= 0 and THDays >= 1 and RRHStatus = 0 and PSHStatus = 0
            then 2
          when ESDays >= 1 and THDays >= 1 and RRHStatus = 0 and PSHStatus = 0
            then 3
          when ESDays <= 0 and THDays <= 0 and RRHStatus >= 2 and PSHStatus = 0
            then 4
          when ESDays >= 1 and THDays <= 0 and RRHStatus >= 2 and PSHStatus = 0
            then 5
          when ESDays <= 0 and THDays >= 1 and RRHStatus >= 2 and PSHStatus = 0
            then 6
          when ESDays >= 1 and THDays >= 1 and RRHStatus >= 2 and PSHStatus = 0
            then 7
          when ESDays <= 0 and THDays <= 0 and RRHStatus = 0 and PSHStatus >= 11 and PSHMoveIn <> 2
            then 8
          when ESDays >= 1 and THDays <= 0 and RRHStatus = 0 and PSHStatus >= 11 and PSHMoveIn <> 2
            then 9
          when ESDays >= 1 and THDays <= 0 and RRHStatus >= 2 and PSHStatus >= 11 and PSHMoveIn <> 2
            then 10
          when ESDays <= 0 and THDays <= 0 and RRHStatus >= 2 and PSHStatus >= 11 and PSHMoveIn <> 2
            then 11
          else 12 end
        from tmp_Household lhh

      SQL
    end

    def four_thirty_nine
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.39 Get Exit Cohort Dates
        *****************************************************************/
        delete from tmp_CohortDates

        insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
        select 0, rpt.ReportStart,
          case when dateadd(mm, -6, rpt.ReportEnd) <= rpt.ReportStart
            then rpt.ReportEnd
            else dateadd(mm, -6, rpt.ReportEnd) end
        from lsa_Report rpt

        insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
        select -1, dateadd(yyyy, -1, rpt.ReportStart)
          , dateadd(yyyy, -1, rpt.ReportEnd)
        from lsa_Report rpt

        insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
        select -2, dateadd(yyyy, -2, rpt.ReportStart)
          , dateadd(yyyy, -2, rpt.ReportEnd)
        from lsa_Report rpt


      SQL
    end

    def four_forty

      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.40 Get Exit Cohort Members and Enrollments
        *****************************************************************/
        delete from ex_Enrollment

        insert into ex_Enrollment (Cohort, HoHID, HHType, EnrollmentID, ProjectType
           , EntryDate, MoveInDate, ExitDate, ExitTo)
        select distinct cd.Cohort, hn.PersonalID, hh.HHType, hn.EnrollmentID, p.ProjectType
           , hn.EntryDate, hn.MoveInDate, hx.ExitDate
           , case when hx.Destination = 3 then 1 --PSH
           when hx.Destination = 31 then 2  --PH - rent/temp subsidy
           when hx.Destination in (19,20,21,26,28) then 3 --PH - rent/own with subsidy
           when hx.Destination in (10,11) then 4  --PH - rent/own no subsidy
           when hx.Destination = 22 then 5  --Family - perm
           when hx.Destination = 23 then 6  --Friends - perm
           when hx.Destination in (15,25) then 7  --Institutions - group/assisted
           when hx.Destination in (4,5,6) then 8  --Institutions - medical
           when hx.Destination = 7 then 9 --Institutions - incarceration
           when hx.Destination in (14,29) then 10 --Temporary - not homeless
           when hx.Destination in (1,2,18,27) then 11 --Homeless - ES/SH/TH
           when hx.Destination = 16 then 12 --Homeless - Street
           when hx.Destination = 12 then 13 --Family - temp
           when hx.Destination = 13 then 14 --Friends - temp
           when hx.Destination = 24 then 15 --Deceased
           else 99  end
        from hmis_Enrollment hn
        inner join hmis_Project p on p.ProjectID = hn.ProjectID
        inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
          and hx.ExitDate > hn.EntryDate
        inner join tmp_CohortDates cd on cd.CohortStart <= hx.ExitDate
          and cd.CohortEnd >= hx.ExitDate
        inner join
            --hh identifies household exits by HHType from relevant projects
            --and adds HHType their HHType
            (select HouseholdID, case
            when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0 then 2
            when AgeStatus/100 > 0 then 99
            when AgeStatus%10 > 0 then 3
            when (AgeStatus/10)%100 > 0 then 1
            else 99 end as HHType
            from (--hhid identifies age status (adult/child/unknown) for
                --members of households with exits in subquery hoh
              select hn.HouseholdID
              , sum(case when c.DOBDataQuality in (8,9)
                  or c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                  --CHANGE 9/19/2018 - check for age > 105 on CohortStart, if relevant
                  or ((hn.EntryDate >= cd.CohortStart
                    and dateadd(yy, 105, c.DOB) <= hn.EntryDate)
                      or (dateadd(yy, 105, c.DOB) <= cd.CohortStart))
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 100
                --calculate age for qualifying exit as of
                --the later of CohortStart and EntryDate
                when hn.EntryDate >= cd.CohortStart
                  and dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                when dateadd(yy, 18, c.DOB) <= cd.CohortStart then 10
                else 1 end) as AgeStatus
              from hmis_Enrollment hn
              inner join tmp_CohortDates cd on cd.CohortEnd >= hn.EntryDate
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              inner join
                  --hoh identifies exits for heads of household
                  --from relevant projects in cohort periods
                  (select distinct hhinfo.HouseholdID
                  from hmis_Enrollment hhinfo
                  inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                  inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                  --CHANGE 9/19/2018 -- add left outer join to lsa_Project
                  left outer join lsa_Project lp on lp.ProjectID = p.ProjectID
                  inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
                    and coc.CoCCode = rpt.ReportCoC
                  --CHANGE 9/19/2018 - Add LSAScope to WHERE clause
                  --Project type for qualifying exit MAY BE STREET OUTREACH
                  --in addition to ES/SH/TH/RRH/PSH when LSAScope = 1 (systemwide).
                  --  When LSAScope = 2 (project-focused), the project must have a record
                  --  in lsa_Project
                  where p.ProjectType in (1,2,3,4,8,13) and p.ContinuumProject = 1
                      and (rpt.LSAScope = 1 or lp.ProjectID is not NULL)
                  group by hhinfo.HouseholdID, coc.CoCCode
                  ) hoh on hoh.HouseholdID = hn.HouseholdID
              group by hn.HouseholdID
              ) hhid) hh on hh.HouseholdID = hn.HouseholdID
        left outer join
            --Subquery b identifies household enrollments by HHType in ES/SH/TH/RRH/PSH
            --  projects active in the cohort period; if these include any activity in the
            --  within 15 days of an exit identified in the hh subquery, the hh exit is
            --  excluded in the WHERE clause.
            (select hn.PersonalID as HoHID, hh.HHType, hn.EntryDate, hx.ExitDate
            from hmis_Enrollment hn
            left outer join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
            inner join (select HouseholdID, case
                when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0 then 2
                when AgeStatus/100 > 0 then 99
                when AgeStatus%10 > 0 then 3
                when (AgeStatus/10)%100 > 0 then 1
                else 99 end as HHType
                from (select hn.HouseholdID
                  , sum(case when c.DOBDataQuality in (8,9)
                      or c.DOB is null
                      or c.DOB = '1/1/1900'
                      or c.DOB > hn.EntryDate
                      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                      or c.DOBDataQuality is null
                      or c.DOBDataQuality not in (1,2) then 100
                    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                    else 1 end) as AgeStatus
                  from hmis_Enrollment hn
                  inner join hmis_Client c on c.PersonalID = hn.PersonalID
                  inner join (select distinct hhinfo.HouseholdID
                      from hmis_Enrollment hhinfo
                      inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                      inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                      inner join hmis_EnrollmentCoC coc on
                        coc.EnrollmentID = hhinfo.EnrollmentID
                        and coc.CoCCode = rpt.ReportCoC
                      --only ES/SH/TH/RRH/PSH enrollments are relevant
                      where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                      group by hhinfo.HouseholdID, coc.CoCCode
                      ) hoh on hoh.HouseholdID = hn.HouseholdID
                  group by hn.HouseholdID
                  ) hhid) hh on hh.HouseholdID = hn.HouseholdID
                where hn.RelationshipToHoH = 1
                ) b on b.HoHID = hn.PersonalID and b.HHType = hh.HHType
                  and b.EntryDate < dateadd(dd, 15, hx.ExitDate)
                  -- CHANGE 9/19/2018 include enrollments where ExitDate is NULL
                  and (b.ExitDate is NULL or b.ExitDate > hx.ExitDate)
        --If there is at least one exit followed by 15 days of inactivity during a cohort period,
        --the HoHID/HHType is included in the relevant exit cohort.
        where hn.RelationshipToHoH = 1 and b.HoHID is null and cd.Cohort <= 0
      SQL
    end

    def four_forty_one_and_two
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.41 Get EnrollmentIDs for Exit Cohort Households

               and

        4.42 Set ExitFrom and ExitTo for Exit Cohort Households
        *****************************************************************/
        update ex
        set ex.Active = 1
        from ex_Enrollment ex
        where ex.EnrollmentID = (select top 1 EnrollmentID
                      from ex_Enrollment a
                      where a.HoHID = ex.HoHID and a.HHType = ex.HHType
                              and a.Cohort = ex.Cohort
                      order by case when a.ExitTo between 1 and 6 then 2
                              when a.ExitTo between 7 and 14 then 3
                              else 4 end asc, a.ExitDate asc)

        delete from tmp_Exit

        insert into tmp_Exit (Cohort, HoHID, HHType
               , EnrollmentID, ex.EntryDate, ex.ExitDate, ExitFrom, ExitTo)
        select distinct ex.Cohort, ex.HoHID, ex.HHType
               , ex.EnrollmentID, ex.EntryDate, ex.ExitDate
               , case ex.ProjectType
                      when 4 then 1
                      when 1 then 2
                      when 2 then 3
                      when 8 then 4
                      when 13 then 5
                      else 6 end
               , ex.ExitTo
        from ex_Enrollment ex
        where ex.Active = 1

        update tmp_Exit
        set ReportID = (select ReportID
                      from lsa_Report)
      SQL
    end

    def four_forty_three
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.43 Set ReturnTime for Exit Cohort Households
        *****************************************************************/
        update ex
        set ex.ReturnDate = (select min(hn.EntryDate)
            from hmis_Enrollment hn
            inner join (select HouseholdID, case
                when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0 then 2
                when AgeStatus/100 > 0 then 99
                when AgeStatus%10 > 0 then 3
                when (AgeStatus/10)%100 > 0 then 1
                else 99 end as HHType
                from (select hn.HouseholdID
                  , sum(case when c.DOBDataQuality in (8,9)
                      or c.DOB is null
                      or c.DOB = '1/1/1900'
                      or c.DOB > hn.EntryDate
                      or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                      --age for later enrollments is always based on EntryDate
                      or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                      or c.DOBDataQuality is null
                      or c.DOBDataQuality not in (1,2) then 100
                    when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                    else 1 end) as AgeStatus
                  from hmis_Enrollment hn
                  inner join hmis_Client c on c.PersonalID = hn.PersonalID
                  inner join (select distinct hhinfo.HouseholdID
                      from hmis_Enrollment hhinfo
                      inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                      inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                      inner join hmis_EnrollmentCoC coc on
                        coc.EnrollmentID = hhinfo.EnrollmentID
                        and coc.CoCCode = rpt.ReportCoC
                      --only later ES/SH/TH/RRH/PSH enrollments are relevant
                      where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                      group by hhinfo.HouseholdID, coc.CoCCode
                      ) hoh on hoh.HouseholdID = hn.HouseholdID
                  group by hn.HouseholdID
                  ) hhid) hh on hh.HouseholdID = hn.HouseholdID
                where hn.RelationshipToHoH = 1
                  and hn.PersonalID = ex.HoHID and hh.HHType = ex.HHType
                  and hn.EntryDate
                    between dateadd(dd, 15, ex.ExitDate) and dateadd(dd, 730, ex.ExitDate))
        from tmp_Exit ex

        update ex
        set ex.ReturnTime =
          case when ex.ReturnDate is null then -1
            else datediff(dd, ex.ExitDate, ex.ReturnDate) end
        from tmp_Exit ex
      SQL
    end

    def four_forty_four
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.44 Set Population Identifiers for Exit Cohort Households
        *****************************************************************/
        update ex
        set ex.HoHRace = case
            when c.RaceNone in (8,9) then 98
            when c.AmIndAkNative + c.Asian + c.BlackAfAmerican +
               c.NativeHIOtherPacific + c.White > 1 then 6
            when c.White = 1 and c.Ethnicity = 1 then 1
            when c.White = 1 then 0
            when c.BlackAfAmerican = 1 then 2
            when c.Asian = 1 then 3
            when c.AmIndAkNative = 1 then 4
            when c.NativeHIOtherPacific = 1 then 5
            else 99 end
          , ex.HoHEthnicity = case
            when c.Ethnicity in (8,9) then 98
            when c.Ethnicity in (0,1) then c.Ethnicity
            else 99 end
        from tmp_Exit ex
        inner join hmis_Client c on c.PersonalID = ex.HoHID


        update ex
        set ex.HHVet = pop.HHVet
          , ex.HHDisability = pop.HHDisability
          , ex.HHFleeingDV = pop.HHFleeingDV
          , ex.HHParent = case when ex.HHType in (2,3)
            then pop.HHParent else 0 end
          , ex.AC3Plus = case when ex.HHType = 2
            and pop.HHChild >= 3 then 1 else 0 end
        from tmp_Exit ex
        inner join (
          select ex.EnrollmentID
            , max(case when age.ageStat = 1 and c.VeteranStatus = 1 then 1
              else 0 end) as HHVet
            , max(case when (age.ageStat = 1 or hn.RelationshipToHoH = 1)
                and hn.DisablingCondition = 1 then 1
              else 0 end) as HHDisability
            , max(case when (age.ageStat = 1 or hn.RelationshipToHoH = 1)
                and dv.DomesticViolenceVictim = 1 and dv.CurrentlyFleeing = 1 then 1
              else 0 end) as HHFleeingDV
            , sum(case when age.ageStat = 0 then 1
              else 0 end) as HHChild
            , max(case when hn.RelationshipToHoH = 2 then 1
              else 0 end) as HHParent
          from tmp_Exit ex
          inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
          inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
          inner join hmis_Client c on c.PersonalID = hn.PersonalID
          left outer join hmis_HealthAndDV dv on hn.EnrollmentID = dv.EnrollmentID
          inner join (select distinct hn.PersonalID
            , case when c.DOBDataQuality in (8,9) then -1
              when c.DOB is null
                or c.DOB = '1/1/1900'
                or c.DOB > hn.EntryDate
                or (hn.RelationshipToHoH = 1 and c.DOB = hn.EntryDate)
                or DATEADD(yy, 105, c.DOB) <= hn.EntryDate
                or c.DOBDataQuality is null
                or c.DOBDataQuality not in (1,2) then -1
              when hn.EntryDate >= cd.CohortStart
                and DATEADD(yy, 18, c.DOB) <= hn.EntryDate then 1
              when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 1
              else 0 end as ageStat
            from tmp_Exit ex
            inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
            inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
            inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
            inner join hmis_Client c on c.PersonalID = hn.PersonalID
            ) age on age.PersonalID = hn.PersonalID
          group by ex.EnrollmentID) pop on pop.EnrollmentID = ex.EnrollmentID

        update ex
        set ex.HHAdultAge = ageGroup.AgeGroup
        from
        tmp_Exit ex
        -- CHANGE 9/17/2018 - correct identification of HHAdultAge
        inner join (select adultAges.HoHID, adultAges.EnrollmentID
            , case when max(adultAges.AgeGroup) = 99 then -1
              when max(adultAges.AgeGroup) = 18 then 18
              when max(adultAges.AgeGroup) = 24 then 24
              when max(adultAges.AgeGroup) = 25 then 25
              when max(adultAges.AgeGroup) = 55 then 55
              else -1 end as AgeGroup
          from (select distinct ex.HoHID, hoh.EnrollmentID
              , case when c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or (hn.RelationshipToHoH = 1 and c.DOB = hn.EntryDate)
                  or DATEADD(yy, 105, c.DOB) <= hn.EntryDate
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 99
                when hn.EntryDate >= cd.CohortStart
                  and DATEADD(yy, 55, c.DOB) <= hn.EntryDate then 55
                when hn.EntryDate >= cd.CohortStart
                  and DATEADD(yy, 25, c.DOB) <= hn.EntryDate then 25
                when hn.EntryDate >= cd.CohortStart
                  and DATEADD(yy, 22, c.DOB) <= hn.EntryDate then 24
                when hn.EntryDate >= cd.CohortStart
                  and DATEADD(yy, 18, c.DOB) <= hn.EntryDate then 18
                when DATEADD(yy, 55, c.DOB) <= cd.CohortStart then 55
                when DATEADD(yy, 25, c.DOB) <= cd.CohortStart then 25
                when DATEADD(yy, 22, c.DOB) <= cd.CohortStart then 24
                when DATEADD(yy, 18, c.DOB) <= cd.CohortStart then 18
                else NULL end as AgeGroup
              from tmp_Exit ex
              inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
              inner join hmis_Enrollment hoh on hoh.EnrollmentID = ex.EnrollmentID
              inner join hmis_Enrollment hn on hn.HouseholdID = hoh.HouseholdID
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              ) adultAges
          group by adultAges.HoHID, adultAges.EnrollmentID
            ) ageGroup on ageGroup.EnrollmentID = ex.EnrollmentID
      SQL
    end

    def four_forty_five
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.45 Set Stat for Exit Cohort Households
        *****************************************************************/
        update ex
        set ex.StatEnrollmentID = (select top 1 previous.EnrollmentID
          from hmis_Enrollment previous
          inner join hmis_Exit hx on hx.EnrollmentID = previous.EnrollmentID
            and hx.ExitDate > previous.EntryDate
            and dateadd(dd,730,hx.ExitDate) >= ex.EntryDate
            and hx.ExitDate < ex.ExitDate
          inner join
            --HouseholdIDs with LSA household types
            (select HouseholdID, case
            when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0 then 2
            when AgeStatus/100 > 0 then 99
            when AgeStatus%10 > 0 then 3
            when (AgeStatus/10)%100 > 0 then 1
            else 99 end as HHType
            from
              --HouseholdIDs with age status for household members
              (select hn.HouseholdID
              , sum(case when c.DOBDataQuality in (8,9)
                  or c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                  --age for prior enrollments is always based on EntryDate
                  or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 100
                when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                else 1 end) as AgeStatus
              from hmis_Enrollment hn
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              inner join
                  --HouseholdIDs
                  (select distinct hhinfo.HouseholdID
                  from hmis_Enrollment hhinfo
                  inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                  inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                  inner join hmis_EnrollmentCoC coc on
                    coc.EnrollmentID = hhinfo.EnrollmentID
                    and coc.CoCCode = rpt.ReportCoC
                  where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                      group by hhinfo.HouseholdID, coc.CoCCode
                      ) hoh on hoh.HouseholdID = hn.HouseholdID
                  group by hn.HouseholdID
                  ) hhid) hh on hh.HouseholdID = previous.HouseholdID
              where previous.PersonalID = ex.HoHID and previous.RelationshipToHoH = 1
                and hh.HHType = ex.HHType
              order by hx.ExitDate desc)
        from tmp_Exit ex

        update ex
        set ex.Stat = case when ex.StatEnrollmentID is null then 1
          when dateadd(dd, 15, hx.ExitDate) >= ex.EntryDate then 5
          when hx.Destination in (3,31,19,20,21,26,28,10,11,22,23) then 2
          when hx.Destination in (15,25,4,5,6,7,14,29,1,2,18,27,16,12,13) then 3
          else 4 end
        from tmp_Exit ex
        left outer join hmis_Exit hx on hx.EnrollmentID = ex.StatEnrollmentID
      SQL
    end

    def four_forty_six
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.46 Get Other Enrollments Relevant to Exit Cohort System Path
        *****************************************************************/
        delete from sys_Enrollment
        insert into sys_Enrollment (HoHID, HHType, EnrollmentID, ProjectType
          , EntryDate
          , MoveInDate
          , ExitDate
          , Active)
        select distinct hn.PersonalID, hh.HHType, hn.EnrollmentID, p.ProjectType
          , case when p.TrackingMethod = 3 then null else hn.EntryDate end
          , case when p.ProjectType in (3,13) then hn.MoveInDate else null end
          , case when p.TrackingMethod = 3 then null else hx.ExitDate end
          , case when hn.EnrollmentID = ex.EnrollmentID then 1 else 0 end
        from tmp_Exit ex
        inner join hmis_Enrollment hn on hn.PersonalID = ex.HoHID
          and hn.RelationshipToHoH = 1
        inner join hmis_Exit hx on hx.EnrollmentID = hn.EnrollmentID
          and hx.ExitDate <= ex.ExitDate
        inner join hmis_Project p on p.ProjectID = hn.ProjectID
        inner join (select HouseholdID, case
              --if at least 1 adult and 1 child, HHType = 2
            when AgeStatus%10 > 0 and (AgeStatus/10)%100 > 0
              then 2
            --If not adult/child, any unknown age means HHType = 99
            when AgeStatus/100 > 0
              then 99
            --child only HHType = 3
            when AgeStatus%10 > 0
              then 3
            --adult only HHType = 1
            when (AgeStatus/10)%100 > 0
              then 1
            else 99 end as HHType
            from (select hn.HouseholdID
              , sum(case when c.DOBDataQuality in (8,9)
                  or c.DOB is null
                  or c.DOB = '1/1/1900'
                  or c.DOB > hn.EntryDate
                  or c.DOB = hn.EntryDate and hn.RelationshipToHoH = 1
                  or dateadd(yy, 105, c.DOB) <= hn.EntryDate
                  or c.DOBDataQuality is null
                  or c.DOBDataQuality not in (1,2) then 100
                when dateadd(yy, 18, c.DOB) <= hn.EntryDate then 10
                else 1 end) as AgeStatus
              from hmis_Enrollment hn
              inner join hmis_Client c on c.PersonalID = hn.PersonalID
              inner join (select distinct hhinfo.HouseholdID
                  from hmis_Enrollment hhinfo
                  inner join lsa_Report rpt on hhinfo.EntryDate <= rpt.ReportEnd
                  inner join hmis_Project p on p.ProjectID = hhinfo.ProjectID
                  inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hhinfo.EnrollmentID
                    and coc.CoCCode = rpt.ReportCoC
                  where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
                  group by hhinfo.HouseholdID, coc.CoCCode
                  ) hoh on hoh.HouseholdID = hn.HouseholdID
              group by hn.HouseholdID
              ) hhid) hh on hh.HouseholdID = hn.HouseholdID

        update ex
        set ex.LastInactive = lastDay.inactive
        from tmp_Exit ex
        inner join (select ex.Cohort, ex.HoHID, ex.HHType, max(cal.theDate) as inactive
          from tmp_Exit ex
          inner join ref_Calendar cal on cal.theDate < ex.EntryDate
          left outer join
            --bednights
            (select distinct sn.HoHID
              , sn.HHType as HHType
              , x.Cohort
              , bn.DateProvided as StartDate
              --CHANGE 9/19/2018 correct dateadd 7 days to dateadd 6
              , dateadd(dd,6,bn.DateProvided) as EndDate
            from sys_Enrollment sn
            inner join tmp_Exit x on x.HHType = sn.HHType and x.HoHID = sn.HoHID
              and x.ExitDate >= sn.ExitDate
            inner join hmis_Services bn on bn.EnrollmentID = sn.EnrollmentID
              and bn.RecordType = 200
            where sn.EntryDate is null
            union
            --time in ES/SH/TH or in RRH/PSH but not housed
            select sn.HoHID, sn.HHType, x.Cohort, sn.EntryDate
              , dateadd(dd,6,sn.ExitDate)
            from sys_Enrollment sn
            inner join tmp_Exit x on x.HHType = sn.HHType and x.HoHID = sn.HoHID
              and x.ExitDate >= sn.ExitDate
            where sn.ProjectType in (1,8,2) or sn.MoveInDate is null
            ) padded on padded.HoHID = ex.HoHID and padded.HHType = ex.HHType
              and cal.theDate between padded.StartDate and padded.EndDate
          where padded.HoHID is null
          group by ex.HoHID, ex.HHType, ex.Cohort
          ) lastDay on lastDay.HoHID = ex.HoHID and lastDay.HHType = ex.HHType
            and lastDay.Cohort = ex.Cohort
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.46 Set SystemPath for Exit Cohort Households
        *****************************************************************/
        update ex
        set ex.SystemPath = -1
        from tmp_Exit ex
        inner join hmis_Enrollment hn on hn.EnrollmentID = ex.EnrollmentID
        where (dateadd(dd, 365, hn.MoveInDate) <= ex.ExitDate
            and ex.ExitFrom in (5,6))
          or (ex.ExitFrom = 6 and hn.MoveInDate <= ex.ExitDate)

        update ex
        set ex.SystemPath = case
          when ex.ExitFrom = 1 then 12
          when ex.ExitFrom = 2 then 1
          when ex.ExitFrom = 3 then 2
          when ex.ExitFrom = 4 then 1
          when ex.ExitFrom = 5 then 4
          when ex.ExitFrom = 6 and sn.MoveInDate < cd.CohortStart then 12
          else 8 end
        from tmp_Exit ex
        inner join sys_Enrollment sn on sn.EnrollmentID = ex.EnrollmentID
        inner join tmp_CohortDates cd on cd.Cohort = ex.Cohort
        where dateadd(dd, -1, ex.EntryDate) = ex.LastInactive
          or ex.ExitFrom = 1
          or (ex.ExitFrom = 6 and sn.MoveInDate < cd.CohortStart)

        update ex
        set ex.SystemPath = case ptype.summary
          when 1 then 1
          when 10 then 2
          when 11 then 3
          when 100 then 4
          when 101 then 5
          when 110 then 6
          when 111 then 7
          when 1000 then 8
          when 1001 then 9
          when 1101 then 10
          when 1100 then 11
          else 12 end
        from tmp_Exit ex
        inner join (select ptypes.HoHID, ptypes.HHType, ptypes.Cohort
          , sum(ProjectType) as summary
          from (select distinct ex.HoHID, ex.HHType, ex.Cohort
              , case when rrh.HoHID is not null then 100
                when th.HoHID is not null then 10
                when es.HoHID is not null or nbn.HoHID is not null then 1
                when pshpre.HoHID is not null then 1000
                when rrhpre.HoHID is not null then 13
                else 0 end as ProjectType
            from tmp_Exit ex
            left outer join sys_Enrollment rrh on rrh.ProjectType = 13
              and rrh.HoHID = ex.HoHID and rrh.HHType = ex.HHType
              and rrh.MoveInDate <= ex.ExitDate and rrh.ExitDate > ex.LastInactive
            left outer join sys_Enrollment th on th.ProjectType = 2
              and th.HoHID = ex.HoHID and th.HHType = ex.HHType
              and th.EntryDate <= ex.ExitDate and th.ExitDate > ex.LastInactive
            left outer join sys_Enrollment es on es.ProjectType in (1,8)
              and es.HoHID = ex.HoHID and es.HHType = ex.HHType
              and es.EntryDate <= ex.ExitDate and es.ExitDate > ex.LastInactive
            left outer join sys_Enrollment nbn on nbn.EntryDate is null
              --CHANGE 9/19/2018 CORRECT nbn join from 'rrh.HoHID = ex.HoHID' to reference nbn and not rrh
              and nbn.HoHID = ex.HoHID and rrh.HHType = ex.HHType
            left outer join sys_Enrollment rrhpre on rrhpre.ProjectType = 13
              and rrhpre.HoHID = ex.HoHID and rrhpre.HHType = ex.HHType
              and rrhpre.EntryDate <= ex.ExitDate
                and coalesce(rrhpre.MoveInDate, rrhpre.ExitDate) > ex.LastInactive
            left outer join sys_Enrollment pshpre on pshpre.ProjectType = 3
              and pshpre.HoHID = ex.HoHID and pshpre.HHType = ex.HHType
              and pshpre.EntryDate <= ex.ExitDate
                and coalesce(pshpre.MoveInDate, pshpre.ExitDate) > ex.LastInactive
            ) ptypes
          group by ptypes.HoHID, ptypes.HHType, ptypes.Cohort
          ) ptype on ptype.HoHID = ex.HoHID and ptype.HHType = ex.HHType
            and ptype.Cohort = ex.Cohort
        where ex.SystemPath is null

      SQL
    end

    def four_forty_seven_to_fifty_one
      SqlServerBase.connection.execute (<<~SQL);
        /*****************************************************************
        4.47-49 LSACalculated Population Identifiers

         In the specs, these sections summarize how to select people and
         households in various populations.

         As demonstrated here, queries used to populate LSACalculated in sections 4.50-4.xx
         join to a table called ref_Populations to enable use of a single query for each
         required average and count vs. separate queries for each population.

        4.50 and 4.51 Get Average Days for LOTH

        CHANGE 9/17/2018 ALL INSERT STATEMENTS for Report Rows 1-9 modified to:
          -correct Universe value to -1 (was 1, which is not valid)
          -combine 4.50 and 4.51 by adding SystemPath to ref_Populations
           (script to create/populate ref_Populations has been updated)

        *****************************************************************/
        delete from lsa_Calculated

        --AVERAGE DAYS IN ES/SH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select distinct avg(ESDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 1 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.ESDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (1,3,5,7,9,10,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        -- AVERAGE DAYS IN TH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select distinct avg(lh.THDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 2 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.THDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (2,3,6,7,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS in ES/SH/TH combined
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select distinct avg(lh.ESTDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 3 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.ESTDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (3,7,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS in RRH/PSH Pre-MoveIn
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select distinct avg(lh.RRHPSHPreMoveInDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 4 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.RRHPSHPreMoveInDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS WHILE HOMELESS
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.SystemHomelessDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 5 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.SystemHomelessDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (5,6,7,10,11,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS Not Enrolled in ES/SH/TH/RRH/PSH PROJECTS
        --  and DOCUMENTED HOMELESS BASED ON 3.917
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.Other3917Days) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 6 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.Other3917Days > 0
          and pop.LOTH = 1
          and (lh.SystemPath <> -1 or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS HOMELESS IN ES/SH/TH/RRH/PSH projects +
        -- DAYS DOCUMENTED HOMELESS BASED ON 3.917
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.TotalHomelessDays) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 7 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.TotalHomelessDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath <> -1 or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS HOUSED IN RRH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.RRHHousedDays) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 8 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.RRHHousedDays > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID

        --AVERAGE DAYS Enrolled in ES/SH/TH/RRH/PSH PROJECTS and not Housed in PSH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.SystemDaysNotPSHHoused) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , 9 as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.SystemDaysNotPSHHoused > 0
          and pop.LOTH = 1
          and (lh.SystemPath in (4,5,6,7,10,11,12) or pop.SystemPath is null)
        group by pop.PopID
          , pop.HHType
          , pop.SystemPath
          , lh.ReportID
      SQL
    end

    def four_fifty_two
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.52 Cumulative Length of Time Housed in PSH
        ******************************************************************/
        --Time Housed in PSH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.PSHHousedDays) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID
          , -1 as SystemPath
          --Row 10 = households that exited, 11 = active on the last day
          , case when PSHStatus in (12,22) then 10 else 11 end as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.PSHMoveIn > 0 and lh.PSHStatus > 0
          and pop.Core = 1
        group by pop.PopID
          , pop.HHType
          , case when PSHStatus in (12,22) then 10 else 11 end
          , lh.ReportID
      SQL
    end

    def four_fifty_three
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.53 Length of Time in RRH Projects
        ******************************************************************/
        --Time in RRH not housed
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.RRHPreMoveInDays) as Value
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID
          , -1 as SystemPath
          --Row 14 = all households placed in PH
          , case when lh.RRHMoveIn in (1,2) then 14
            --Row 12 = exited households not placed in PH
            when RRHStatus in (12,22) then 12
            --Row 13 = active households not placed in PH
            else 13 end as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.RRHMoveIn > 0
          and pop.Core = 1
        group by pop.PopID
          , pop.HHType
          , case when lh.RRHMoveIn in (1,2) then 14
            when RRHStatus in (12,22) then 12
            else 13 end
          , lh.ReportID

        --Time housed in RRH
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lh.RRHHousedDays) as Value
          --CHANGE 9/17/2018 - set Universe to -1 (was 1)
          , 1 as Cohort, -1 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID as Population
          , -1 as SystemPath
          --Row 15 = exited households
          , case when RRHStatus in (12,22) then 15
            --Row 16 = active households
            else 16 end as ReportRow
          , lh.ReportID
        from tmp_Household lh
        inner join ref_Populations pop on
          (lh.HHType = pop.HHType or pop.HHType is null)
          and (lh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lh.HHVet = pop.HHVet or pop.HHVet is null)
          and (lh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lh.HHChronic = pop.HHChronic or pop.HHChronic is null)
          and (lh.HHChild = pop.HHChild or pop.HHChild is null)
          and (lh.Stat = pop.Stat or pop.Stat is null)
          and (lh.PSHMoveIn = pop.PSHMoveIn or pop.PSHMoveIn is null)
          and (lh.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lh.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lh.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lh.RRHMoveIn in (1,2)
          and pop.Core = 1
        group by pop.PopID
          , pop.HHType
          , case when RRHStatus in (12,22) then 15
            else 16 end
          , lh.ReportID
      SQL
    end

    def four_fifty_four
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.54 Days to Return/Re-engage by Last Project Type
        ******************************************************************/
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lx.ReturnTime) as Value
          , lx.Cohort,
          case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID as Population
          , -1 as SystemPath
          , lx.ExitFrom + 16 as ReportRow
          , lx.ReportID
        from tmp_Exit lx
        inner join ref_Populations pop on
          (lx.HHType = pop.HHType or pop.HHType is null)
          and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lx.HHVet = pop.HHVet or pop.HHVet is null)
          and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lx.HHParent = pop.HHParent or pop.HHParent is null)
          and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
          and (lx.Stat = pop.Stat or pop.Stat is null)
          and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
        where lx.ReturnTime > 0
          and pop.Core = 1
        group by pop.PopID, lx.ReportID
          , lx.Cohort
          , lx.ExitFrom
          , case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end
          , pop.HHType
      SQL
    end

    def four_fifty_five_and_six
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.55 and 4.56 Days to Return/Re-engage by Population / SystemPath

        CHANGE 9/16/2018 - combine 4.55 and 4.56 for individual system paths
        ******************************************************************/
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lx.ReturnTime) as Value
          , lx.Cohort,
          case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID as Population
          , coalesce(pop.SystemPath, -1)
          , coalesce(pop.SystemPath, 0) + 23 as ReportRow
          , lx.ReportID
        from tmp_Exit lx
        inner join ref_Populations pop on
          (lx.HHType = pop.HHType or pop.HHType is null)
          and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lx.HHVet = pop.HHVet or pop.HHVet is null)
          and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lx.HHParent = pop.HHParent or pop.HHParent is null)
          and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
          and (lx.Stat = pop.Stat or pop.Stat is null)
          and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
          and (lx.SystemPath = pop.SystemPath or pop.SystemPath is null)
        where lx.ReturnTime > 0
          and pop.ReturnSummary = 1
        group by pop.PopID, lx.ReportID
          , lx.Cohort
          , case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end
          , pop.HHType
          , pop.SystemPath
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.56 Average Days to Return/Re-engage for All NOT Housed in PSH on CohortStart

        CHANGE 9/16/2018
          - deleted separate insert for individual system paths
            and combined with 4.55 above
        ******************************************************************/
        --Days to return after any path (total row for by-path avgs--
        --excludes those housed in PSH on cohort start date)
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lx.ReturnTime) as Value
          , lx.Cohort,
          case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID as Population
          , -1 as SystemPath
          , 36 as ReportRow
          , lx.ReportID
        from tmp_Exit lx
        inner join ref_Populations pop on
          (lx.HHType = pop.HHType or pop.HHType is null)
          and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lx.HHVet = pop.HHVet or pop.HHVet is null)
          and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lx.HHParent = pop.HHParent or pop.HHParent is null)
          and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
          and (lx.Stat = pop.Stat or pop.Stat is null)
          and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
        where lx.ReturnTime > 0
          and pop.Core = 1
          and lx.SystemPath between 1 and 12
        group by pop.PopID, lx.ReportID
          , lx.Cohort
          , case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end
          , pop.HHType
      SQL
    end

    def four_fifty_seven
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.57 Days to Return/Re-engage by Exit Destination
        ******************************************************************/
        insert into lsa_Calculated (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select avg(lx.ReturnTime) as Value
          , lx.Cohort,
          case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID as Population
          , -1 as SystemPath
          , case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end as ReportRow
          , lx.ReportID
        from tmp_Exit lx
        inner join ref_Populations pop on
          (lx.HHType = pop.HHType or pop.HHType is null)
          and (lx.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (lx.HHVet = pop.HHVet or pop.HHVet is null)
          and (lx.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (lx.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (lx.HHParent = pop.HHParent or pop.HHParent is null)
          and (lx.AC3Plus = pop.AC3Plus or pop.AC3Plus is null)
          and (lx.Stat = pop.Stat or pop.Stat is null)
          and (lx.HoHRace = pop.HoHRace or pop.HoHRace is null)
          and (lx.HoHEthnicity = pop.HoHEthnicity or pop.HoHEthnicity is null)
        where lx.ReturnTime > 0
          and pop.Core = 1
        group by pop.PopID, lx.ReportID
          , lx.Cohort
          , case when lx.ExitTo between 1 and 6 then 2
            when lx.ExitTo between 7 and 14 then 3 else 4 end
          , pop.HHType
          , case when lx.ExitTo between 1 and 15 then lx.ExitTo + 36 else 52 end
      SQL
    end

    def four_fifty_eight
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.58 Get Dates for Counts by Project ID and Project Type
        ******************************************************************/
        delete from tmp_CohortDates where cohort > 0

        insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
        select 1, rpt.ReportStart, rpt.ReportEnd
        from lsa_Report rpt

        --CHANGE 9/18/2018 - simplify criteria, remove requirement that LSAScope = 1
        insert into tmp_CohortDates (Cohort, CohortStart, CohortEnd)
        select distinct case cal.mm
          when 10 then 10
          when 1 then 11
          when 4 then 12
          else 13 end
          , cal.theDate
          , cal.theDate
        from lsa_Report rpt
        inner join ref_Calendar cal
          on cal.theDate between rpt.ReportStart and rpt.ReportEnd
        where (cal.mm = 10 and cal.dd = 31 and cal.yyyy = year(rpt.ReportStart))
          or (cal.mm = 1 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))
          or (cal.mm = 4 and cal.dd = 30 and cal.yyyy = year(rpt.ReportEnd))
          or (cal.mm = 7 and cal.dd = 31 and cal.yyyy = year(rpt.ReportEnd))

      SQL
    end

    def four_fifty_nine
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.59 Get Counts of People by Project ID and Household Characteristics
        ******************************************************************/
        --Count people in households by ProjectID for:
        --AO/AC/CO/All All: Disabled Adult/HoH, CH Adult/HoH, Adult/HoH Fleeing DV,
        --  and:  AO Youth, AO/AC Vet, AC Youth Parent, CO Parent,
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ProjectID, ReportID)
        select count (distinct an.PersonalID)
          , cd.Cohort, 10 as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID as PopID, -1, 53
          , p.ProjectID, cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID in (0,1,2,3,5,6,7,9,10) and pop.PopType = 1
          and pop.SystemPath is null
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID, pop.HHType

      SQL
    end

    def four_sixty
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.60 Get Counts of People by Project Type and Household Characteristics
        **********************************************************************/
        --Unduplicated count of people in households for each project type
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID)
          , cd.Cohort, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 53
          , cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID between 0 and 10 and pop.PopType = 1
          and pop.SystemPath is null
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID
            , p.ProjectType
            , p.ExportID
            , pop.HHType

        --Unduplicated count of people in households for ES/SH/TH combined
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID)
          , cd.Cohort, 16 as Universe
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 53
          , cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID between 0 and 10 and pop.PopType = 1
          and pop.SystemPath is null
          and ((p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID
            , p.ExportID
            , pop.HHType

      SQL
    end

    def four_sixty_one
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.61 Get Counts of Households by Project ID
        ******************************************************************/
        --Count households
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ProjectID, ReportID)
        select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
          , cd.Cohort, 10
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 54
          , p.ProjectID, cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID in (0,1,2,3,5,6,7,9,10) and pop.PopType = 1
          and pop.SystemPath is null
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID
          , pop.HHType

      SQL
    end

    def four_sixty_two
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.62 Get Counts of Households by Project Type
        ******************************************************************/
        --Unduplicated count households for each project type
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
          , cd.Cohort, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID, -1, 54
          , cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID between 0 and 10 and pop.PopType = 1 and pop.SystemPath is null
          and pop.SystemPath is null
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end, p.ExportID
          , pop.HHType

        --Unduplicated count of households for ES/SH/TH combined
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct ahh.HoHID + cast(ahh.HHType as nvarchar))
          , cd.Cohort, 16 as Universe
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID, -1, 54
          , cast(p.ExportID as int)
        from active_Enrollment an
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHVet = pop.HHVet or pop.HHVet is null)
          and (ahh.HHDisability = pop.HHDisability or pop.HHDisability is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (ahh.HHChronic = pop.HHChronic or pop.HHChronic is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopID between 0 and 10 and pop.PopType = 1 and pop.SystemPath is null
          and pop.SystemPath is null
          and (--for night-by-night ES, count only people with bednights in period
            (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ExportID
          , pop.HHType

      SQL
    end

    def four_sixty_three
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.63 Get Counts of People by ProjectID and Personal Characteristics
        ******************************************************************/
        --Count people with specific characteristic
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ProjectID, ReportID)
        select count (distinct lp.PersonalID)
          , cd.Cohort, 10
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID, -1, 55
          , p.ProjectID, cast(p.ExportID as int)
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
          and (an.AgeGroup = pop.Age or pop.Age is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and (pop.PopID in (3,6) or pop.popID between 145 and 148)
          and pop.PopType = 3
          and pop.ProjectLevelCount = 1
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ProjectID, p.ExportID
          , pop.HHType

      SQL
    end

    def four_sixty_four
      SqlServerBase.connection.execute (<<~SQL);
        /******************************************************************
        4.64 Get Counts of People by Project Type and Personal Characteristics
        ******************************************************************/
        --Count people with specific characteristics for each project type
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct lp.PersonalID)
          , cd.Cohort, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID, -1, 55
          , cast(p.ExportID as int)
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
          and (an.AgeGroup = pop.Age or pop.Age is null)
          and (lp.Gender = pop.Gender or pop.Gender is null)
          and (lp.Race = pop.Race or pop.Race is null)
          and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopType = 3
          and (
             --for RRH and PSH, count only people who are housed in period
            (p.ProjectType in (3,13) and an.MoveInDate <= cd.CohortEnd)
            --for night-by-night ES, count only people with bednights in period
            or (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ProjectType, p.ExportID
          , pop.HHType

        --Count people with specific characteristics for ES/SH/TH combined
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct lp.PersonalID)
          , cd.Cohort, 16
          , coalesce(pop.HHType, 0) as HHType
          , pop.PopID, -1, 55
          , cast(p.ExportID as int)
        from tmp_Person lp
        inner join active_Enrollment an on an.PersonalID = lp.PersonalID
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (ahh.HHFleeingDV = pop.HHFleeingDV or pop.HHFleeingDV is null)
          and (ahh.HHParent = pop.HHParent or pop.HHParent is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
          and (an.AgeGroup = pop.Age or pop.Age is null)
          and (lp.Gender = pop.Gender or pop.Gender is null)
          and (lp.Race = pop.Race or pop.Race is null)
          and (lp.Ethnicity = pop.Ethnicity or pop.Ethnicity is null)
        inner join tmp_CohortDates cd on cd.CohortEnd >= an.EntryDate
            --The date criteria for these counts differs from the general LSA
            --criteria for 'active', which includes those who exited on the start date.
            --Here, at least one bednight in the cohort period is required, so any exit
            --must be at least one day AFTER the start of the cohort period.
            and (cd.CohortStart < an.ExitDate or an.ExitDate is null)
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        where cd.Cohort > 0
          and pop.PopType = 3
          and (
            --for night-by-night ES, count only people with bednights in period
            (p.TrackingMethod = 3
              and bn.DateProvided between cd.CohortStart and cd.CohortEnd)
            or (p.TrackingMethod <> 3 and p.ProjectType in (1,2,8))
            )
        group by cd.Cohort, pop.PopID, p.ExportID
          , pop.HHType

      SQL
    end

    def four_sixty_five
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.65 Get Counts of Bed Nights in Report Period by Project ID
        **********************************************************************/
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ProjectID, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, 10, coalesce(pop.HHType, 0)
          , pop.PopID, -1, 56
          , p.ProjectID
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
          and rrhpsh.theDate >= rpt.ReportStart
          and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
        group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType

      SQL
    end

    def four_sixty_six
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.66 Get Counts of Bed Nights in Report Period by Project Type
        **********************************************************************/
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 56
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
          and rrhpsh.theDate >= rpt.ReportStart
          and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
        group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType, p.ProjectType

        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, 16
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 56
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and (ahh.HHAdultAge = pop.HHAdultAge or pop.HHAdultAge is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (0,1,2) and pop.SystemPath is null and pop.PopType = 1
          and p.ProjectType in (1,8,2)
        group by p.ExportID, pop.PopID, pop.HHType
      SQL
    end

    def four_sixty_seven
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.67 Get Counts of Bed Nights in Report Period by Project ID/Personal Char
        **********************************************************************/
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ProjectID, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, 10, coalesce(pop.HHType, 0)
          , pop.PopID, -1, 57
          , p.ProjectID
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join tmp_Person lp on lp.PersonalID = an.PersonalID
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
          and rrhpsh.theDate >= rpt.ReportStart
          and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (3,6) and pop.PopType = 3
        group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType

      SQL
    end

    def four_sixty_eight
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.68 Get Counts of Bed Nights in Report Period by Project Type/Personal Char
        **********************************************************************/
        --each project type
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(rrhpsh.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, case p.ProjectType
            when 1 then 11
            when 8 then 12
            when 2 then 13
            when 13 then 14
            else 15 end
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 56
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join tmp_Person lp on lp.PersonalID = an.PersonalID
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar rrhpsh on rrhpsh.theDate >= an.MoveInDate
          and rrhpsh.theDate >= rpt.ReportStart
          and rrhpsh.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (3,6) and pop.PopType = 3
        group by p.ProjectID, p.ExportID, pop.PopID, pop.HHType, p.ProjectType

        --ES/SH/TH unduplicated
        insert into lsa_Calculated
          (Value, Cohort, Universe, HHType
          , Population, SystemPath, ReportRow, ReportID)
        select count (distinct an.PersonalID + cast(est.theDate as nvarchar))
          + count (distinct an.PersonalID + cast(bnd.theDate as nvarchar))
          , 1, 16
          , coalesce(pop.HHType, 0)
          , pop.PopID, -1, 56
          , cast(p.ExportID as int)
        from active_Enrollment an
        inner join tmp_Person lp on lp.PersonalID = an.PersonalID
        inner join active_Household ahh on ahh.HouseholdID = an.HouseholdID
        inner join ref_Populations pop on
          (ahh.HHType = pop.HHType or pop.HHType is null)
          and ((lp.CHTime = pop.CHTime and lp.CHTimeStatus = pop.CHTimeStatus)
             or pop.CHTime is null)
          and (lp.DisabilityStatus = pop.DisabilityStatus or pop.DisabilityStatus is null)
          and (lp.VetStatus = pop.VetStatus or pop.VetStatus is null)
        left outer join hmis_Services bn on bn.EnrollmentID = an.EnrollmentID
          and bn.RecordType = 200
        inner join lsa_Project p on p.ProjectID = an.ProjectID
        inner join lsa_Report rpt on rpt.ReportID = cast(p.ExportID as int)
        left outer join ref_Calendar est on est.theDate >= an.EntryDate
          and est.theDate >= rpt.ReportStart
          and est.theDate < coalesce(an.ExitDate, dateadd(dd, 1, rpt.ReportEnd))
          and p.ProjectType in (1,2,8) and
            (p.TrackingMethod <> 3 or p.TrackingMethod is null)
        left outer join ref_Calendar bnd on bnd.theDate = bn.DateProvided
          and bnd.theDate >= rpt.ReportStart and bnd.theDate <= rpt.ReportEnd
        where pop.PopID in (3,6) and pop.PopType = 3
          and p.ProjectType in (1,8,2)
        group by p.ExportID, pop.PopID, pop.HHType

      SQL
    end

    def four_sixty_nine
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.69 Set LSAReport Data Quality Values for Report Period
        **********************************************************************/
        --CHANGE 9/20/2018 - multiple corrections throughout to correct missing
        --parentheses in the WHERE clauses, which were overcounting errors by a lot.
        update rpt
          set UnduplicatedClient1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              where lp.ReportID = rpt.ReportID)
          , UnduplicatedAdult1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              where lp.ReportID = rpt.ReportID
                and lp.Age between 18 and 65)
          , AdultHoHEntry1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65))
          , ClientEntry1 = (select count(distinct n.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment n on n.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID)
          , ClientExit1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and an.ExitDate is not null)
          , Household1 = (select count(distinct an.HouseholdID)
              from tmp_Person lp
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID)
          , HoHPermToPH1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
              inner join hmis_Exit x on x.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and an.RelationshipToHoH = 1
                and an.ProjectType in (3,13)
                and x.Destination in (3,31,19,20,21,26,28,10,11,22,23) )
          , DOB1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              where lp.ReportID = rpt.ReportID
                and an.AgeGroup in (98,99))
          , Gender1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and (c.Gender not in (0,1,2,3,4) or c.Gender is null))
          , Race1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and (coalesce(c.AmIndAKNative,0) + coalesce(c.Asian,0)
                  + coalesce(c.BlackAfAmerican,0) + coalesce(c.NativeHIOtherPacific,0)
                  + coalesce(c.White,0) = 0
                  or c.RaceNone in (8,9,99)))
          , Ethnicity1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and (c.Ethnicity not in (0,1) or c.Ethnicity is null))
          , VetStatus1 = (select count(distinct lp.PersonalID)
              from tmp_Person lp
            --CHANGE 7/9/2018 - add join to active_Enrollment and check for adult AgeGroup
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
                and an.AgeGroup between 18 and 65
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
          , RelationshipToHoH1 = (select count(distinct n.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment n on n.PersonalID = lp.PersonalID
              where lp.ReportID = rpt.ReportID
                and n.RelationshipToHoH not in (1,2,3,4,5)
                  or n.RelationshipToHoH is null)
          , DisablingCond1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
          , LivingSituation1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment an on an.PersonalID = lp.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
          , LengthOfStay1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and an.RelationshipToHoH = 1
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                --CHANGE 9/20/2018 remove 99 from hn.LengthOfStay in (8,9)
                and (hn.LengthOfStay in (8,9) or hn.LengthOfStay is null))
          , HomelessDate1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                and (hn.LivingSituation in (1,16,18,27) and hn.DateToStreetESSH is null)
                  or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11)
                      and hn.DateToStreetESSH is null)
                  or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
                    and hn.LivingSituation in (4,5,6,7,15,24)
                    and hn.DateToStreetESSH is null))
          , TimesHomeless1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                and (hn.TimesHomelessPastThreeYears not between 1 and 4
                  or hn.TimesHomelessPastThreeYears is null))
          , MonthsHomeless1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                and (hn.MonthsHomelessPastThreeYears not between 101 and 113
                or hn.MonthsHomelessPastThreeYears is null))
          , DV1 = (select count(distinct an.EnrollmentID)
              from tmp_Person lp
              inner join hmis_Client c on c.PersonalID = lp.PersonalID
              inner join active_Enrollment an on an.PersonalID = c.PersonalID
              left outer join hmis_HealthAndDV dv on dv.EnrollmentID = an.EnrollmentID
                and dv.DataCollectionStage = 1
              where lp.ReportID = rpt.ReportID
                and (an.RelationshipToHoH = 1 or an.AgeGroup between 18 and 65)
                and (dv.DomesticViolenceVictim not in (0,1)
                    or dv.DomesticViolenceVictim is null
                    or (dv.DomesticViolenceVictim = 1 and
                      (dv.CurrentlyFleeing not in (0,1)
                        or dv.CurrentlyFleeing is null))))
          , Destination1 = (select count(distinct n.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment n on n.PersonalID = lp.PersonalID
              inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and n.ExitDate is not null
                and (x.Destination in (8,9,17,30,99) or x.Destination is null))
          --CHANGE 9/20/2018 - correct NotOneHoH1
          , NotOneHoH1 = (select count(distinct ah.HouseholdID)
              from active_Household ah
              inner join (select an.HouseholdID
                  , count(distinct hn.PersonalID) as hoh
                from active_Enrollment an
                inner join hmis_Enrollment hn on hn.EnrollmentID = an.EnrollmentID
                  and hn.RelationshipToHoH = 1
                group by an.HouseholdID
                ) hoh on hoh.HouseholdID = ah.HouseholdID
              where hoh.hoh <> 1)
          , MoveInDate1 = coalesce((select count(distinct n.EnrollmentID)
              from tmp_Person lp
              inner join active_Enrollment n on n.PersonalID = lp.PersonalID
              inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
              where lp.ReportID = rpt.ReportID
                and n.RelationshipToHoH = 1
                and n.ProjectType in (3,13)
                and x.Destination in (3,31,19,20,21,26,28,10,11,22,23)
                and n.MoveInDate is null), 0)
        from lsa_Report rpt

      SQL
    end

    def four_seventy
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.70 Get Relevant Enrollments for Three Year Data Quality Checks
        **********************************************************************/
        delete from dq_Enrollment
        insert into dq_Enrollment (EnrollmentID, PersonalID, HouseholdID, RelationshipToHoH
          , ProjectType, EntryDate, MoveInDate, ExitDate, Adult, SSNValid)

        select distinct n.EnrollmentID, n.PersonalID, n.HouseholdID, n.RelationshipToHoH
          , p.ProjectType, n.EntryDate, hhinfo.MoveInDate, ExitDate
          , case when c.DOBDataQuality in (8,9)
            or c.DOB is null
            or c.DOB = '1/1/1900'
            or c.DOB > n.EntryDate
            or c.DOB = n.EntryDate and n.RelationshipToHoH = 1
            or dateadd(yy, 105, c.DOB) <= n.EntryDate
            or c.DOBDataQuality is null
            or c.DOBDataQuality not in (1,2) then 99
          when dateadd(yy, 18, c.DOB) <= n.EntryDate then 1
          else 0 end
        , case when c.SSNDataQuality in (8,9) then null
            when SUBSTRING(c.SSN,1,3) in ('000','666')
                or LEN(c.SSN) <> 9
                or SUBSTRING(c.SSN,4,2) = '00'
                or SUBSTRING(c.SSN,6,4) ='0000'
                or c.SSN is null
                or c.SSN = ''
                --UPDATE 9/20/2018 - was "c.SSN not like '[0-9]'" which matched every record
                or c.SSN like '%[^0-9]%'
                or left(c.SSN,1) >= '9'
                or c.SSN in ('123456789','111111111','222222222','333333333','444444444'
                    ,'555555555','777777777','888888888')
              then 0 else 1 end
        from lsa_report rpt
        inner join hmis_Enrollment n on n.EntryDate <= rpt.ReportEnd
        inner join hmis_Project p on p.ProjectID = n.ProjectID
        inner join hmis_Client c on c.PersonalID = n.PersonalID
        left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
          and x.ExitDate >= dateadd(yy, -3, rpt.ReportStart)
        inner join (select distinct hh.HouseholdID, min(hh.MoveInDate) as MoveInDate
          from hmis_Enrollment hh
          inner join lsa_Report rpt on hh.EntryDate <= rpt.ReportEnd
          inner join hmis_Project p on p.ProjectID = hh.ProjectID
          inner join hmis_EnrollmentCoC coc on coc.EnrollmentID = hh.EnrollmentID
            and coc.CoCCode = rpt.ReportCoC
          where p.ProjectType in (1,2,3,8,13) and p.ContinuumProject = 1
          group by hh.HouseholdID
          ) hhinfo on hhinfo.HouseholdID = n.HouseholdID
      SQL
    end

    def four_seventy_one
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.71 Set LSAReport Data Quality Values for Three Year Period
        **********************************************************************/
        update rpt
          set UnduplicatedClient3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n)
          , UnduplicatedAdult3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              where n.Adult = 1)
          , AdultHoHEntry3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              where n.Adult = 1 or n.RelationshipToHoH = 1)
          , ClientEntry3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n)
          , ClientExit3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              where n.ExitDate is not null)
          , Household3 = (select count(distinct n.HouseholdID)
              from dq_Enrollment n)
          , HoHPermToPH3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
              where n.RelationshipToHoH = 1
                and n.ProjectType in (3,13)
                and x.Destination in (3,31,19,20,21,26,28,10,11,22,23))
          ,   NoCoC = (select count (distinct n.HouseholdID)
              from hmis_Enrollment n
              left outer join hmis_EnrollmentCoC coc on
                coc.EnrollmentID = n.EnrollmentID
              inner join hmis_Project p on p.ProjectID = n.ProjectID
                and p.ContinuumProject = 1 and p.ProjectType in (1,2,3,8,13)
              inner join hmis_ProjectCoC pcoc on pcoc.CoCCode = rpt.ReportCoC
              left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
                and x.ExitDate >= dateadd(yy, -3, rpt.ReportStart)
              where n.EntryDate <= rpt.ReportEnd
                and n.RelationshipToHoH = 1
                and coc.CoCCode is null)
          , SSNNotProvided = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              where n.SSNValid is null)
          , SSNMissingOrInvalid = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              where n.SSNValid = 0)
          , ClientSSNNotUnique = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              inner join hmis_Client c on c.PersonalID = n.PersonalID
              inner join hmis_Client oc on oc.SSN = c.SSN
                and oc.PersonalID <> c.PersonalID
              inner join dq_Enrollment dqn on dqn.PersonalID = oc.PersonalID
              where n.SSNValid = 1)
          , DistinctSSNValueNotUnique = (select count(distinct d.SSN)
              from (select distinct c.SSN
                from hmis_Client c
                inner join dq_Enrollment n on n.PersonalID = c.PersonalID
                  and n.SSNValid = 1
                group by c.SSN
                having count(distinct n.PersonalID) > 1) d)
          , DOB3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              where n.Adult = 99)
          , Gender3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              inner join hmis_Client c on c.PersonalID = n.PersonalID
                and (c.Gender not in (0,1,2,3,4) or c.Gender is null))
          , Race3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              inner join hmis_Client c on c.PersonalID = n.PersonalID
              where (coalesce(c.AmIndAKNative,0) + coalesce(c.Asian,0)
                  + coalesce(c.BlackAfAmerican,0) + coalesce(c.NativeHIOtherPacific,0)
                  + coalesce(c.White,0) = 0
                  or c.RaceNone in (8,9,99)))
          , Ethnicity3 = (select count(distinct n.PersonalID)
              from dq_Enrollment n
              inner join hmis_Client c on c.PersonalID = n.PersonalID
              where (c.Ethnicity not in (0,1) or c.Ethnicity is null))
          , VetStatus3 = (select count(distinct c.PersonalID)
              from dq_Enrollment n
              inner join hmis_Client c on c.PersonalID = n.PersonalID
              where n.Adult = 1
                and (c.VeteranStatus not in (0,1) or c.VeteranStatus is null))
          , RelationshipToHoH3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              where  (n.RelationshipToHoH not in (1,2,3,4,5) or n.RelationshipToHoH is null))
          , DisablingCond3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (hn.DisablingCondition not in (0,1) or hn.DisablingCondition is null))
            -- CHANGE 7/9/2018 - correct LivingSituation1 --> LivingSituation3
          , LivingSituation3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (hn.LivingSituation in (8,9,99) or hn.LivingSituation is null))
          , LengthOfStay3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (hn.LengthOfStay in (8,9) or hn.LengthOfStay is null))
          , HomelessDate3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (hn.LivingSituation in (1,16,18,27) and hn.DateToStreetESSH is null)
                  or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (10,11)
                      and hn.DateToStreetESSH is null)
                  or (hn.PreviousStreetESSH = 1 and hn.LengthOfStay in (2,3)
                    and hn.LivingSituation in (4,5,6,7,15,24)
                    and hn.DateToStreetESSH is null))
          , TimesHomeless3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (hn.TimesHomelessPastThreeYears not between 1 and 4
                  or hn.TimesHomelessPastThreeYears is null))
          , MonthsHomeless3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Enrollment hn on hn.EnrollmentID = n.EnrollmentID
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (hn.MonthsHomelessPastThreeYears not between 101 and 113
                or hn.MonthsHomelessPastThreeYears is null))
          , DV3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              left outer join hmis_HealthAndDV dv on dv.EnrollmentID = n.EnrollmentID
                and dv.DataCollectionStage = 1
              where (n.RelationshipToHoH = 1 or n.Adult = 1)
                and (dv.DomesticViolenceVictim not in (0,1)
                    or dv.DomesticViolenceVictim is null
                    or (dv.DomesticViolenceVictim = 1 and
                      (dv.CurrentlyFleeing not in (0,1)
                        or dv.CurrentlyFleeing is null))))
          , Destination3 = (select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
              where n.ExitDate is not null
                and (x.Destination in (8,9,17,30,99) or x.Destination is null))
            --CHANGE 9/20/2018 - correct NotOneHoH3
          , NotOneHoH3 = (select count(distinct n.HouseholdID)
              from dq_Enrollment n
              inner join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
                from hmis_Enrollment hn
                where hn.RelationshipToHoH = 1
                group by hn.HouseholdID
              ) hoh on hoh.HouseholdID = n.HouseholdID
              where hoh.hoh <> 1)
          , MoveInDate3 = coalesce((select count(distinct n.EnrollmentID)
              from dq_Enrollment n
              inner join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
              where n.RelationshipToHoH = 1
                and n.ProjectType in (3,13)
                and x.Destination in (3,31,19,20,21,26,28,10,11,22,23)
                and n.MoveInDate is null), 0)
        from lsa_Report rpt
      SQL
    end

    def four_seventy_two
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.72 Set ReportDate for LSAReport
        **********************************************************************/
        update lsa_Report set ReportDate = getdate()
      SQL
    end
    def four_seventy_three
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        4.73 Select Data for Export
        **********************************************************************/
        -- LSAPerson
        delete from lsa_Person
        insert into lsa_Person (RowTotal
          , Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
          , CHTime, CHTimeStatus, DVStatus
          , HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
          , HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID)
        select count(distinct PersonalID)
          , Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
          , CHTime, CHTimeStatus, DVStatus
          , HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
          , HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID
        from tmp_Person
        group by Age, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
          , CHTime, CHTimeStatus, DVStatus
          , HHTypeEST, HoHEST, HHTypeRRH, HoHRRH, HHTypePSH, HoHPSH
          , HHChronic, HHVet, HHDisability, HHFleeingDV, HHAdultAge, HHParent, AC3Plus, ReportID

        -- LSAHousehold
        delete from lsa_Household
        insert into lsa_Household(RowTotal
          , Stat, ReturnTime, HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
          , HoHRace, HoHEthnicity, HHAdult, HHChild, HHNoDOB, HHAdultAge
          , HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
          , ESDays, THDays, ESTDays
          , ESTGeography, ESTLivingSit, ESTDestination
          , RRHPreMoveInDays, RRHPSHPreMoveInDays, RRHHousedDays, SystemDaysNotPSHHoused
          , RRHGeography, RRHLivingSit, RRHDestination
          , SystemHomelessDays, Other3917Days, TotalHomelessDays
          , PSHGeography, PSHLivingSit, PSHDestination
          , PSHHousedDays, SystemPath, ReportID)
        select count (distinct HoHID + cast(HHType as nvarchar)), Stat
          , case when ReturnTime between 15 and 30 then 30
            when ReturnTime between 31 and 60 then 60
            when ReturnTime between 61 and 180 then 180
            when ReturnTime between 181 and 365 then 365
            when ReturnTime between 366 and 547 then 547
            when ReturnTime >= 548 then 730
            else ReturnTime end
          , HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
          , HoHRace, HoHEthnicity
          , HHAdult, HHChild, HHNoDOB
          , HHAdultAge
          , HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
          , case when ESDays between 1 and 7 then 7
            when ESDays between 8 and 30 then 30
            when ESDays between 31 and 60 then 60
            when ESDays between 61 and 90 then 90
            when ESDays between 91 and 180 then 180
            when ESDays between 181 and 365 then 365
            when ESDays between 366 and 547 then 547
            when ESDays between 548 and 730 then 730
            when ESDays between 731 and 1094 then 1094
            when ESDays > 1094 then 1095
            else ESDays end
          , case when THDays between 1 and 7 then 7
            when THDays between 8 and 30 then 30
            when THDays between 31 and 60 then 60
            when THDays between 61 and 90 then 90
            when THDays between 91 and 180 then 180
            when THDays between 181 and 365 then 365
            when THDays between 366 and 547 then 547
            when THDays between 548 and 730 then 730
            when THDays between 731 and 1094 then 1094
            when THDays > 1094 then 1095
            else THDays end
          , case when ESTDays between 1 and 7 then 7
            when ESTDays between 8 and 30 then 30
            when ESTDays between 31 and 60 then 60
            when ESTDays between 61 and 90 then 90
            when ESTDays between 91 and 180 then 180
            when ESTDays between 181 and 365 then 365
            when ESTDays between 366 and 547 then 547
            when ESTDays between 548 and 730 then 730
            when ESTDays between 731 and 1094 then 1094
            when ESTDays > 1094 then 1095
            else ESTDays end
          , ESTGeography, ESTLivingSit, ESTDestination
          , case when RRHPreMoveInDays between 1 and 7 then 7
            when RRHPreMoveInDays between 8 and 30 then 30
            when RRHPreMoveInDays between 31 and 60 then 60
            when RRHPreMoveInDays between 61 and 90 then 90
            when RRHPreMoveInDays between 91 and 180 then 180
            when RRHPreMoveInDays between 181 and 365 then 365
            when RRHPreMoveInDays between 366 and 547 then 547
            when RRHPreMoveInDays between 548 and 730 then 730
            when RRHPreMoveInDays between 731 and 1094 then 1094
            when RRHPreMoveInDays > 1094 then 1095
            else RRHPreMoveInDays end
          , case when RRHPSHPreMoveInDays between 1 and 7 then 7
            when RRHPSHPreMoveInDays between 8 and 30 then 30
            when RRHPSHPreMoveInDays between 31 and 60 then 60
            when RRHPSHPreMoveInDays between 61 and 90 then 90
            when RRHPSHPreMoveInDays between 91 and 180 then 180
            when RRHPSHPreMoveInDays between 181 and 365 then 365
            when RRHPSHPreMoveInDays between 366 and 547 then 547
            when RRHPSHPreMoveInDays between 548 and 730 then 730
            when RRHPSHPreMoveInDays between 731 and 1094 then 1094
            when RRHPSHPreMoveInDays > 1094 then 1095
            else RRHPSHPreMoveInDays end
          , case when RRHHousedDays between 1 and 7 then 7
            when RRHHousedDays between 8 and 30 then 30
            when RRHHousedDays between 31 and 60 then 60
            when RRHHousedDays between 61 and 90 then 90
            when RRHHousedDays between 91 and 180 then 180
            when RRHHousedDays between 181 and 365 then 365
            when RRHHousedDays between 366 and 547 then 547
            when RRHHousedDays between 548 and 730 then 730
            when RRHHousedDays between 731 and 1094 then 1094
            when RRHHousedDays > 1094 then 1095
            else RRHHousedDays end
          , case when SystemDaysNotPSHHoused between 1 and 7 then 7
            when SystemDaysNotPSHHoused between 8 and 30 then 30
            when SystemDaysNotPSHHoused between 31 and 60 then 60
            when SystemDaysNotPSHHoused between 61 and 90 then 90
            when SystemDaysNotPSHHoused between 91 and 180 then 180
            when SystemDaysNotPSHHoused between 181 and 365 then 365
            when SystemDaysNotPSHHoused between 366 and 547 then 547
            when SystemDaysNotPSHHoused between 548 and 730 then 730
            when SystemDaysNotPSHHoused between 731 and 1094 then 1094
            when SystemDaysNotPSHHoused > 1094 then 1095
            else SystemDaysNotPSHHoused end
          , RRHGeography, RRHLivingSit, RRHDestination
          , case when SystemHomelessDays between 1 and 7 then 7
            when SystemHomelessDays between 8 and 30 then 30
            when SystemHomelessDays between 31 and 60 then 60
            when SystemHomelessDays between 61 and 90 then 90
            when SystemHomelessDays between 91 and 180 then 180
            when SystemHomelessDays between 181 and 365 then 365
            when SystemHomelessDays between 366 and 547 then 547
            when SystemHomelessDays between 548 and 730 then 730
            when SystemHomelessDays between 731 and 1094 then 1094
            when SystemHomelessDays > 1094 then 1095
            else SystemHomelessDays end
          , case when Other3917Days between 1 and 7 then 7
            when Other3917Days between 8 and 30 then 30
            when Other3917Days between 31 and 60 then 60
            when Other3917Days between 61 and 90 then 90
            when Other3917Days between 91 and 180 then 180
            when Other3917Days between 181 and 365 then 365
            when Other3917Days between 366 and 547 then 547
            when Other3917Days between 548 and 730 then 730
            when Other3917Days between 731 and 1094 then 1094
            when Other3917Days > 1094 then 1095
            else Other3917Days end
          , case when TotalHomelessDays between 1 and 7 then 7
            when TotalHomelessDays between 8 and 30 then 30
            when TotalHomelessDays between 31 and 60 then 60
            when TotalHomelessDays between 61 and 90 then 90
            when TotalHomelessDays between 91 and 180 then 180
            when TotalHomelessDays between 181 and 365 then 365
            when TotalHomelessDays between 366 and 547 then 547
            when TotalHomelessDays between 548 and 730 then 730
            when TotalHomelessDays between 731 and 1094 then 1094
            when TotalHomelessDays > 1094 then 1095
            else TotalHomelessDays end
          , PSHGeography, PSHLivingSit, PSHDestination
          --NOTE:  These are different grouping categories from above!
            --CHANGE 9/17/2018 – select -1 (n/a) if not housed in PSH
          , case when PSHMoveIn not in (1,2) then -1
            when PSHHousedDays < 90 then 3
            when PSHHousedDays between 91 and 180 then 6
            when PSHHousedDays between 181 and 365 then 12
            when PSHHousedDays between 366 and 730 then 24
            when PSHHousedDays between 731 and 1095 then 36
            when PSHHousedDays between 1096 and 1460 then 48
            when PSHHousedDays between 1461 and 1825 then 60
            when PSHHousedDays between 1826 and 2555 then 84
            when PSHHousedDays between 2556 and 3650 then 120
            when PSHHousedDays > 3650 then 121
            else PSHHousedDays end
          , SystemPath, ReportID
        from tmp_Household
        group by Stat
          , case when ReturnTime between 15 and 30 then 30
            when ReturnTime between 31 and 60 then 60
            when ReturnTime between 61 and 180 then 180
            when ReturnTime between 181 and 365 then 365
            when ReturnTime between 366 and 547 then 547
            when ReturnTime >= 548 then 730
            else ReturnTime end
          , HHType, HHChronic, HHVet, HHDisability, HHFleeingDV
          , HoHRace, HoHEthnicity
          , HHAdult, HHChild, HHNoDOB
          , HHAdultAge
          , HHParent, ESTStatus, RRHStatus, RRHMoveIn, PSHStatus, PSHMoveIn
          , case when ESDays between 1 and 7 then 7
            when ESDays between 8 and 30 then 30
            when ESDays between 31 and 60 then 60
            when ESDays between 61 and 90 then 90
            when ESDays between 91 and 180 then 180
            when ESDays between 181 and 365 then 365
            when ESDays between 366 and 547 then 547
            when ESDays between 548 and 730 then 730
            when ESDays between 731 and 1094 then 1094
            when ESDays > 1094 then 1095
            else ESDays end
          , case when THDays between 1 and 7 then 7
            when THDays between 8 and 30 then 30
            when THDays between 31 and 60 then 60
            when THDays between 61 and 90 then 90
            when THDays between 91 and 180 then 180
            when THDays between 181 and 365 then 365
            when THDays between 366 and 547 then 547
            when THDays between 548 and 730 then 730
            when THDays between 731 and 1094 then 1094
            when THDays > 1094 then 1095
            else THDays end
          , case when ESTDays between 1 and 7 then 7
            when ESTDays between 8 and 30 then 30
            when ESTDays between 31 and 60 then 60
            when ESTDays between 61 and 90 then 90
            when ESTDays between 91 and 180 then 180
            when ESTDays between 181 and 365 then 365
            when ESTDays between 366 and 547 then 547
            when ESTDays between 548 and 730 then 730
            when ESTDays between 731 and 1094 then 1094
            when ESTDays > 1094 then 1095
            else ESTDays end
          , ESTGeography, ESTLivingSit, ESTDestination
          , case when RRHPreMoveInDays between 1 and 7 then 7
            when RRHPreMoveInDays between 8 and 30 then 30
            when RRHPreMoveInDays between 31 and 60 then 60
            when RRHPreMoveInDays between 61 and 90 then 90
            when RRHPreMoveInDays between 91 and 180 then 180
            when RRHPreMoveInDays between 181 and 365 then 365
            when RRHPreMoveInDays between 366 and 547 then 547
            when RRHPreMoveInDays between 548 and 730 then 730
            when RRHPreMoveInDays between 731 and 1094 then 1094
            when RRHPreMoveInDays > 1094 then 1095
            else RRHPreMoveInDays end
          , case when RRHPSHPreMoveInDays between 1 and 7 then 7
            when RRHPSHPreMoveInDays between 8 and 30 then 30
            when RRHPSHPreMoveInDays between 31 and 60 then 60
            when RRHPSHPreMoveInDays between 61 and 90 then 90
            when RRHPSHPreMoveInDays between 91 and 180 then 180
            when RRHPSHPreMoveInDays between 181 and 365 then 365
            when RRHPSHPreMoveInDays between 366 and 547 then 547
            when RRHPSHPreMoveInDays between 548 and 730 then 730
            when RRHPSHPreMoveInDays between 731 and 1094 then 1094
            when RRHPSHPreMoveInDays > 1094 then 1095
            else RRHPSHPreMoveInDays end
          , case when RRHHousedDays between 1 and 7 then 7
            when RRHHousedDays between 8 and 30 then 30
            when RRHHousedDays between 31 and 60 then 60
            when RRHHousedDays between 61 and 90 then 90
            when RRHHousedDays between 91 and 180 then 180
            when RRHHousedDays between 181 and 365 then 365
            when RRHHousedDays between 366 and 547 then 547
            when RRHHousedDays between 548 and 730 then 730
            when RRHHousedDays between 731 and 1094 then 1094
            when RRHHousedDays > 1094 then 1095
            else RRHHousedDays end
          , case when SystemDaysNotPSHHoused between 1 and 7 then 7
            when SystemDaysNotPSHHoused between 8 and 30 then 30
            when SystemDaysNotPSHHoused between 31 and 60 then 60
            when SystemDaysNotPSHHoused between 61 and 90 then 90
            when SystemDaysNotPSHHoused between 91 and 180 then 180
            when SystemDaysNotPSHHoused between 181 and 365 then 365
            when SystemDaysNotPSHHoused between 366 and 547 then 547
            when SystemDaysNotPSHHoused between 548 and 730 then 730
            when SystemDaysNotPSHHoused between 731 and 1094 then 1094
            when SystemDaysNotPSHHoused > 1094 then 1095
            else SystemDaysNotPSHHoused end
          , RRHGeography, RRHLivingSit, RRHDestination
          , case when SystemHomelessDays between 1 and 7 then 7
            when SystemHomelessDays between 8 and 30 then 30
            when SystemHomelessDays between 31 and 60 then 60
            when SystemHomelessDays between 61 and 90 then 90
            when SystemHomelessDays between 91 and 180 then 180
            when SystemHomelessDays between 181 and 365 then 365
            when SystemHomelessDays between 366 and 547 then 547
            when SystemHomelessDays between 548 and 730 then 730
            when SystemHomelessDays between 731 and 1094 then 1094
            when SystemHomelessDays > 1094 then 1095
            else SystemHomelessDays end
          , case when Other3917Days between 1 and 7 then 7
            when Other3917Days between 8 and 30 then 30
            when Other3917Days between 31 and 60 then 60
            when Other3917Days between 61 and 90 then 90
            when Other3917Days between 91 and 180 then 180
            when Other3917Days between 181 and 365 then 365
            when Other3917Days between 366 and 547 then 547
            when Other3917Days between 548 and 730 then 730
            when Other3917Days between 731 and 1094 then 1094
            when Other3917Days > 1094 then 1095
            else Other3917Days end
          , case when TotalHomelessDays between 1 and 7 then 7
            when TotalHomelessDays between 8 and 30 then 30
            when TotalHomelessDays between 31 and 60 then 60
            when TotalHomelessDays between 61 and 90 then 90
            when TotalHomelessDays between 91 and 180 then 180
            when TotalHomelessDays between 181 and 365 then 365
            when TotalHomelessDays between 366 and 547 then 547
            when TotalHomelessDays between 548 and 730 then 730
            when TotalHomelessDays between 731 and 1094 then 1094
            when TotalHomelessDays > 1094 then 1095
            else TotalHomelessDays end
          , PSHGeography, PSHLivingSit, PSHDestination
          , case when PSHMoveIn not in (1,2) then -1
            when PSHHousedDays < 90 then 3
            when PSHHousedDays between 91 and 180 then 6
            when PSHHousedDays between 181 and 365 then 12
            when PSHHousedDays between 366 and 730 then 24
            when PSHHousedDays between 731 and 1095 then 36
            when PSHHousedDays between 1096 and 1460 then 48
            when PSHHousedDays between 1461 and 1825 then 60
            when PSHHousedDays between 1826 and 2555 then 84
            when PSHHousedDays between 2556 and 3650 then 120
            when PSHHousedDays > 3650 then 121
            else PSHHousedDays end
          , SystemPath, ReportID

        -- LSAExit
        delete from lsa_Exit
        insert into lsa_Exit (RowTotal
          , Cohort, Stat, ExitFrom, ExitTo, ReturnTime, HHType
          , HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
          , HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID)
        select count (distinct HoHID + cast(HHType as nvarchar))
          , Cohort, Stat, ExitFrom, ExitTo
          , case when ReturnTime between 15 and 30 then 30
            when ReturnTime between 31 and 60 then 60
            when ReturnTime between 61 and 180 then 180
            when ReturnTime between 181 and 365 then 365
            when ReturnTime between 366 and 547 then 547
            when ReturnTime >= 548 then 730
            else ReturnTime end
          , HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
          , HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID
        from tmp_Exit
        group by Cohort, Stat, ExitFrom, ExitTo
          , case when ReturnTime between 15 and 30 then 30
            when ReturnTime between 31 and 60 then 60
            when ReturnTime between 61 and 180 then 180
            when ReturnTime between 181 and 365 then 365
            when ReturnTime between 366 and 547 then 547
            when ReturnTime >= 548 then 730
            else ReturnTime end
          , HHType, HHVet, HHDisability, HHFleeingDV, HoHRace, HoHEthnicity
          , HHAdultAge, HHParent, AC3Plus, SystemPath, ReportID
      SQL
    end
  end
end
# SqlServerBase.connection.execute (<<~SQL);
# /**********************************************************************
# 5.3 Create Stored Procedure – Person-Level Demographics Report Output
# (Optional; no display of LSA summary data is required in HMIS applications at this time.)
# **********************************************************************/
# /*
# DATE:  5/30/2018

# This will produce the following demographic report tables,
# depending on the @rptTable parameter:
# Age, Gender, Race, Ethnicity, VetStatus, DVStatus

# It will generate results for the following populations,
# depending on the @popID and @hhtype parameters:

# PopID HHType  Population
# 0 0   All
# 0 1   AO Households
# 0 2   AC Households
# 0 3   CO Households
# 1 1   AO Youth Household 18-21
# 2 1   AO Youth Household 22-24
# 3 1   AO Veteran Household
# 3 2   AC Veteran Household
# 4 1   AO Non-Veteran 25+ Household
# 6 1-3   Household with Chronically Homeless Adult/HoH
# 9 2   AC Parenting Youth Household 18-24
# 10  3   Parenting Child Household
# */
# DROP PROCEDURE IF EXISTS [dbo].[sp_lsaPersonDemographics];
# SQL
# SqlServerBase.connection.execute (<<~SQL);
# CREATE PROCEDURE [dbo].[sp_lsaPersonDemographics]
# @popID int
# , @hhtype int
# , @rptTable varchar(12)
# AS
# BEGIN
# select val.textValue as Category
# , EST = coalesce((select sum(RowTotal)
# from lsa_Person est
# where est.HHTypeEST <> -1
# and (@hhtype = 0
#   or cast(est.HHTypeEST as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 1 or est.HHAdultAge = 18)
# and (@popID <> 2 or est.HHAdultAge = 24)
# and (@popID <> 3
#   or cast(est.HHVet as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 4 or (est.HHAdultAge in (25,55)
#   and cast(est.HHVet as varchar) not like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 6
#   or cast(est.HHChronic as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 9 or (est.HHAdultAge in (18,24)
#   and cast(est.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 10
#   or cast(est.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and val.intValue = case when @rptTable = 'Age' then est.Age
#     when @rptTable = 'Gender' then est.Gender
#     when @rptTable = 'Race' then est.Race
#     when @rptTable = 'Ethnicity' then est.Ethnicity
#     when @rptTable = 'VeteranStatus' then est.VetStatus
#     when @rptTable = 'DVStatus' then est.DVStatus
#     else null end), 0)
# , RRH = coalesce((select sum(RowTotal)
# from lsa_Person rrh
# where rrh.HHTypeRRH <> -1
# and (@hhtype = 0
#   or cast(rrh.HHTypeRRH as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 1 or rrh.HHAdultAge = 18)
# and (@popID <> 2 or rrh.HHAdultAge = 24)
# and (@popID <> 3
#   or cast(rrh.HHVet as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 4 or (rrh.HHAdultAge in (25,55)
#   and cast(rrh.HHVet as varchar) not like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 6
#   or cast(rrh.HHChronic as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 9 or (rrh.HHAdultAge in (18,24)
#   and cast(rrh.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 10
#   or cast(rrh.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and val.intValue = case when @rptTable = 'Age' then rrh.Age
#     when @rptTable = 'Gender' then rrh.Gender
#     when @rptTable = 'Race' then rrh.Race
#     when @rptTable = 'Ethnicity' then rrh.Ethnicity
#     when @rptTable = 'VeteranStatus' then rrh.VetStatus
#     when @rptTable = 'DVStatus' then rrh.DVStatus
#     else null end), 0)
# , PSH = coalesce((select sum(RowTotal)
# from lsa_Person psh
# where psh.HHTypePSH <> -1
# and (@hhtype = 0
#   or cast(psh.HHTypePSH as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 1 or psh.HHAdultAge = 18)
# and (@popID <> 2 or psh.HHAdultAge = 24)
# and (@popID <> 3
#   or cast(psh.HHVet as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 4 or (psh.HHAdultAge in (25,55)
#   and cast(psh.HHVet as varchar) not like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 6
#   or cast(psh.HHChronic as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and (@popID <> 9 or (psh.HHAdultAge in (18,24)
#   and cast(psh.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%'))
# and (@popID <> 10
#   or cast(psh.HHParent as varchar) like '%' + cast(@hhtype as varchar) + '%')
# and val.intValue = case when @rptTable = 'Age' then psh.Age
#     when @rptTable = 'Gender' then psh.Gender
#     when @rptTable = 'Race' then psh.Race
#     when @rptTable = 'Ethnicity' then psh.Ethnicity
#     when @rptTable = 'VeteranStatus' then psh.VetStatus
#     when @rptTable = 'DVStatus' then psh.DVStatus
#     else null end), 0)
# from ref_lsaValues val
# inner join ref_lsaColumns col on col.ColumnNumber = val.ColumnNumber
# and col.FileNumber = val.FileNumber
# inner join ref_lsaFiles f on f.FileNumber = val.FileNumber
# where col.ColumnName = @rptTable
# and f.FileName = 'LSAPerson'
# and val.intValue <> -1
# order by val.intValue

# END
# SQL