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

    def self.look_aside_scope
      # Default to no look aside module
      nil
    end

    def self.importable_files
      importable_files_map.transform_values do |name|
        module_name = if HmisTwentyTwenty.look_aside?(name) && look_aside_scope.present?
          look_aside_scope
        else
          module_scope
        end

        "#{module_name}::#{name}".constantize
      end
    end
  end

  def self.look_aside(clazz)
    @look_aside ||= []
    @look_aside << clazz.name.split('::').last
  end

  def self.look_aside?(name)
    @look_aside ||= []
    @look_aside.include?(name)
  end
end
