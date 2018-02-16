RSpec.shared_context "enrollment setup", shared_context: :metadata do
  let!(:enrollments) { create_list :hud_enrollment, 5, data_source_id: data_source.id, EntryDate: 2.weeks.ago }
  let!(:clients) { create_list :hud_client, 5, data_source_id: data_source.id }
  let!(:destination_data_source) { create :grda_warehouse_data_source }
  let!(:destination_clients) do 
    clients.map do |client|
      client.data_source_id = destination_data_source.id
      attributes = client.attributes
      attributes['id'] = nil
      dest_client = GrdaWarehouse::Hud::Client.create(attributes)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: client.PersonalID,
        data_source_id: client.data_source_id,
        source_id: client.id,
        destination_id: dest_client.id
      )
    end
  end
  let!(:disabilities) { create_list :hud_disability, 5, data_source_id: data_source.id, InformationDate: 1.week.ago }
  let!(:enrollment_cocs) { create_list :hud_enrollment_coc, 5, data_source_id: data_source.id, InformationDate: 1.week.ago }
  let!(:employment_educations) { create_list :hud_employment_education, 5, data_source_id: data_source.id, InformationDate: 1.week.ago }
  let!(:health_and_dvs) { create_list :hud_health_and_dv, 5, data_source_id: data_source.id, InformationDate: 1.week.ago }
  let!(:income_benefits) { create_list :hud_income_benefit, 5, data_source_id: data_source.id, InformationDate: 1.week.ago }
  let!(:services) { create_list :hud_service, 5, data_source_id: data_source.id, DateProvided: 1.week.ago }
  let!(:exits) { create_list :hud_exit, 5, data_source_id: data_source.id, ExitDate: Date.yesterday }
  
  # Project Related
  # 'Affiliation.csv' => affiliation_source,
  # 'Funder.csv' => funder_source,
  # 'Inventory.csv' => inventory_source,
  # 'Organization.csv' => organization_source,
  # 'Geography.csv' => geography_source,
  # 'ProjectCoC.csv' => project_coc_source,
  
  # Enrollment Related
  # 'Disabilities.csv' => disability_source,
  # 'EmploymentEducation.csv' => employment_education_source,
  # 'EnrollmentCoC.csv' => enrollment_coc_source,
  # 'Exit.csv' => exit_source,
  # 'HealthAndDV.csv' => health_and_dv_source,
  # 'IncomeBenefits.csv' => income_benefits_source,
  # 'Services.csv' => service_source,
  
  #  Other
  # 'Export.csv' => export_source,
  # 'Client.csv' => client_source,
  # 'Enrollment.csv' => enrollment_source,
  # 'Project.csv' => project_source,

  class EnrollmentRelatedTests
    TESTS ||= [
      { 
        list: :disabilities,
        klass: GrdaWarehouse::Export::HMISSixOneOne::Disability,
        export_method: :export_disabilities,
      },
      { 
        list: :enrollment_cocs,
        klass: GrdaWarehouse::Export::HMISSixOneOne::EnrollmentCoc,
        export_method: :export_enrollment_cocs,
      },
      { 
        list: :employment_educations,
        klass: GrdaWarehouse::Export::HMISSixOneOne::EmploymentEducation,
        export_method: :export_employment_educations,
      },
      { 
        list: :health_and_dvs,
        klass: GrdaWarehouse::Export::HMISSixOneOne::HealthAndDv,
        export_method: :export_health_and_dvs,
      },
      { 
        list: :income_benefits,
        klass: GrdaWarehouse::Export::HMISSixOneOne::IncomeBenefit,
        export_method: :export_income_benefits,
      },
      { 
        list: :services,
        klass: GrdaWarehouse::Export::HMISSixOneOne::Service,
        export_method: :export_services,
      },
      { 
        list: :exits,
        klass: GrdaWarehouse::Export::HMISSixOneOne::Exit,
        export_method: :export_exits,
      },
    ]
  end

  def csv_file_path klass
    File.join(exporter.file_path, klass.file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "enrollment setup", include_shared: true
end