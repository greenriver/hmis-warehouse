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
        options[field] = YAML.load(options[field].first).reject { |m| m.blank? } if options[field]&.first&.include?('---')
        exp.update!(options: options)
      end
    end
  end
end
