###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2023
  class QuestionFour < Base
    QUESTION_NUMBER = 'Question 4'.freeze

    TABLE_HEADER = [
      'Organization Name',
      'Organization ID',
      'Project Name',
      'Project ID',
      'HMIS Project Type',
      'Method for Tracking ES',
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

    private def q4_project_identifiers
      table_name = 'Q4a'
      @report.universe(QUESTION_NUMBER)

      project_rows = []

      cell_columns = ('A'..'N').to_a
      q4_project_scope.order(ProjectName: :asc).find_each.with_index do |project, i|
        cell_row = i + 2

        project_row = [
          project.organization&.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.computed_project_type,
          if project.computed_project_type == 1 then project.TrackingMethod else 0 end,
          if project.computed_project_type == 6 then project.ResidentialAffiliation else 0 end,
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

        # Note cells O and P (active clients and active households)
        cell = "O#{cell_row}"
        answer = @report.answer(question: table_name, cell: cell)
        members = universe.members.where(a_t[:project_id].eq(project.id))
        answer.add_members(members)
        answer.update(summary: members.count)

        cell = "P#{cell_row}"
        answer = @report.answer(question: table_name, cell: cell)
        members = universe.members.where(hoh_clause).where(a_t[:project_id].eq(project.id))
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: [],
        first_column: 'A',
        last_column: 'P',
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
