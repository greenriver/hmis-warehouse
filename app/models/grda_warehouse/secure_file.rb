###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

    scope :visible_by?, ->(user) do
      # If you can see all client files, show everything
      visible_scope = if user.can_view_all_secure_uploads?
        all
      # You can only see files you were sent
      elsif user.can_view_assigned_secure_uploads?
        where(recipient_id: user.id)
      else
        none
      end
      # all secure files expire after 1.month
      visible_scope.unexpired
    end

    scope :expired, -> do
      where(arel_table[:created_at].lt(1.months.ago.to_date))
    end

    scope :unexpired, -> do
      where(arel_table[:created_at].gteq(102.months.ago))
    end

    scope :diet_select, -> do
      select(*(column_names - ['content']))
    end

    def self.clean_expired
      expired.update_all(deleted_at: Time.now)
    end

    # for file migration
    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::SecureFile').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return unless valid? # Ignore uploads that are already invalid (data source deleted?)
      return if secure_file.attached? # don't re-process

      puts "Migrating #{file} to S3"

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        secure_file.attach(io: tmp_file, content_type: content_type, filename: file, identify: false)
      end

      # Save no-matter validity state
      self.content = nil
      save!(validate: false)
    end
    # END for file migration
  end
end
