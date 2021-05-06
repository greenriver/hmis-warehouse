class AddVersionSlugToPublicReports < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_reports, :version_slug, :string
  end
end
