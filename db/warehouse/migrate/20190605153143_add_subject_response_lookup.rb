class AddSubjectResponseLookup < ActiveRecord::Migration[4.2]
  def change
    add_column :bo_configs, :subject_response_lookup_cuid, :string
  end
end
