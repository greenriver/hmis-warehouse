###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Contact
  class Base < GrdaWarehouseBase
    self.table_name = :contacts
    acts_as_paranoid

    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :report_tokens, foreign_key: :contact_id, class_name: 'GrdaWarehouse::ReportToken'

    validates_email_format_of :email

    def full_name
      "#{first_name} #{last_name}"
    end

    def full_name_with_email
      "#{first_name} #{last_name} (#{email})"
    end
  end
end
