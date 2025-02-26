###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Importer
  class ImporterLog < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = 'hmis_csv_importer_logs'

    has_many :import_errors
    has_many :import_validations, class_name: 'HmisCsvImporter::HmisCsvValidation::Base'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    # phase_metrics can be large, use this scope for more performant selects
    scope :without_phase_metrics, -> { select(column_names - ['phase_metrics']) }

    def paused?
      status.to_s == 'paused'
    end

    def resuming?
      status.to_s == 'resuming'
    end

    def import_time
      return unless persisted?
      # Historically we didn't set started_at
      return unless started_at

      if completed_at && started_at
        seconds = ((completed_at - started_at) / 1.minute).round * 60
        "#{distance_of_time_in_words(seconds)} -#{started_at.strftime('%l:%M %P')} to #{completed_at.strftime('%l:%M %P')}"
      else
        'processing...'
      end
    end

    def post_processing_time(importer)
      return unless completed_at
      return unless importer&.completed_at

      seconds = ((importer.completed_at - completed_at) / 1.minute).round * 60
      "#{distance_of_time_in_words(seconds)} -#{importer.completed_at.strftime('%l:%M %P')} to #{completed_at.strftime('%l:%M %P')}"
    end

    def any_errors_or_validations?
      import_errors.exists? || import_validations.exists?
    end

    def import_validations_count(filename, files)
      validation_classes = HmisCsvImporter::HmisCsvValidation::Base.validation_classes.map(&:to_s)
      loader_class = files.to_h.invert[filename]
      import_validations.where(source_type: loader_class, type: validation_classes).count
    end

    def import_validation_errors_count(filename, files)
      error_classes = HmisCsvImporter::HmisCsvValidation::Base.error_classes.map(&:to_s)
      loader_class = files.to_h.invert[filename]
      import_validations.where(source_type: loader_class, type: error_classes).count
    end

    def log_phase(phase, **args)
      phase = phase.to_s
      raise if phase.blank?

      self.phase_metrics ||= {}
      phase_metrics[phase] ||= {}
      phase_metrics[phase].deep_merge!(args.stringify_keys)
      save!
    end

    # for debugging
    def format_phases(show_sql: false)
      log_data = phase_metrics
      # log_data = JSON.parse(File.read(Rails.root.join('t2.json')))

      # Sort phases by duration (if available)
      sorted_phases = log_data.sort_by do |_phase_name, phase_data|
        -(phase_data['duration'] || 0).to_f
      end

      # Format each phase
      formatted_output = ''

      sorted_phases.each do |phase_name, phase_data|
        formatted_output += "#{phase_name}:\n"

        # Add phase duration if available
        if phase_data['duration']
          formatted_output += "  duration: #{phase_data['duration']} seconds\n"
        else
          formatted_output += "  duration: incomplete\n"
        end

        # Process SQL query keys
        phase_data.each do |key, value|
          next if ['duration', 'started_at'].include?(key)

          # Assume this is a query key if it's an array
          next unless value.is_a?(Array) && !value.empty?

          formatted_output += "  #{key}:\n"

          # Sort queries by duration
          sorted_queries = value.sort_by { |q| -(q['duration'] || 0).to_f }

          sorted_queries.each_with_index do |query_info, index|
            query_name = "query#{index + 1}"
            formatted_output += "     #{query_name}:\n"
            formatted_output += "       #{(query_info['duration'] / 1000) / 1000} seconds:\n"

            next unless query_info['compressed_query']

            next unless show_sql

            begin
              # decompress the query
              (query_sql, _query_binds) = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(query_info['compressed_query']))).values_at('sql', 'binds')
              # hydrate the binds
              # (_query_binds|| []).each { |bind| query_sql.sub!(/\$\d+/, bind['value'].gsub('"', "'")) }
              formatted_output += "       query: #{query_sql}\n"
              # formatted_output += "       binds: #{_query_binds}\n"
            rescue StandardError => e
              formatted_output += "       error: Failed to decompress query: #{e.message}\n"
            end
          end
        end
      end

      formatted_output
    end
  end
end
