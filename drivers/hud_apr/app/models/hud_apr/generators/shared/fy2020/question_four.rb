###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFour < Base
    QUESTION_NUMBER = 'Question 4'.freeze
    QUESTION_TABLE_NUMBER = 'Q4a'.freeze

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

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      project_rows = []

      GrdaWarehouse::Hud::Project.find(@report.project_ids).each do |project|
        project_row = [
          project.organization.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.ProjectType,
          if project.ProjectType == 1 then project.TrackingMethod else 0 end,
          if project.ProjectType == 6 then project.ResidentialAffiliation else 0 end,
          if project.ProjectType == 6 && project.ResidentialAffiliation == 1 then project.residential_affiliations.map(&:ProjectID).join(', ') else ' ' end,
          project.project_cocs.map(&:CoCCode).join(', '),
          project.project_cocs.map(&:Geocode).join(', '),
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
          @report.answer(question: QUESTION_TABLE_NUMBER, cell: cell_name).update(summary: value)
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
      @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
