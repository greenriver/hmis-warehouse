###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo
  class CsvTransformer
    TRANSFORM_TYPES = {
      'Export.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Export::Csv],
      'Organization.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Organization::Csv],
      'Project.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Project::Csv],
      'Client.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Client::Csv],
      'Disabilities.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Disability::Csv],
      'EmploymentEducation.csv' => [:copy],
      'Enrollment.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Enrollment::Csv],
      'EnrollmentCoC.csv' => [:copy],
      'Exit.csv' => [:copy],
      'Funder.csv' => [:copy],
      'HealthAndDV.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::Csv],
      'IncomeBenefits.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit::Csv],
      'Inventory.csv' => [:copy],
      'ProjectCoC.csv' => [:copy],
      'Affiliation.csv' => [:copy],
      'Services.csv' => [:update, HudTwentyTwentyToTwentyTwentyTwo::Service::Csv],
      'CurrentLivingSituation.csv' => [:copy],
      'Assessment.csv' => [:copy],
      'AssessmentQuestions.csv' => [:copy],
      'AssessmentResults.csv' => [:copy],
      'Event.csv' => [:copy],
      'User.csv' => [:copy],
      'YouthEducationStatus.csv' => [:create, GrdaWarehouse::Hud::YouthEducationStatus],
    }.freeze

    def self.up(source_directory, destination_directory)
      TRANSFORM_TYPES.each do |file, (action, klass)|
        source_file = File.join(source_directory, file)
        destination_file = File.join(destination_directory, file)

        case action
        when :copy
          FileUtils.copy(source_file, destination_file)
        when :update
          ::Kiba.run(klass.up(source_file, destination_file))
        when :create
          CSV.open(
            destination_file, 'w',
            write_headers: true,
            headers: klass.hmis_configuration(version: '2022').keys.map(&:to_s)
          ) { |csv| } # Empty block
        end
      end
    end
  end
end
