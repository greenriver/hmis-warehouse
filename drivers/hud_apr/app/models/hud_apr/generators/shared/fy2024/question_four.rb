###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionFour < Base
    QUESTION_NUMBER = 'Question 4'.freeze

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

    HMIS_SOFTWARE_NAME = 'OpenPath HMIS Warehouse'.freeze

    def self.table_descriptions
      {
        'Question 4' => 'HMIS Information',
        'Q4a' => 'Project Identifiers in HMIS',
      }.freeze
    end

    def detect_ce_participation(project)
      # Column G should show the response to 2.09.1 effective as of the [report end date]. This element is a transactional data element, and only the most recent value for the report period is displayed.
      records = project.ce_participations.filter do |record|
        start = record.CEParticipationStatusStartDate || 100.years.ago
        stop = record.CEParticipationStatusEndDate || Date.current
        @report.end_date.between?(start, stop)
      end
      records = records.sort_by do |record|
        [record.DateUpdated, record.id]
      end
      records.last
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
          (ce_participation&.AccessPoint || 0),
          # (If 2.02.6 =6 or (13 and 2.02.6A = 1)), then 0 or 1
          (project.ProjectType == 6 || (project.ProjectType == 13 && project.RRHSubType == 1) ? project.ResidentialAffiliation : 0),
          if project.ProjectType == 6 && project.ResidentialAffiliation == 1 then project.residential_affiliations.map(&:ResProjectID).join(', ') else ' ' end,
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
