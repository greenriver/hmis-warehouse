module GrdaWarehouse::WarehouseReports
  class ProjectContact < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :project, class_name: GrdaWarehouse::Hud::Project
    has_many :data_qualilty_reports, class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name
    has_many :report_tokens, -> { where(contact_id: id)}, class_name: GrdaWarehouse::ReportToken.name

    validates_email_format_of :email

    def full_name
      "#{first_name} #{last_name}"
    end
  end
end