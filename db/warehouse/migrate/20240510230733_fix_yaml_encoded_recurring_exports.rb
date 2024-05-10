class FixYamlEncodedRecurringExports < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::RecurringHmisExport.find_each do |exp|
      options = exp.options
      [
        'project_ids',
        'data_source_ids',
        'organization_ids',
        'project_group_ids',
      ].each do |field|
        options[field] = YAML.parse(options[field]).reject { |m| m.blank? } if options[field]&.first&.include?('---')
      end
    end
  end
end
