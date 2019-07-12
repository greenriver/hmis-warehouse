class AddSubjectResponseLookup < ActiveRecord::Migration
  def change
    add_column :bo_configs, :subject_response_lookup_cuid, :string
  end
end
