###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::CeApr::Fy2020
  class QuestionFour
    attr_accessor :report

    def initialize(generator)
      @generator = generator
      @report = generator.report
    end

    TABLE_HEADER = [
      'Organization Name',
      'Organization ID',
      'Project Name',
      'Project ID',
      'HMIS Project Type	Method for Tracking ES',
      'Affiliated with a residential project',
      'Project IDs of affiliations',
      'CoC Number',
      'Geocode',
      'Victim Service Provider',
      'HMIS Software Name',
      'Report Start Date',
      'Report End Date',
    ]

    HMIS_SOFTWARE_NAME = 'OpenPath'

    def run!
      @generator.update_state('Q4')

      metadata = []
      @report.options['project_ids'].each do |project_id|
        project = GrdaWarehouse::Hud::Project.find_by(ProjectID: project_id)
        metadata_row = [
          project.organization.OrganizationName,
          project.OrganizationID,
          project.ProjectName,
          project.ProjectID,
          project.ProjectType,
          (project.ProjectType == 1)? project.TrackingMethod : 0,
          (project.ProjectType == 6)? project.ResidentialAffiliation : 0,
          (project.ProjectType == 6 && project.ResidentialAffiliation == 1)? project.residential_affiliations.map(&:ProjectID).join(' ') : '',
          project.project_cocs.map(&:CoCCode).join(' '),
          project.project_cocs.map(&:Geocode).join(' '),
          (project.VictimServicesProvider.present?)? project.VictimServiceProvider : 0,
          HMIS_SOFTWARE_NAME,
          @report.start_date,
          @report.end_date,
        ]
        metadata << metadata_row
      end

      @report.cell('Q4', nil).update(metadata: metadata)
    end
  end
end