###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###
module HmisTwentyTwenty
  extend ActiveSupport::Concern
  included do
    def self.importable_files_map
      {
        'Export.csv' => 'Export',
        'Organization.csv' => 'Organization',
        'Project.csv' => 'Project',
        'Client.csv' => 'Client',
        'Disabilities.csv' => 'Disability',
        'EmploymentEducation.csv' => 'EmploymentEducation',
        'Enrollment.csv' => 'Enrollment',
        'EnrollmentCoC.csv' => 'EnrollmentCoc',
        'Exit.csv' => 'Exit',
        'Funder.csv' => 'Funder',
        'HealthAndDV.csv' => 'HealthAndDv',
        'IncomeBenefits.csv' => 'IncomeBenefit',
        'Inventory.csv' => 'Inventory',
        'ProjectCoC.csv' => 'ProjectCoc',
        'Affiliation.csv' => 'Affiliation',
        'Services.csv' => 'Service',
        'CurrentLivingSituation.csv' => 'CurrentLivingSituation',
        'Assessment.csv' => 'Assessment',
        'AssessmentQuestions.csv' => 'AssessmentQuestion',
        'AssessmentResults.csv' => 'AssessmentResult',
        'Event.csv' => 'Event',
        'User.csv' => 'User',
      }.freeze
    end

    def self.importable_files
      importable_files_map.transform_values { |name| "#{module_scope}::#{name}".constantize }
    end
  end
end
