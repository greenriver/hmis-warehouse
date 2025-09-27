###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# job = HmisExternalApis::AcHmis::DataWarehouseUploadJob.new
module HmisExternalApis::AcHmis
  class DataWarehouseUploadJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    attr_accessor :state

    def perform(methods)
      if Exporters::DataWarehouseUploader.can_run?
        Rails.logger.info "Running #{methods} DW upload job"

        Array.wrap(methods).each do |method|
          if method == 'daily_uploads'
            instrument_as_maintenance_task(name: method) do |run|
              daily_uploads.each { |m| send(m) } # run all exports in the daily_uploads group
              run.complete!
            end
          elsif method == 'quarterly_uploads'
            instrument_as_maintenance_task(name: method, alert_threshold: 95.days) do |run|
              hmis_csv_export_full_refresh
              run.complete!
            end
          elsif known?(method)
            # run one export individually. only used for testing purposes or manual runs.
            send(method)
          else
            raise "unknown method: #{method}" unless known?(method)
          end
        end
        self.state = :success
      else
        self.state = :not_run
        Rails.logger.info "Not running #{methods} due to lack of credentials"
      end
    rescue StandardError => e
      puts e.message
      self.state = :failed
      log('Failure in Data Warehouse uploader job', exception: e)
      Rails.logger.fatal e.message
    end

    def one_time_training_env_export_20250904
      enrollment_ids = Hmis::Hud::Enrollment.where(id: [200819, 200804, 200850, 200802, 200710, 200866, 200867, 200872])
      enrollments = Hmis::Hud::Enrollment.where(id: enrollment_ids)

      form_identifier = 'housing_needs_assessment_2_0_individuals'
      fdt = Hmis::Form::Definition.arel_table
      custom_assessment_ids = Hmis::Hud::CustomAssessment.
        joins(:form_processor).joins(form_processor: :definition).
        where(enrollment: enrollments).
        where(fdt['identifier'].eq(form_identifier)).
        where(date_created: Date.new(2025, 9, 3).beginning_of_day..Date.new(2025, 9, 3).end_of_day).
        pluck(:id)

      weighted_link_ids = Hmis::Scoring::Rule.pluck(:link_id).to_set
      form = Hmis::Form::Definition.published.find_by(identifier: form_identifier)
      keys_to_include = form.link_id_item_hash.map do |id, item|
        next unless weighted_link_ids.include?(id)

        item.mapping.custom_field_key
      end.compact.to_set

      cded_export = HmisExternalApis::AcHmis::Exporters::CdedExport.new(included_keys: keys_to_include)
      cded_export.run!
      File.open('CustomFieldDefinitions.csv', 'w') do |file|
        file.write(cded_export.output.string)
      end

      cde_export = HmisExternalApis::AcHmis::Exporters::CdeExport.new(included_keys: keys_to_include, included_assessment_ids: custom_assessment_ids)
      cde_export.run!
      File.open('CustomFieldValues.csv', 'w') do |file|
        file.write(cde_export.output.string)
      end

      custom_assessment_export = HmisExternalApis::AcHmis::Exporters::CustomAssessmentExport.new(included_assessment_ids: custom_assessment_ids)
      custom_assessment_export.run!
      File.open('CustomAssessments.csv', 'w') do |file|
        file.write(custom_assessment_export.output.string)
      end

      alt_aha_calculation_log_export = HmisExternalApis::AcHmis::Exporters::AltAhaCalculationLogExport.new(included_enrollment_ids: enrollment_ids)
      alt_aha_calculation_log_export.run!
      File.open('AltAhaCalculationLogs.csv', 'w') do |file|
        file.write(alt_aha_calculation_log_export.output.string)
      end
    end

    def things
      require 'csv'
      output = StringIO.new
      columns = [
        'VariableName',
        'CustomFieldKey',
        'Algorithm',
        'CriteriaType',
        'ExactMatch',
        'GreaterThan',
        'GreaterThanOrEqualTo',
        'LessThan',
        'LessThanOrEqualTo',
        'Weight',
      ]
      form = Hmis::Form::Definition.published.find_by(identifier: 'hna_2')
      output << CSV.generate_line(columns)
      Hmis::Scoring::Rule.all.each do |rule|
        algorithm = case rule.algorithm
                    when 'alt_aha_1'
                      'er'
                    when 'alt_aha_2'
                      'mhip'
                    when 'alt_aha_3'
                      'jail'
                    end
        item = form.link_id_item_hash[rule.link_id]
        custom_field_key = item ? item['mapping']['custom_field_key'] : rule.link_id

        if custom_field_key == 'housing_needs_monthly_household_income'
          # if rule.criteria_config['match_value'].nil? && rule.criteria_config['gt'].nil? && rule.criteria_config['gte'].nil? && rule.criteria_config['lt'].nil? && rule.criteria_config['lte'].nil?
          binding.pry
        end

        values = [
          rule.variable_name,
          custom_field_key,
          algorithm,
          rule.criteria_type,
          rule.criteria_config['match_value'],
          rule.criteria_config['gt'],
          rule.criteria_config['gte'],
          rule.criteria_config['lt'],
          rule.criteria_config['lte'],
          rule.weight,
        ]
        output << CSV.generate_line(values)
      end
      File.open('AltAhaScoringRules.csv', 'w') do |file|
        file.write(output.string)
      end
    end

    private

    def log(message, exception: nil)
      if exception
        Sentry.capture_exception(exception)
        Rails.logger.error("#{message} #{exception.message}")
      else
        Rails.logger.info(message)
      end
    end

    def known?(method)
      known_methods.include?(method)
    end

    def known_methods
      [
        'clients_with_mci_ids_and_address',
        'hmis_csv_export',
        'hmis_csv_export_full_refresh', # runs quarterly
        'project_crosswalk',
        'move_in_address_export',
        'posting_export',
        'custom_fields_export',
        'pathways_export',
        'case_note_export',
        # 'ce_referrals',
        # 'ce_referral_tasks',
        # 'custom_assessments',
      ].freeze
    end

    def daily_uploads
      known_methods - ['hmis_csv_export_full_refresh']
    end

    def clients_with_mci_ids_and_address
      export = Exporters::ClientExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-clients.zip',
        io_streams: [
          OpenStruct.new(
            name: 'ClientMciMapping.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def hmis_csv_export
      export = HmisExternalApis::AcHmis::Exporters::HmisExportFetcher.new
      export.run!

      hash = Digest::MD5.hexdigest(export.content)

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: "%Y-%m-%d-HMIS-#{hash}-hudcsv.zip",
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def hmis_csv_export_full_refresh
      export = HmisExternalApis::AcHmis::Exporters::HmisExportFetcher.new
      export.run!(start_date: 10.years.ago.to_date)

      hash = Digest::MD5.hexdigest(export.content)

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: "%Y-%m-%d-HMIS-full-refresh-#{hash}-hudcsv.zip",
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def project_crosswalk
      export = HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-cross-walks.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Organizations-cross-walk.csv',
            io: export.orgs_csv_stream,
          ),
          OpenStruct.new(
            name: 'Project-cross-walk.csv',
            io: export.projects_csv_stream,
          ),
        ],
      )

      uploader.run!
    end

    def move_in_address_export
      export = HmisExternalApis::AcHmis::Exporters::MoveInAddressExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-move-in-addresses.zip',
        io_streams: [
          OpenStruct.new(
            name: 'MoveInAddresses.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def posting_export
      export = HmisExternalApis::AcHmis::Exporters::PostingExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-postings.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Postings.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def custom_fields_export
      cded_export = HmisExternalApis::AcHmis::Exporters::CdedExport.new
      cded_export.run!

      cde_export = HmisExternalApis::AcHmis::Exporters::CdeExport.new
      cde_export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-custom-fields.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CustomFieldDefinitions.csv',
            io: cded_export.output,
          ),
          OpenStruct.new(
            name: 'CustomFieldValues.csv',
            io: cde_export.output,
          ),
        ],
      )

      uploader.run!
    end

    def pathways_export
      export = HmisExternalApis::AcHmis::Exporters::PathwaysExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-pathways.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Pathways.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def case_note_export
      export = HmisExternalApis::AcHmis::Exporters::CaseNoteExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-case-notes.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CaseNotes.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def ce_referrals
      export = HmisExternalApis::AcHmis::Exporters::CeReferralExport.new
      export.run!
      # File.open('CeReferrals.csv', 'w') do |file|
      #   file.write(export.output.string)
      # end

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-ce-referrals.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CeReferrals.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def ce_referral_tasks
      export = HmisExternalApis::AcHmis::Exporters::CeReferralTaskExport.new
      export.run!
      # File.open('CeReferralTasks.csv', 'w') do |file|
      #   file.write(export.output.string)
      # end

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-ce-referral-tasks.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CeReferralTasks.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def custom_assessments_export
      export = HmisExternalApis::AcHmis::Exporters::CustomAssessmentExport.new
      export.run!

      # File.open('CustomAssessments.csv', 'w') do |file|
      #   file.write(export.output.string)
      # end
      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-custom-assessments.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CustomAssessments.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end
  end
end
