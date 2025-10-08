###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Contact
  class Base < GrdaWarehouseBase
    self.table_name = :contacts
    acts_as_paranoid

    # TODO: enable this after 20251007133153_fixup_contacts.rb is run (release-186 or later)
    # self.ignored_columns = ['first_name', 'last_name', 'email']

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :email

    belongs_to :user, optional: true
    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :report_tokens, foreign_key: :contact_id, class_name: 'GrdaWarehouse::ReportToken'

    def self.available_users(entity, include_current: false)
      scope = User.active.not_system.order(last_name: :asc, first_name: :asc)
      scope = scope.where.not(id: entity.contacts.pluck(:user_id)) unless include_current
      scope
    end

    def email
      user&.email || email
    end

    def full_name
      user&.name || 'Unknown'
    end

    def full_name_with_email
      user&.name_with_email || 'Unknown'
    end
  end
end
