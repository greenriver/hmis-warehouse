###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Not an importer, this is an assistive class for composing the UHA cols
module HmisExternalApis::TcHmis::Importers::Loaders
  class UhaHeaderBuilder
    def perform(dir)
      reader = FileReader.new(dir)

      seen = Set.new
      rows = reader.rows(filename: 'UHA_cols.xlsx', header_row_number: 1, field_id_row_number: nil)
      configs = rows.map do |row|
        next if row.field_value(:skip, required: false)

        id =  row.field_value(:id, required: false)
        label = row.field_value(:label)
        key = row.field_value(:key, required: false)
        prefix = row.field_value(:prefix, required: false)
        suffix = row.field_value(:suffix, required: false)
        repeats = row.field_value(:repeats, required: false).present?

        key ||= label.size <= 50 ? label_to_key(label) : id_to_key(id)
        raise unless key

        key = ['uha', prefix, key, suffix].compact.join('_')
        raise row.inspect if key.in?(seen)

        seen.add key

        { element_id: id, label: label, key: key, repeats: repeats, field_type: 'string' }
      end
      configs.compact
    end

    def label_to_key(label)
      label.downcase.gsub(/[^a-z0-9]+/, ' ').strip.gsub(' ', '_')
    end

    def id_to_key(id)
      "key_#{id}"
    end
  end
end
