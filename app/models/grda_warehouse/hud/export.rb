###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Export < Base
    include HudSharedScopes
    self.table_name = 'Export'
    self.hud_key = :ExportID

    def self.hud_paranoid_column
      nil
    end

    def self.hud_csv_headers(version: nil)
      # Same for 5 & 6 at this time
      [
        :ExportID,
        :SourceType,
        :SourceID,
        :SourceName,
        :SourceContactFirst,
        :SourceContactLast,
        :SourceContactPhone,
        :SourceContactExtension,
        :SourceContactEmail,
        :ExportDate,
        :ExportStartDate,
        :ExportEndDate,
        :SoftwareName,
        :SoftwareVersion,
        :ExportPeriodType,
        :ExportDirective,
        :HashStatus
      ].freeze
    end

    has_many :affiliations, **hud_assoc(:AffiliationID, 'Affiliation'), inverse_of: :export
    has_many :clients, **hud_assoc(:PersonalID, 'Client'), inverse_of: :export
    has_many :disabilities, **hud_assoc(:DisabilityID, 'Disability'), inverse_of: :export
    has_many :employment_educations, **hud_assoc(:EmploymentEducationID, 'EmploymentEducation'), inverse_of: :export
    has_many :enrollments, **hud_assoc(:EnrollmentID, 'Enrollment'), inverse_of: :export
    has_many :enrollment_cocs, **hud_assoc(:EnrollmentCocID, 'EnrollmentCoc'), inverse_of: :export
    has_many :exits, **hud_assoc(:ExitID, 'Exit'), inverse_of: :export
    has_many :funders, **hud_assoc(:FunderID, 'Funder'), inverse_of: :export
    has_many :health_and_dvs, **hud_assoc(:HealthAndDvID, 'HealthAndDv'), inverse_of: :export
    has_many :income_benefits, **hud_assoc(:IncomeBenefitID, 'IncomeBenefit'), inverse_of: :export
    has_many :inventories, **hud_assoc(:InventoryID, 'Inventory'), inverse_of: :export
    has_many :organizations, **hud_assoc(:OrganizationID, 'Organization'), inverse_of: :export
    has_many :projects, **hud_assoc(:ProjectID, 'Project'), inverse_of: :export
    has_many :project_cocs, **hud_assoc(:ProjectCocID, 'ProjectCoc'), inverse_of: :export
    has_many :services, **hud_assoc(:ServiceID, 'Service'), inverse_of: :export
    has_many :sites, **hud_assoc(:SiteID, 'Site'), inverse_of: :export
    has_many :users, **hud_assoc(:UserID, 'User'), inverse_of: :export
    has_many :current_living_situations, **hud_assoc(:CurrentLivingSituationID, 'CurrentLivingSituation'), inverse_of: :export
    has_many :assessments, **hud_assoc(:AssessmentID, 'Assessment'), inverse_of: :export
    has_many :assessment_questions, **hud_assoc(:AssessmentQuestionID, 'AssessmentQuestion'), inverse_of: :export
    has_many :assessment_results, **hud_assoc(:AssessmentResultID, 'AssessmentResult'), inverse_of: :export
    has_many :events, **hud_assoc(:EventID, 'Event'), inverse_of: :export

    belongs_to :data_source, inverse_of: :exports
  end
end