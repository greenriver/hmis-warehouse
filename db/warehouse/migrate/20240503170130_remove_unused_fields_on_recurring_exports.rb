class RemoveUnusedFieldsOnRecurringExports < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      {
        start_date: :date,
        end_date: :date,
        version: :string,
        hash_status: :integer,
        period_type: :integer,
        include_deleted: :boolean,
        directive: :integer,
        faked_pii: :boolean,
        confidential: :boolean,
        project_group_ids: :string,
        organization_ids: :string,
        data_source_ids: :string,
      }.each do |col, fmt|
        remove_column :recurring_hmis_exports, col, fmt
      end
    end
  end
end
