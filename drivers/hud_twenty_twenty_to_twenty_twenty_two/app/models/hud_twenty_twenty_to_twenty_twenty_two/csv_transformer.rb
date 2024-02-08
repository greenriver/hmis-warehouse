###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo
  class CsvTransformer
    include ExternalFileUtils

    TRANSFORM_TYPES = {
      'Export.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Export,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Export::Csv,
      },
      'Organization.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Organization,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Organization::Csv,
      },
      'Project.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Project,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Project::Csv,
      },
      'Client.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Client,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Client::Csv,
      },
      'Disabilities.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Disability,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Disability::Csv,
      },
      'EmploymentEducation.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::EmploymentEducation,
      },
      'Enrollment.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Enrollment,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Enrollment::Csv,
      },
      'EnrollmentCoC.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::EnrollmentCoc,
      },
      'Exit.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Exit,
      },
      'Funder.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Funder,
      },
      'HealthAndDV.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::HealthAndDv,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::Csv,
      },
      'IncomeBenefits.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::IncomeBenefit,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit::Csv,
      },
      'Inventory.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Inventory,
      },
      'ProjectCoC.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::ProjectCoc,
      },
      'Affiliation.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Affiliation,
      },
      'Services.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Service,
        transformer: HudTwentyTwentyToTwentyTwentyTwo::Service::Csv,
      },
      'CurrentLivingSituation.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::CurrentLivingSituation,
      },
      'Assessment.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Assessment,
      },
      'AssessmentQuestions.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::AssessmentQuestion,
      },
      'AssessmentResults.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::AssessmentResult,
      },
      'Event.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Event,
      },
      'User.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::User,
      },
      'YouthEducationStatus.csv' => {
        action: :create,
        model: GrdaWarehouse::Hud::YouthEducationStatus,
      },
    }.freeze

    def self.up(source_directory, destination_directory)
      TRANSFORM_TYPES.each do |file, transform|
        action = transform[:action]
        model = transform[:model]
        transformer = transform[:transformer]

        source_file = File.join(source_directory, file)
        destination_file = File.join(destination_directory, file)
        next unless File.exist?(source_file)

        case action
        when :copy
          encoding = AutoEncodingCsv.detect_encoding(source_file)
          fix_bad_line_endings(source_file, encoding)
          FileUtils.copy(source_file, destination_file)
        when :update
          encoding = AutoEncodingCsv.detect_encoding(source_file)
          fix_bad_line_endings(source_file, encoding)
          ::Kiba.run(transformer.up(source_file, destination_file, encoding, header_converter(model)))
        when :create
          CSV.open(
            destination_file, 'w',
            write_headers: true,
            headers: model.hmis_configuration(version: '2022').keys.map(&:to_s)
          ) { |csv| } # Empty block
        end
      end
    end

    def self.header_converter(klass)
      normalized_klass_keys = klass.hmis_configuration(version: '2020').keys.map { |key| [key.to_s.downcase, key.to_s] }.to_h
      proc { |header| normalized_klass_keys[header.downcase] || header }
    end
  end
end
