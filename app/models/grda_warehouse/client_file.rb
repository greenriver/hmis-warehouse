module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    acts_as_taggable

    include ArelHelper

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :vispdat, class_name: 'GrdaWarehouse::Vispdat::Base'
    validates_presence_of :name
    validates_inclusion_of :visible_in_window, in: [true, false]
    validate :file_exists_and_not_too_large
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

    scope :window, -> do
      where(visible_in_window: true)
    end

    scope :visible_by?, -> (user) do
      # If you can see all client files, show everything
      if user.can_manage_client_files? 
        all
      # If all you can see are window files:
      #   show those with full releases and those you uploaded
      elsif user.can_manage_window_client_files?
        window.joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].eq(user.id))
        )
      # You can only see files you uploaded
      elsif user.can_see_own_file_uploads?
        where(user_id: user.id)
      else
        none
      end
    end

    ####################
    # Callbacks
    ####################
    after_create :notify_users

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_manage_window_client_files? || user.can_see_own_file_uploads?
    end

    def notify_users
      if client.present?
        # notify related users if the client has a full release and the file is visible in the window
        if client.release_valid? && visible_in_window
          NotifyUser.file_uploaded( id ).deliver_later
        end
        # Send out administrative notifications as appropriate
        tag_list = ActsAsTaggableOn::Tag.where(name: self.tag_list).pluck(:id)
        notification_triggers = GrdaWarehouse::Config.get(:file_notifications).pluck(:id)
        to_send = tag_list & notification_triggers
        FileNotificationMailer.notify(to_send, client.id).deliver_later if to_send.any?
      end
    end

    def file_exists_and_not_too_large
      errors.add :file, "No uploaded file found" if (content&.size || 0) < 100
      errors.add :file, "Uploaded file must be less than 2 MB" if (content&.size || 0) > 2.megabytes
    end

    # Any of these tags could represent a full release
    def self.full_release_tags
      [
        'Consent Form',
        'Full Network Release',
      ]
    end

    def self.available_tags
      [
        'Birth Certificate',
        'Government ID',
        'Social Security Card',
        'Disability Verification',
        'Homeless Verification',
        'Veteran Verification',
        'Proof of Income',
        'Client Photo',
        'DD-214',
        'Consent Form',
        'Full Network Release',
        'Limited CAS Release',
        'Chronic Homelessness Verification',
        'BHA Eligibility',
        'Housing Authority Eligibility',
        'Other',
      ].sort.freeze
    end

    def self.document_ready_tags
      [
        'Birth Certificate',
        'Government ID',
        'Social Security Card',
        'Proof of Income',
      ]
    end
  end
end  
