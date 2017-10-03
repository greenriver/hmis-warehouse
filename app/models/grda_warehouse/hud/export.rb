module GrdaWarehouse::Hud
  class Export < Base
    include HudSharedScopes
    self.table_name = 'Export'
    self.hud_key = 'ExportID'

    def self.hud_paranoid_column 
      nil
    end

    def self.hud_csv_headers(version: nil)
      case version
      when 6.1
      else
        GrdaWarehouse::Import::HMISFiveOne::Export.hud_csv_headers
      end
      
    end

    # a little meta-programming to save my sanity -- this just builds a lot of has_many relations
    {
      affiliations:          Affiliation,
      clients:               Client,
      disabilities:          Disability,
      employment_educations: EmploymentEducation,
      enrollments:           Enrollment,
      enrollment_cocs:       EnrollmentCoc,
      exits:                 Exit,
      funders:               Funder,
      health_and_dvs:        HealthAndDv,
      income_benefits:       IncomeBenefit,
      inventories:           Inventory,
      organizations:         Organization,
      projects:              Project,
      project_cocs:          ProjectCoc,
      services:              Service,
      sites:                 Site,
    }.each do |rel, model|
        has_many rel, **hud_many(model), inverse_of: :export
    end

    belongs_to :data_source, inverse_of: :exports
  end
end