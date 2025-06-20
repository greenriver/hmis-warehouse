###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026
  class QuestionFour < Base
    QUESTION_NUMBER = 'Question 4'

    def table_header
      [
        'Organization Name',
        'Organization ID',
        'Project Name',
        'Project ID',
        'HMIS Project Type',
        'RRH Subtype',
        'Coordinated Entry Access Point',
        'Affiliated with a residential project',
        'Project IDs of affiliations',
        'CoC Number',
        'Geocode',
        'Victim Service Provider',
        'HMIS Software Name',
        'Report Start Date',
        'Report End Date',
        'Total Active Clients',
        'Total Active Households',
      ].freeze
    end

    HMIS_SOFTWARE_NAME = 'OpenPath HMIS Warehouse'

    def self.table_descriptions
      {
        'Question 4' => 'HMIS Information',
        'Q4a' => 'Project Identifiers in HMIS',
      }.freeze
    end

    # 5.	Column G should show the response to 2.09.1 effective as of the project’s [operating end date] if [operating end date] >= [report start date] and [operating end date] < [report end date]. If the [operating end date] does not meet that criteria, use the response to 2.09.1 effective as of the [report end date]. This element is a transactional data element, and only the most recent value for the report period is displayed.
    def detect_ce_participation(project)
      # Determine the effective date based on project's operating end date
      effective_date = if project.operating_end_date.present? &&
                          project.operating_end_date >= @report.start_date &&
                          project.operating_end_date < @report.end_date
        project.operating_end_date
      else
        @report.end_date
      end

      # Find all records that were active at the effective date
      records = project.ce_participations.filter do |record|
        start = record.CEParticipationStatusStartDate || @report.start_date
        stop = record.CEParticipationStatusEndDate || @report.end_date
        effective_date.between?(start, stop)
      end

      # Sort by:
      # 1. Most recent CEParticipationStatusEndDate (primary)
      # 2. Most recent CEParticipationStatusStartDate (secondary)
      # 3. Most recent DateUpdated (tertiary)
      # 4. Record ID (quaternary)
      records = records.sort_by do |record|
        # NOTE: converting to time so we can compare integers, but using safe navigation to avoid nil errors
        # and nil.to_i returns 0
        [
          -record.CEParticipationStatusEndDate&.to_time.to_i, # Negative for descending order
          -record.CEParticipationStatusStartDate&.to_time.to_i,
          -record.DateUpdated.to_i,
          record.id,
        ]
      end
      records.first
    end

    private def q4_project_identifiers
      @report.universe(QUESTION_NUMBER)
      headers = table_header.zip(('A'..'Q').to_a)

      question_sheet(question: 'Q4a') do |sheet|
        headers.each { |label, col| sheet.add_header(col: col, label: label) }
        # Sorted to match test kit output, doesn't matter for submission
        q4_project_scope.order(ProjectName: :desc).preload(:ce_participations).each do |project|
          project_row(sheet, project)
        end
      end
    end

    def project_row(sheet, project)
      sheet.append_row(label: project.organization&.OrganizationName) do |row|
        ce_participation = detect_ce_participation(project)
        [
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.ProjectType,
          project.RRHSubType,
          # Coordinated Entry Access Point
          ce_participation&.AccessPoint || 0,
          # (If 2.02.6 =6 or (13 and 2.02.6A = 1)), then 0 or 1
          (project.ProjectType == 6 || (project.ProjectType == 13 && project.RRHSubType == 1) ? (project.ResidentialAffiliation || 0) : 0),
          if project.ProjectType == 6 && project.ResidentialAffiliation == 1 then project.residential_projects.map(&:ProjectID).join(', ') else ' ' end,
          project.project_cocs.map(&:effective_coc_code).join(', '),
          project.project_cocs.map(&:effective_geocode).join(', '),
          if project.VictimServicesProvider.present? then project.VictimServicesProvider else 0 end,
          HMIS_SOFTWARE_NAME,
          @report.start_date,
          @report.end_date,
        ].each do |value|
          row.append_cell_value(value: value)
        end

        # Note cells P and Q (active clients and active households)
        row.append_cell_members(members: universe.members.where(a_t[:project_id].eq(project.id)))
        row.append_cell_members(members: universe.members.where(hoh_clause).where(a_t[:project_id].eq(project.id)))
      end
    end

    private def q4_project_scope
      GrdaWarehouse::Hud::Project.where(id: @report.project_ids)
    end
  end
end
