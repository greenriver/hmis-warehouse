###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class User < Base
    include HudSharedScopes
    self.table_name = :User
    self.hud_key = :UserID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :UserID,
        :UserFirstName,
        :UserLastName,
        :UserPhone,
        :UserExtension,
        :UserEmail,
        :DateCreated,
        :DateUpdated,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    has_many :affiliations, **hud_assoc(:UserID, 'Affiliation')
    has_many :clients, **hud_assoc(:PersonalID, 'Client')
    has_many :disabilities, **hud_assoc(:UserID, 'Disability')
    has_many :employment_educations, **hud_assoc(:UserID, 'EmploymentEducation')
    has_many :enrollments, **hud_assoc(:UserID, 'Enrollment')
    has_many :enrollment_cocs, **hud_assoc(:UserID, 'EnrollmentCoc')
    has_many :exits, **hud_assoc(:UserID, 'Exit')
    has_many :funders, **hud_assoc(:UserID, 'Funder')
    has_many :health_and_dvs, **hud_assoc(:UserID, 'HealthAndDv')
    has_many :income_benefits, **hud_assoc(:UserID, 'IncomeBenefit')
    has_many :inventories, **hud_assoc(:UserID, 'Inventory')
    has_many :organizations, **hud_assoc(:UserID, 'Organization')
    has_many :projects, **hud_assoc(:UserID, 'Project')
    has_many :project_coss, **hud_assoc(:UserID, 'ProjectCoc')
    has_many :services, **hud_assoc(:UserID, 'Service')

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :users
    belongs_to :data_source

  end
end
