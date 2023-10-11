###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionFour < Base
    QUESTION_NUMBER = 'Question 4'.freeze

    TABLE_HEADER = [
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

    HMIS_SOFTWARE_NAME = 'OpenPath HMIS Warehouse'.freeze

    def self.table_descriptions
      {
        'Question 4' => 'HMIS Information',
        'Q4a' => 'Project Identifiers in HMIS',
      }.freeze
    end

    def detect_ce_participation(project)
      # FIXME: this probably isn't right
      # Column G should show the response to 2.09.1 effective as of the [report end date]. This element is a transactional data element, and only the most recent value for the report period is displayed.
      records = project.ce_participations.filter do |record|
        start = record.CEParticipationStatusStartDate || 100.years.ago
        stop = record.CEParticipationStatusEndDate || 100.years.from_now
        @report.start_date.between?(start, stop)
      end
      records = records.sort_by do |record|
        [record.DateUpdated, record.id]
      end
      records.last
    end

    private def q4_project_identifiers
      table_name = 'Q4a'
      @report.universe(QUESTION_NUMBER)

      project_rows = []

      cell_columns = ('A'..'O').to_a
      q4_project_scope.order(ProjectName: :asc).preload(:ce_participations).find_each.with_index do |project, i|
        cell_row = i + 2

        ce_participation = detect_ce_participation(project)
        project_row = [
          project.organization&.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.computed_project_type,
          # RRH Subtype
          (project.RRHSubType == 13 ? 1 : 2),
          # Coordinated Entry Access Point
          ce_participation&.AccessPoint,
          # (If 2.02.6 =6 or (13 and 2.02.6A = 1)), then 0 or 1
          (project.computed_project_type == 6 || (project.computed_project_type == 13 && project.RRHSubType == 1) ? project.ResidentialAffiliation : 0),
          if project.computed_project_type == 6 && project.ResidentialAffiliation == 1 then project.residential_affiliations.map(&:ResProjectID).join(', ') else ' ' end,
          project.project_cocs.map(&:effective_coc_code).join(', '),
          project.project_cocs.map(&:effective_geocode).join(', '),
          if project.VictimServicesProvider.present? then project.VictimServicesProvider else 0 end,
          HMIS_SOFTWARE_NAME,
          @report.start_date,
          @report.end_date,
        ]
        # Note for count
        project_rows << project_row

        project_row.each_with_index do |value, column_index|
          cell_name = cell_columns[column_index] + cell_row.to_s
          @report.answer(question: table_name, cell: cell_name).update(summary: value)
        end

        # Note cells P and Q (active clients and active households)
        cell = "P#{cell_row}"
        answer = @report.answer(question: table_name, cell: cell)
        members = universe.members.where(a_t[:project_id].eq(project.id))
        answer.add_members(members)
        answer.update(summary: members.count)

        cell = "Q#{cell_row}"
        answer = @report.answer(question: table_name, cell: cell)
        members = universe.members.where(hoh_clause).where(a_t[:project_id].eq(project.id))
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: [],
        first_column: 'A',
        last_column: 'Q',
        first_row: 2,
        last_row: project_rows.size + 1,
      }
      @report.answer(question: table_name).update(metadata: metadata)
    end

    private def q4_project_scope
      GrdaWarehouse::Hud::Project.where(id: @report.project_ids)
    end
  end
end
