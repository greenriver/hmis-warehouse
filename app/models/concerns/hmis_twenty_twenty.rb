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
      importable_files_map.transform_values do |name|
        importable_file_class(name)
      end
    end

    def self.importable_file_class(name)
      "#{module_scope}::#{name}".constantize
    end

    def elapsed_time(total_seconds)
      d = total_seconds / 86_400
      h = total_seconds / 3600 % 24
      m = total_seconds / 60 % 60
      s = total_seconds % 60
      if d >= 1
        format('%id%ih%im%.3fs', d, h, m, s)
      elsif h >= 1
        format('%ih%im%.3fs', h, m, s)
      elsif m >= 1
        format('%im%.3fs', m, s)
      else
        format('%.3fs', s)
      end
    end
  end
end
