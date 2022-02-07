###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
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

      GrdaWarehouse::Hud::Project.find(@report.project_ids).each do |project|
        project_row = [
          project.organization.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.computed_project_type,
          if project.computed_project_type == 1 then project.TrackingMethod else 0 end,
          if project.computed_project_type == 6 then project.ResidentialAffiliation else 0 end,
          if project.computed_project_type == 6 && project.ResidentialAffiliation == 1 then project.residential_affiliations.map(&:ProjectID).join(', ') else ' ' end,
          project.project_cocs.map(&:effective_coc_code).join(', '),
          project.project_cocs.map(&:effective_geocode).join(', '),
          if project.VictimServicesProvider.present? then project.VictimServicesProvider else 0 end,
          HMIS_SOFTWARE_NAME,
          @report.start_date,
          @report.end_date,
        ]
        project_rows << project_row
      end

      cell_columns = ('A'..'N').to_a
      project_rows.each_with_index do |row, row_index|
        row.each_with_index do |value, column_index|
          cell_name = cell_columns[column_index] + (row_index + 2).to_s
          @report.answer(question: table_name, cell: cell_name).update(summary: value)
        end
      end

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: [],
        first_column: 'A',
        last_column: 'N',
        first_row: 2,
        last_row: project_rows.size + 1,
      }
      @report.answer(question: table_name).update(metadata: metadata)
    end
  end
end
