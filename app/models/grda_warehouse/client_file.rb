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

    scope :non_consent, -> do
      tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), exclude: true)
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
    before_save :adjust_consent_date
    after_save :note_changes_in_consent
    after_commit :set_client_consent, on: [:create, :update]

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

    def active_consent_form?
      client.consent_form_id == id
    end

    def consent_type
      if GrdaWarehouse::AvailableFileTag.full_release?(tag_list)
        GrdaWarehouse::Hud::Client.full_release_string
      elsif GrdaWarehouse::AvailableFileTag.partial_consent?(tag_list)
        GrdaWarehouse::Hud::Client.partial_release_string
      end
    end

    def confirm_consent!
      update(consent_form_confirmed: true)
      note_changes_in_consent
      set_client_consent
    end

    def adjust_consent_date
      if GrdaWarehouse::AvailableFileTag.contains_consent_form?(tag_list)
        self.consent_form_signed_on = effective_date
      end
    end

    def note_changes_in_consent
      @consent_form_signed_on_changed_recently = consent_form_signed_on_changed? || false
      @consent_form_confirmed_changed_recently = consent_form_confirmed_changed? || false
    end

    def set_client_consent
      # If the client consent is not valid,
      # update client to match file (don't overwrite with blanks)
      #
      # If the consent if valid on the client,
      # remove consent only if the confirmation was also changed and this is the only confirmed consent file

      if ! client.consent_form_valid?
        if consent_form_signed_on.present?
          client.update_column(:consent_form_signed_on, consent_form_signed_on)
        end
        if consent_form_confirmed
          client.update_columns(
            housing_release_status: consent_type,
            consent_form_signed_on: consent_form_signed_on,
            consent_form_id: id
          )
        end
      else
        consent_form_ids = self.class.consent_forms.confirmed.pluck(:id)
        no_other_confirmed_consent_files = consent_form_ids.count == 0 && ! consent_form_confirmed || consent_form_ids.count == 1 && consent_form_ids.first == id

        if consent_form_confirmed
          client.update_columns(
            housing_release_status: consent_type,
            consent_form_signed_on: consent_form_signed_on,
            consent_form_id: id
          )
        elsif no_other_confirmed_consent_files
          client.invalidate_consent!
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
      errors.add :file, "File size should be less than 4 MB" if (content&.size || 0) > 2.megabytes
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
