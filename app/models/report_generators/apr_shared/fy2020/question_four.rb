###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::AprShared::Fy2020
  class QuestionFour
    attr_accessor :report

    def initialize(generator)
      @generator = generator
      @report = generator.report
    end

    QUESTION_NUMBER = 'Q4'
    QUESTION_TABLE_NUMBER = 'Q4a'

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

    def run!
      @generator.update_state(QUESTION_NUMBER)

      project_rows = []

      GrdaWarehouse::Hud::Project.find(@report.project_ids). each do |project|
        project_row = [
          project.organization.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.ProjectType,
          (project.ProjectType == 1)? project.TrackingMethod : 0,
          (project.ProjectType == 6)? project.ResidentialAffiliation : 0,
          (project.ProjectType == 6 && project.ResidentialAffiliation == 1)? project.residential_affiliations.map(&:ProjectID).join(', ') : '',
          project.project_cocs.map(&:CoCCode).join(', '),
          project.project_cocs.map(&:Geocode).join(', '),
          (project.VictimServicesProvider.present?)? project.VictimServicesProvider : 0,
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
    end
  end
end