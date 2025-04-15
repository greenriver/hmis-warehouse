class FixJsonSerialization < ActiveRecord::Migration[7.1]
  # Define the model locally to avoid dependency on the main application code
  # which might change in the future, breaking older migrations.
  class HmisSupplementalFieldValue < ActiveRecord::Base
    self.table_name = 'hmis_supplemental_field_values'
  end

  def up
    say_with_time "Converting YAML data to JSON in hmis_supplemental_field_values" do
      HmisSupplementalFieldValue.find_each do |record|
        next if record.data.nil?
        raise "Unexpected data type in hmis_supplemental_field_values ID #{record.id}: #{record.data.class}" unless record.data.is_a?(String)

        # Check if data is a non-empty string before parsing
        if record.data.present?
          parsed_data = YAML.safe_load(record.data, permitted_classes: [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
          # Use update_column to skip validations and callbacks for performance
          record.update_column(:data, parsed_data)
        else
          # Ensure nil or empty strings become null in the jsonb column
          record.update_column(:data, nil)
        end
      end
    end
    # Add similar blocks here for other tables if needed
  end

  def down
    say_with_time "Converting JSON data back to YAML string in hmis_supplemental_field_values" do
      HmisSupplementalFieldValue.find_each do |record|
        # Check if data is not nil before attempting to dump
        if record.data.present?
          # The raw jsonb type might be Hash or Array, convert it back to YAML string
           record.update_column(:data, record.data.to_yaml)
        else
           # Keep nil as nil
           record.update_column(:data, nil)
        end
      end
    end
     # Add similar blocks here for other tables if needed
  end
end
