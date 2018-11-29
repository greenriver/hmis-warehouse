# require_relative 'sql_server_base'
require Rails.root.join('lib/rds_sql_server/sql_server_base').to_s
module LsaSqlServer
  class LSAQueries
    attr_accessor :project_ids

    # loop through each section and verify that the expected section exists and has some content
    def validate_file
      steps.each do |step|
        validate_step step
      end
    end

    def steps
      @steps ||= [
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
        :four_twenty_three,
        :four_twenty_four_and_five,
        :four_twenty_six,
        :four_twenty_seven,
        :four_twenty_eight_a,
        :four_twenty_eight_b,
        :four_twenty_eight_c,
        :four_twenty_eight_d,
        :four_twenty_nine_a,
        :four_twenty_nine_b,
        :four_twenty_nine_c,
        :four_twenty_nine_d,
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
        :four_forty_one_and_two,
        :four_forty_three,
        :four_forty_four,
        :four_forty_five,
        :four_forty_six,
        :four_forty_seven_to_fifty_one,
        :four_fifty_two,
        :four_fifty_three,
        :four_fifty_four,
        :four_fifty_five,
        :four_fifty_six,
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

    def exists_in_code? key
      code.scan(/(?=#{Regexp.escape(key)})/).count == 1
    end

    def execute_lsa_query key
      SqlServerBase.connection.execute(query_for(key))
    end

    def run_query step
      key = send(step)
      execute_lsa_query(key)
    end

    def validate_step step
      # TODO: this may want to call query_for key and then check query length.  Currently it is valid, even if finding a query fails
      key = send(step)
      raise "Unable to find section (or found multiple): #{key}" if ! exists_in_code? key
      return true
    end

    def query_for key
      ss = StringScanner.new(code)

      # find the first instance of the key
      ss.skip_until(start_regex(key))
      # jump to the end of the comment
      ss.skip_until(end_of_comment)
      # grab the section up until the next comment, removing the comment
      query = ss.scan_until(/#{Regexp.escape(stop_sequence)}/).gsub(stop_sequence, '')
      query = "/** #{key} **/" + query
    end

    def start_regex key
      /\/\*+\n^#{Regexp.escape(key)}.*\n/
    end

    def end_of_comment
      /\*+\//
    end

    def stop_sequence
      '/********************************'
    end

    def code
      @code ||= File.read('lib/rds_sql_server/lsa/fy2018/LSASampleCode.sql')
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
      # Limit the projects that are reported to those selected
      if project_ids.present?
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
            and hp.ProjectID in(#{project_ids.join(',')})
        SQL
      else
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
    end

    def four_three
      '4.3 Get Organization Records / lsa_Organization'
    end

    def four_four
      '4.4 Get Funder Records / lsa_Funder'
    end

    def four_five
      '4.5 Get Inventory Records / lsa_Inventory'
    end

    def four_six
      '4.6 Get Geography Records / lsa_Geography'
    end

    def four_seven
      '4.7 Get Active Household IDs'
    end

    def four_eight
      '4.8 Get Active Enrollments and Associated AgeDates'
    end

    def four_nine
      '4.9 Set Age Group for Each Active Enrollment'
    end

    def four_ten
      '4.10 Set HHType for Active HouseholdIDs '
    end

    def four_eleven
      '4.11 Get Active Clients for tmp_Person '
    end

    def four_twelve
      '4.12 Set Demographic Values in tmp_Person'
    end

    def four_thirteen
      '4.13 Get Chronic Homelessness Date Range for Each Head of Household/Adult'
    end

    def four_fourteen
      '4.14 Get Enrollments Relevant to Chronic Homelessness'
    end

    def four_fifteen
      '4.15 Get Dates to Exclude from Counts of ES/SH/Street Days'
    end

    def four_sixteen
      '4.16 Get Dates to Include in Counts of ES/SH/Street Days'
    end

    def four_seventeen
      '4.17 Get ES/SH/Street Episodes'
    end

    def four_eighteen
      '4.18 Set Initial CHTime and CHTimeStatus Values'
    end

    def four_nineteen
      '4.19 Update Selected CHTime and CHTimeStatus Values'
    end

    def four_twenty
      '4.20 Set tmp_Person Project Group / Household Type Identifiers'
    end

    def four_twenty_one
      '4.21 Set tmp_Person Head of Household Identifiers for Each Project Group'
    end

    def four_twenty_two
      '4.22 Set Population Identifiers for Active HouseholdIDs'
    end

    def four_twenty_three
      '4.23 Set tmp_Person Population Identifiers from Active Households'
    end

    def four_twenty_four_and_five
      '4.24-25 Get Unique Households and Population Identifiers for tmp_Household'
    end

    def four_twenty_six
      '4.26 Set tmp_Household Project Group Status Indicators'
    end

    def four_twenty_seven
      '4.27 Set tmp_Household RRH and PSH Move-In Status Indicators'
    end

    def four_twenty_eight_a
      '4.28.a Get Most Recent Enrollment in Each ProjectGroup for HoH'
    end

    def four_twenty_eight_b
      '4.28.b Set tmp_Household Geography for Each Project Group'
    end

    def four_twenty_eight_c
      '4.28.c Set tmp_Household Living Situation for Each Project Group'
    end

    def four_twenty_eight_d
      '4.28.d Set tmp_Household Destination for Each Project Group'
    end

    def four_twenty_nine_a
      '4.29.a Get Earliest EntryDate from Active Enrollments'
   end
   def four_twenty_nine_b
      '4.29.b Get EnrollmentID for Latest Exit in Two Years Prior to FirstEntry'
    end
    def four_twenty_nine_c
      '4.29.c Set System Engagement Status for tmp_Household'
    end
    def four_twenty_nine_d
      '4.29.d Set ReturnTime for tmp_Household'
    end

    def four_thirty
      '4.30 Get Days In RRH Pre-Move-In'
    end

    def four_thirty_one
      '4.31 Get Dates Housed in PSH or RRH'
    end

    def four_thirty_two
      '4.32 Get Enrollments Relevant to Last Inactive Date and Other System Use Days'
    end

    def four_thirty_three
      '4.33 Get Last Inactive Date'
    end

    def four_thirty_four
      '4.34 Get Dates of Other System Use'
    end

    def four_thirty_five
      '4.35 Get Other Dates Homeless from 3.917 Living Situation'
    end

    def four_thirty_six
      '4.36 Set System Use Days for LSAHousehold'
    end

    def four_thrity_seven
      '4.37 Update ESTStatus and RRHStatus'
    end

    def four_thirty_eight
      '4.38 Set SystemPath for LSAHousehold'
    end

    def four_thirty_nine
      '4.39 Get Exit Cohort Dates'
    end

    def four_forty
      '4.40 Get Exit Cohort Members and Enrollments'
    end

    def four_forty_one_and_two
      '4.41 Get EnrollmentIDs for Exit Cohort Households'
    end

    def four_forty_three
      '4.43 Set ReturnTime for Exit Cohort Households'
    end

    def four_forty_four
      '4.44 Set Population Identifiers for Exit Cohort Households'
    end

    def four_forty_five
      '4.45 Set Stat for Exit Cohort Households'
    end

    def four_forty_six
      '4.46 Set System Path for Exit Cohort Households'
    end

    def four_forty_seven_to_fifty_one
      '4.47-49 LSACalculated Population Identifiers'
    end

    def four_fifty_two
      '4.52 Cumulative Length of Time Housed in PSH'
    end

    def four_fifty_three
      '4.53 Length of Time in RRH Projects'
    end

    def four_fifty_four
      '4.54 Days to Return/Re-engage by Last Project Type'
    end

    def four_fifty_five
      '4.55 and 4.56 Days to Return/Re-engage by Population / SystemPath'
    end

    def four_fifty_six
      '4.56 Average Days to Return/Re-engage for All NOT Housed in PSH on CohortStart'
    end

    def four_fifty_seven
      '4.57 Days to Return/Re-engage by Exit Destination'
    end

    def four_fifty_eight
      '4.58 Get Dates for Counts by Project ID and Project Type'
    end

    def four_fifty_nine
      '4.59 Get Counts of People by Project ID and Household Characteristics'
    end

    def four_sixty
      '4.60 Get Counts of People by Project Type and Household Characteristics'
    end

    def four_sixty_one
      '4.61 Get Counts of Households by Project ID'
    end

    def four_sixty_two
      '4.62 Get Counts of Households by Project Type'
    end

    def four_sixty_three
      '4.63 Get Counts of People by ProjectID and Personal Characteristics'
    end

    def four_sixty_four
      '4.64 Get Counts of People by Project Type and Personal Characteristics'
    end

    def four_sixty_five
      '4.65 Get Counts of Bed Nights in Report Period by Project ID'
    end

    def four_sixty_six
      '4.66 Get Counts of Bed Nights in Report Period by Project Type'
    end

    def four_sixty_seven
      '4.67 Get Counts of Bed Nights in Report Period by Project ID/Personal Char'
    end

    def four_sixty_eight
      '4.68 Get Counts of Bed Nights in Report Period by Project Type/Personal Char'
    end

    def four_sixty_nine
      '4.69 Set LSAReport Data Quality Values for Report Period'
    end

    def four_seventy
      '4.70 Get Relevant Enrollments for Three Year Data Quality Checks'
    end

    def four_seventy_one
      '4.71 Set LSAReport Data Quality Values for Three Year Period'
    end

    def four_seventy_two
      '4.72 Set ReportDate for LSAReport'
    end

    def four_seventy_three
      '4.73 Select Data for Export'
    end
  end
end
