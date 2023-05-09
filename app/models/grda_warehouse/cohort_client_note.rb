###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CohortClientNote < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :cohort_client
    has_one :client, through: :cohort_client
    belongs_to :user, optional: true

    attr_accessor :send_notification

    validates_presence_of :cohort_client, :note

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def destroyable_by user
      notes_column = cohort_client.cohort.column_state.find { |c| c.is_a?(CohortColumns::Notes) }
      notes_column.display_as_editable?(user, cohort_client, on_cohort: cohort_client.cohort)
    end

    def recipient_info
      return unless notification_contacts.present?

      "Note sent to: #{notification_contacts.to_sentence}"
    end

    private def notification_contacts
      ids = recipients&.reject(&:blank?)
      return unless ids.present?

      @notification_contacts ||= User.where(id: ids).map(&:name_with_email)
    end
  end
end
