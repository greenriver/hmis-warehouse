class RenameSubstanceAbuseDisorder < ActiveRecord::Migration[5.2]
  def change
    rename_column :hap_report_clients, :substance_abuse, :substance_abuse_disorder
  end
end
