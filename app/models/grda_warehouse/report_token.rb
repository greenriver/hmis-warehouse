###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ReportToken < GrdaWarehouseBase
    has_paper_trail

    belongs_to :report, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base', optional: true

    validates :token, uniqueness: true
    before_validation :setup_token

    def expired?
      Time.now > expires_at
    end

    # contact_id is a contacts.id for contact notifications, or a users.id for requestor notifications
    def valid_for?(report_id:, user:)
      return false if expired? || self.report_id != report_id.to_i

      return true if contact_id == user.id && report&.requestor_id == user.id

      report_recipient?(user)
    end

    private def report_recipient?(user)
      return false if report.nil?

      [
        report.project_contacts,
        report.organization_contacts,
        report.project_group_contacts,
        report.organization_project_group_contacts,
      ].any? { |contacts| contacts.where(id: contact_id, user_id: user.id).exists? }
    end

    def setup_token
      self.token ||= SecureRandom.urlsafe_base64
      self.expires_at ||= Time.now + 1.year
    end
  end
end
