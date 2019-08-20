###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
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

    has_many :affiliations, **hud_many(Affiliation)
    has_many :clients, **hud_many(Client)
    has_many :disabilities, **hud_many(Disability)
    has_many :employment_educations, **hud_many(EmploymentEducation)
    has_many :enrollments, **hud_many(Enrollment)
    has_many :enrollment_cocs, **hud_many(EnrollmentCoc)
    has_many :exits, **hud_many(Exit)
    has_many :funders, **hud_many(Funder)
    has_many :health_and_dvs, **hud_many(HealthAndDv)
    has_many :income_benefits, **hud_many(IncomeBenefit)
    has_many :inventories, **hud_many(Inventory)
    has_many :organizations, **hud_many(Organization)
    has_many :projects, **hud_many(Project)
    has_many :project_coss, **hud_many(ProjectCoc)
    has_many :services, **hud_many(Service)

    belongs_to :export, **hud_belongs(Export), inverse_of: :users
    belongs_to :data_source

  end
end
