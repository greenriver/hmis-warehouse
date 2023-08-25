###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour
  class CsvTransformer
    include ExternalFileUtils

    TRANSFORM_TYPES = {
      # Export File
      'Export.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Export,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Export::Csv,
      },
      # Project Descriptor Files
      'Organization.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Organization,
      },
      'User.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::User,
      },
      'Project.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Project,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Project::Csv,
      },
      'Funder.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Funder,
      },
      'ProjectCoC.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::ProjectCoc,
      },
      'Inventory.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Inventory,
      },
      'Affiliation.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Affiliation,
      },
      'HMISParticipation.csv' => {
        action: :create,
        model: GrdaWarehouse::Hud::HmisParticipation,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::HmisParticipation::Csv,
        references: {
          project: {
            file: 'Project.csv',
          },
          organization: {
            file: 'Organization.csv',
          },
        },
      },
      'CEParticipation.csv' => { # Create an empty placeholder file, but we aren't populating it..
        action: :create,
        model: GrdaWarehouse::Hud::CeParticipation,
      },
      # Client File
      'Client.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Client,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Client::Csv,
      },
      # Enrollment Files
      'Enrollment.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Enrollment,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::Csv,
        references: {
          enrollment_coc: {
            file: 'EnrollmentCoC.csv',
          },
        },
      },
      'Exit.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Exit,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Exit::Csv,
      },
      'IncomeBenefits.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::IncomeBenefit,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::IncomeBenefit::Csv,
      },
      'HealthAndDV.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::HealthAndDv,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::HealthAndDv::Csv,
      },
      'EmploymentEducation.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::EmploymentEducation,
      },
      'Disabilities.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::Disability,
      },
      'Services.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::Service,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::Service::Csv,
      },
      'CurrentLivingSituation.csv' => {
        action: :update,
        model: GrdaWarehouse::Hud::CurrentLivingSituation,
        transformer: HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation::Csv,
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
      'YouthEducationStatus.csv' => {
        action: :copy,
        model: GrdaWarehouse::Hud::YouthEducationStatus,
      },
    }.freeze

    def self.up(source_directory, destination_directory)
      TRANSFORM_TYPES.each do |file, transform|
        action = transform[:action]
        model = transform[:model]
        transformer = transform[:transformer]
        references = transform[:references] || {}

        source_file = File.join(source_directory, file)
        destination_file = File.join(destination_directory, file)
        next unless action == :create || File.exist?(source_file)

        references.transform_values! do |reference|
          file = File.join(source_directory, reference[:file])
          next unless File.exist?(file)

          encoding = AutoEncodingCsv.detect_encoding(file)
          fix_bad_line_endings(file, encoding)
          {
            file: file,
            model: reference[:model],
          }
        end

        case action
        when :copy
          encoding = AutoEncodingCsv.detect_encoding(source_file)
          fix_bad_line_endings(source_file, encoding)
          FileUtils.copy(source_file, destination_file)
        when :update
          encoding = AutoEncodingCsv.detect_encoding(source_file)
          fix_bad_line_endings(source_file, encoding)
          ::Kiba.run(transformer.up(source_file, destination_file, encoding, header_converter(model), references))
        when :create
          if transformer.present?
            ::Kiba.run(transformer.create(destination_file, references))
          else
            CSV.open(
              destination_file, 'w',
              write_headers: true,
              headers: model.hmis_configuration(version: '2024').keys.map(&:to_s)
            ) { |csv| } # Empty block
          end
        end
      end
    end

    def self.header_converter(klass)
      normalized_klass_keys = klass.hmis_configuration(version: '2022').keys.map { |key| [key.to_s.downcase, key.to_s] }.to_h
      proc { |header| normalized_klass_keys[header.downcase] || header }
    end
  end
end
