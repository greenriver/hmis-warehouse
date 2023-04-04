###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisitFile < HealthBase
    acts_as_paranoid
    require 'csv'

    phi_attr :file, Phi::FreeText, 'Name of file'
    phi_attr :content, Phi::FreeText, 'Content of file'

    belongs_to :user, optional: true

    mount_uploader :file, EdIpVisitFileUploader

    has_many :loaded_ed_ip_visits, dependent: :destroy

    def label
      'ED & IP Visits'
    end

    def status
      if failed_at.present?
        'Failed to import'
      elsif completed_at.present?
        'Imported'
      elsif started_at.present?
        'Importing...'
      elsif updated_at < 3.hours.ago
        'Failed to import'
      else
        'Queued for import'
      end
    end

    def columns
      self.class.header_map
    end

    def load!
      update(started_at: Time.current)
      visits = []
      if check_header
        ::CSV.parse(content, headers: true, liberal_parsing: true).each do |row|
          model_row = {
            ed_ip_visit_file_id: id,
          }
          self.class.header_map.each do |column, title|
            next unless Health::LoadedEdIpVisit.column_names.include?(column.to_s)

            value = row[title]
            if csv_date_columns.include?(column) && value
              model_row[column] = Date.strptime(value, '%m/%d/%Y')
            else
              model_row[column] = value
            end
            # Create an encounter identifier, if one does not exist
            model_row[:encounter_id] = default_encounter_id(model_row) if model_row[:encounter_id].nil?
          end
          next if model_row[:encounter_id].blank?

          visits << model_row
        end
        Health::LoadedEdIpVisit.import!(visits)
        update(completed_at: Time.current)
        return true
      else
        update(failed_at: Time.current, message: 'Check header failed')
        return false
      end
    rescue Exception => e
      update(failed_at: Time.current, message: e.message)
      return false
    end

    def ingest!(loaded_visits)
      visits = []
      loaded_visits.each do |loaded_visit|
        next unless loaded_visit.medicaid_id

        visits << {
          medicaid_id: loaded_visit.medicaid_id,
          admit_date: loaded_visit.admit_date,
          encounter_major_class: loaded_visit.encounter_major_class,
          loaded_ed_ip_visit_id: loaded_visit.id,
          encounter_id: loaded_visit.encounter_id,
        }
      end
      Health::EdIpVisit.import(
        visits,
        on_duplicate_key_ignore: true,
      )
    end

    private def default_encounter_id(model_row)
      # In the absence of better data, it was decided that one encounter per type per day was reasonable,
      # so we can use that as a default encounter id:
      encounter_id = "#{model_row[:medicaid_id]}_#{model_row[:admit_date]}_#{model_row[:visit_type]}"

      # Encounter IDs must be unique in an INSERT or the import fails...
      @encounter_ids ||= Set.new
      return nil if @encounter_ids.include?(encounter_id)

      @encounter_ids << encounter_id
      encounter_id
    end

    private def check_header
      incoming = ::CSV.parse(content.lines.first).flatten.map { |m| m&.strip }
      expected = parsed_expected_header.map { |m| m&.strip }
      # You can update the header string with File.read('path/to/file.csv').lines.first
      # Using CSV parse in case the quoting styles differ
      return true if incoming == expected

      Rails.logger.error (incoming - expected).inspect
      Rails.logger.error (expected - incoming).inspect
      return false
    end

    private def parsed_expected_header
      CSV.parse(expected_header).flatten
    end

    private def expected_header
      self.class.header_map.values.join(',')
    end
  end
end
