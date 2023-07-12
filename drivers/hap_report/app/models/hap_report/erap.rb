###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport
  class Erap < GrdaWarehouseBase
    belongs_to :hap_report, class_name: 'HapReport::Report'

    def self.parse(report, data)
      return true if data.nil?

      data = data.force_encoding('UTF-8').delete_prefix("\xEF\xBB\xBF") # REMOVE UTF-8 encoding if present
      content = StringIO.new(data)
      header = CSV.parse(content.each_line.first).flatten.map { |m| m&.strip }
      content.rewind
      if header == CSV_FORMAT.keys
        batch = []
        CSV.parse(content, headers: true) do |raw|
          row = raw.to_h.transform_keys { |k| CSV_FORMAT[k] }
          next if row[:personal_id].blank?

          row[:hap_report_id] = report.id
          batch << row
        end
        import!(batch)
        return true
      end
      false
    rescue CSV::MalformedCSVError
      false
    end

    def client_key
      OpenStruct.new(first_name: first_name, last_name: last_name, mci_id: mci_id)
    end

    def client_data
      {}.tap do |h|
        DATA_MAPPING.each do |key, attr|
          h[key] = send(attr)
        end
      end
    end

    CSV_FORMAT = {
      personal_id: 'personal_id',
      mci_id: 'mci_id',
      first_name: 'first_name',
      last_name: 'last_name',
      age: 'age',
      household_id: 'household_id',
      head_of_household: 'head_of_household',
      emancipated: 'emancipated',
      project_type: 'project_type',
      veteran: 'veteran',
      mental_health_disorder: 'mental health disorder',
      substance_use_disorder: 'substance use disorder',
      survivor_of_domestic_violence: 'survivor of domestic violence',
      income_at_start: 'income at start',
      income_at_exit: 'income at exit',
      homeless: 'homeless',
      nights_in_shelter: 'nights in shelter',
    }.invert.freeze
  end

  DATA_MAPPING = {
    personal_id: :personal_id,
    mci_id: :mci_id,
    age: :age,
    head_of_household: :head_of_household,
    emancipated: :emancipated,
    veteran: :veteran,
    mental_health: :mental_health_disorder,
    substance_use_disorder: :substance_use_disorder,
    domestic_violence: :survivor_of_domestic_violence,
    income_at_start: :income_at_start,
    income_at_exit: :income_at_exit,
    homeless: :homeless,
  }.freeze
end
