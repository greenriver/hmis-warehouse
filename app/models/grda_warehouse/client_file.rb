module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    acts_as_taggable

    include ArelHelper

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :vispdat, class_name: 'GrdaWarehouse::Vispdat::Base'
    validates_presence_of :name
    validates_inclusion_of :visible_in_window, in: [true, false]
    validate :file_exists_and_not_too_large
    validate :note_if_other
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

    scope :editable_by?, -> (user) do
      # If you can see all client files, show everything
      if user.can_manage_client_files? 
        all
      # If all you can see are window files or your own files
      #   show only those you uploaded
      elsif user.can_manage_window_client_files? || user.can_see_own_file_uploads?
        where(user_id: user.id)
      else
        none
      end
    end

    scope :consent_forms, -> do
      tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), any: true)
    end
    
    scope :confirmed, -> do
      where(consent_form_confirmed: true)
    end
    
    scope :unconfirmed, -> do
      where(consent_form_confirmed: [false, nil])
    end

    scope :signed_on, -> (date) do
      where(consent_form_signed_on: date)
    end

    scope :signed, -> do
      where.not(consent_form_signed_on: nil)
    end

    scope :verification_of_disability, -> do
      tagged_with(['Verification of Disability', 'Disability Verification'], any: true)
    end

    scope :notification_triggers, -> do
      tagged_with(GrdaWarehouse::AvailableFileTag.notification_triggers.pluck(:name), any: true)
    end

    ####################
    # Callbacks
    ####################
    after_create :notify_users
    after_save :set_client_consent

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_manage_window_client_files? || user.can_see_own_file_uploads?
    end

    def editable_by?(user)
      return true if user.can_manage_client_files?
      return true if (user.can_manage_window_client_files? || user.can_see_own_file_uploads?) && user_id == user.id
      false
    end

    def confirm_consent!
      update(consent_form_confirmed: true)
    end

    def set_client_consent
      if consent_form_signed_on_changed?
        client.update_column :consent_form_signed_on, consent_form_signed_on
      end
      if consent_form_confirmed_changed?
        if consent_form_confirmed
          client.update_column(:housing_release_status, client.class.full_release_string)
        else
          client.update_column(:housing_release_status, '')
        end
      end
    end

    def notify_users
      if client.present?
        # notify related users if the client has a full release and the file is visible in the window
        if client.release_valid? && visible_in_window
          NotifyUser.file_uploaded( id ).deliver_later
        end
        # Send out administrative notifications as appropriate
        if GrdaWarehouse::AvailableFileTag.should_send_notifications?(tag_list)
          FileNotificationMailer.notify(client.id).deliver_later
        end
      end
    end

    def file_exists_and_not_too_large
      errors.add :file, "No uploaded file found" if (content&.size || 0) < 100
      errors.add :file, "Uploaded file must be less than 2 MB" if (content&.size || 0) > 2.megabytes
    end

    def note_if_other
      if tag_list.include?('Other') && note.blank?
        errors.add :note, "Note is required if Other is chosen above"
      end
    end

    def self.available_tags
      GrdaWarehouse::AvailableFileTag.grouped
    end

    def as_preview
      return content unless content_type == 'image/jpeg'
      image = MiniMagick::Image.read(content)
      image.auto_level
      image.strip
      image.resize('1920x1080')
      image.to_blob
    end

    def as_thumb
      return nil unless content_type == 'image/jpeg'
      image = MiniMagick::Image.read(content)
      image.auto_level
      image.strip
      image.resize('400x400')
      image.to_blob
    end

  end
end  
