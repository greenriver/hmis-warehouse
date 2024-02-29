###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Not an importer, this is an assistive class for composing columns
module HmisExternalApis::TcHmis::Importers::Loaders
  class HeaderBuilder
    # HeaderBuilder.new.perform(dir: '/host/tc', filename: 'uha_cols.xlsx', key_prefix: 'uha')
    def perform(dir:, filename:, key_prefix: nil)
      reader = FileReader.new(dir)

      seen = Set.new
      rows = reader.rows(filename: filename, header_row_number: 1, field_id_row_number: nil)
      configs = rows.map do |row|
        next if row.field_value(:skip, required: false)

        id =  row.field_value(:id, required: false)&.to_i
        label = normalize_label(row.field_value(:label))
        key = row.field_value(:key, required: false)
        prefix = row.field_value(:prefix, required: false)

        suffix = row.field_value(:suffix, required: false)
        suffix = suffix.is_a?(Float) ? suffix.to_i : suffix # this ends up as a float. Annoying.
        repeats = row.field_value(:repeats, required: false).present?
        field_type = row.field_value(:field_type, required: false) || 'string'

        key ||= label.size <= 50 ? label_to_key(label) : id_to_key(id)
        # ensure key is valid js identifier
        raise unless key && key =~ /\A[a-zA-Z_$][a-zA-Z\d_$]*\z/

        key = [prefix, key, suffix].compact.join('_')
        key = [key_prefix, key].compact.join('_') if key_prefix.present? && key !~ /\A#{key_prefix}_/
        raise "duplicate key #{key}" if key.in?(seen)

        seen.add key

        config = id ? { element_id: id } : {}
        config.merge({ label: label, key: key, repeats: repeats, field_type: field_type })
      end
      configs.compact
    end

    def normalize_label(value)
      value&.gsub(/\s+/, ' ')&.strip.presence
    end

    def label_to_key(label)
      label.downcase.gsub(/[^a-z0-9]+/, ' ').strip.gsub(' ', '_')
    end

    def id_to_key(id)
      "key_#{id}"
    end
  end
end
