module Hmis::Form
  RecordType = Struct.new(:id, :owner_type, :processor_name, keyword_init: true) do
    extend Enumerable

    def self.each(&block)
      all.each(&block)
    end

    def self.find(id)
      @by_id ||= all.index_by(&:id)
      @by_id[id]
    end

    def self.all
      @all ||= [
        new(
          id: 'ASSESSMENT',
          owner_type: 'Hmis::Hud::Assessment',
          processor_name: 'CeAssessment',
        ),
        new(
          id: 'CLIENT',
          owner_type: 'Hmis::Hud::Client',
          processor_name: 'Client',
        ),
        new(
          id: 'CURRENT_LIVING_SITUATION',
          owner_type: 'Hmis::Hud::CurrentLivingSituation',
          processor_name: 'CurrentLivingSituation',
        ),
        new(
          id: 'DISABILITY_GROUP',
          owner_type: nil,
          processor_name: 'DisabilityGroup',
        ),
        new(
          id: 'EMPLOYMENT_EDUCATION',
          owner_type: 'Hmis::Hud::EmploymentEducation',
          processor_name: 'EmploymentEducation',
        ),
        new(
          id: 'ENROLLMENT',
          owner_type: 'Hmis::Hud::Enrollment',
          processor_name: 'Enrollment',
        ),
        new(
          id: 'EVENT',
          owner_type: 'Hmis::Hud::Event',
          processor_name: 'Event',
        ),
        new(
          id: 'EXIT',
          owner_type: 'Hmis::Hud::Exit',
          processor_name: 'Exit',
        ),
        new(
          id: 'HEALTH_AND_DV',
          owner_type: 'Hmis::Hud::HealthAndDv',
          processor_name: 'HealthAndDv',
        ),
        new(
          id: 'INCOME_BENEFIT',
          owner_type: 'Hmis::Hud::IncomeBenefit',
          processor_name: 'IncomeBenefit',
        ),
        new(
          id: 'YOUTH_EDUCATION_STATUS',
          owner_type: 'Hmis::Hud::YouthEducationStatus',
          processor_name: 'YouthEducationStatus',
        ),
        new(
          id: 'GEOLOCATION',
          owner_type: 'Hmis::Hud::Enrollment',
          processor_name: 'Geolocation',
        ),
      ].map(&:freeze).freeze
    end
  end
end
