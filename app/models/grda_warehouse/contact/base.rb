module GrdaWarehouse::Contact
  class Base < GrdaWarehouseBase
    self.table_name = :contacts
    acts_as_paranoid

    has_many :data_quality_reports, class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name
    has_many :report_tokens, -> { where(contact_id: id)}, class_name: GrdaWarehouse::ReportToken.name

    validates_email_format_of :email

    def full_name
      "#{first_name} #{last_name}"
    end

    def full_name_with_email
      "#{first_name} #{last_name} (#{email})"
    end
  end
end