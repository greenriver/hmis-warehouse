###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class SecureFile < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :recipient, class_name: 'User'
    belongs_to :sender, class_name: 'User'
    validates_presence_of :name

    has_one_attached :secure_file

    # The following are only used on the form, we allow multiple recipients, but store one file per person
    # and we allow notifications, but don't log those, just need to know if we should send them or not
    attr_accessor :send_notifications, :recipients

    scope :viewable_by, ->(user) do
      # If you can see all client files, show everything
      visible_scope = if user.can_view_all_secure_uploads?
        all
      # Otherwise you can see files sent to you or that you uploaded yourself.
      # Access follows the role: lose the permission and you lose access to your
      # own past uploads too.
      elsif user.can_view_assigned_secure_uploads?
        where(recipient_id: user.id).or(where(sender_id: user.id))
      else
        none
      end
      # all secure files expire after 1.month
      visible_scope.unexpired
    end

    scope :received_by, ->(user) do
      scope = user.can_view_some_secure_files? ? where(recipient_id: user.id) : none
      scope.unexpired
    end

    scope :expired, -> do
      where(arel_table[:created_at].lt(1.months.ago.to_date))
    end

    scope :unexpired, -> do
      where(arel_table[:created_at].gteq(1.months.ago))
    end

    def self.clean_expired
      expired.update_all(deleted_at: Time.now)
    end
  end
end
