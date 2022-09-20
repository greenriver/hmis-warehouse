###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    # attr_accessor :requires_expiration_date
    # attr_accessor :requires_effective_date
    # TODO: This can be removed after merging https://github.com/greenriver/hmis-warehouse/pull/611
    attr_accessor :coc_code

    # FIXME: temporary alias pending merge multi-coc code
    alias_attribute :coc_code, :coc_codes

    acts_as_taggable

    include ArelHelper

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :vispdat, class_name: 'GrdaWarehouse::Vispdat::Base', optional: true
    validates_presence_of :name
    validates_inclusion_of :visible_in_window, in: [true, false]
    validate :file_exists_and_not_too_large
    validate :note_if_other
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

    validates_presence_of :expiration_date, on: :requires_expiration_date, message: 'Expiration date is required'
    validates_presence_of :effective_date, on: :requires_effective_date, message: 'Effective date is required'

    # because Rails cannot supply two contexts at once
    validates_presence_of :effective_date, on: :requires_expiration_and_effective_dates, message: 'Effective date is required'
    validates_presence_of :expiration_date, on: :requires_expiration_and_effective_dates, message: 'Expiration date is required'

    scope :window, -> do
      where(visible_in_window: true)
    end

    scope :visible_by?, ->(user) do
      return current_scope if user.can_manage_client_files?

      # setup sql statements
      is_own_file = arel_table[:user_id].eq(user.id)
      is_verified_homeless_history = arel_table[:id].in(Arel.sql(verified_homeless_history.select(:id).to_sql))
      is_not_verified_homeless_history = arel_table[:id].not_in(Arel.sql(verified_homeless_history.select(:id).to_sql))
      is_consent_form = arel_table[:id].in(Arel.sql(consent_forms.select(:id).to_sql))
      has_full_housing_release = arel_table[:client_id].in(
        Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql),
      )

      # show your own files
      sql = is_own_file
      # show all verified homeless histories based on site config
      sql = sql.or(is_verified_homeless_history) if GrdaWarehouse::Config.get(:verified_homeless_history_visible_to_all)
      # show all consents based on site config
      sql = sql.or(is_consent_form) if GrdaWarehouse::Config.get(:consent_visible_to_all)

      if user.can_manage_window_client_files?
        if ::GrdaWarehouse::Config.get(:verified_homeless_history_method).to_sym == :release
          # show verified homeless histories for clients with full release in the current user's coc
          #   note: the verified_homeless_history_visible_to_all setting overrides this by including all
          clients_with_consent = GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(user.coc_codes).select(:id)
          sql = sql.or(arel_table[:client_id].in(Arel.sql(clients_with_consent.to_sql)).and(is_verified_homeless_history))

          # show all NON-verified-homeless-history files for clients with full releases (regardless of CoC)
          sql = sql.or(has_full_housing_release.and(is_not_verified_homeless_history))
        else
          # show all files for clients with full releases
          sql = sql.or(has_full_housing_release)
        end

        window.where(sql)
      # You can only see files you uploaded
      elsif user.can_see_own_file_uploads? || user.can_use_separated_consent?
        where(sql)
      # You have specific permission to generate homeless verification PDFs
      elsif user.can_generate_homeless_verification_pdfs? && GrdaWarehouse::Config.get(:verified_homeless_history_visible_to_all)
        where(is_verified_homeless_history)
      elsif user.can_generate_homeless_verification_pdfs?
        where(is_own_file.and(is_verified_homeless_history))
      else
        none
      end
    end

    scope :editable_by?, ->(user) do
      # If you can see all client files, show everything
      if user.can_manage_client_files?
        current_scope
      # If all you can see are window files or your own files
      #   show only those you uploaded
      elsif user.can_manage_window_client_files? || user.can_see_own_file_uploads?
        where(user_id: user.id)
      else
        none
      end
    end

    scope :consent_forms, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), any: true)
      consent_form_tag_ids = ActsAsTaggableOn::Tag.where(
        name: GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name),
      ).pluck(:id)
      consent_form_tagging_ids = ActsAsTaggableOn::Tagging.where(tag_id: consent_form_tag_ids).
        where(taggable_type: 'GrdaWarehouse::File').
        pluck(:taggable_id)

      where(id: consent_form_tagging_ids)
    end

    scope :non_consent, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), exclude: true)
      consent_form_tag_ids = ActsAsTaggableOn::Tag.where(
        name: GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name),
      ).pluck(:id)
      consent_form_tagging_ids = ActsAsTaggableOn::Tagging.where(tag_id: consent_form_tag_ids).
        where(taggable_type: 'GrdaWarehouse::File').
        pluck(:taggable_id)

      where.not(id: consent_form_tagging_ids)
    end

    scope :non_cache, -> do
      where.not(name: 'Client Headshot Cache')
    end

    scope :verified_homeless_history, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), any: true)
      verified_homeless_history_tag_ids = ActsAsTaggableOn::Tag.where(
        name: GrdaWarehouse::AvailableFileTag.verified_homeless_history.pluck(:name),
      ).pluck(:id)
      verified_homeless_history_tagging_ids = ActsAsTaggableOn::Tagging.where(tag_id: verified_homeless_history_tag_ids).
        where(taggable_type: 'GrdaWarehouse::File').
        pluck(:taggable_id)

      where(id: verified_homeless_history_tagging_ids)
    end

    scope :confirmed, -> do
      where(consent_form_confirmed: true, consent_revoked_at: nil)
    end

    scope :unconfirmed, -> do
      where(consent_form_confirmed: [false, nil])
    end

    scope :signed_on, ->(date) do
      where(consent_form_signed_on: date)
    end

    scope :signed, -> do
      where.not(consent_form_signed_on: nil)
    end

    scope :verification_of_disability, -> do
      tags = GrdaWarehouse::AvailableFileTag.tag_includes('Verification of Disability').map(&:name)
      tagged_with(tags, any: true)
    end

    scope :notification_triggers, -> do
      tagged_with(GrdaWarehouse::AvailableFileTag.notification_triggers.pluck(:name), any: true)
    end

    scope :for_coc, ->(coc_codes) do
      coc_codes = Array.wrap(coc_codes) + [nil, '']
      where(coc_codes: coc_codes)
    end

    ####################
    # Callbacks
    ####################
    after_create_commit :notify_users
    before_save :adjust_consent_date
    after_save :note_changes_in_consent
    after_commit :set_client_consent, on: [:create, :update]

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_manage_window_client_files? || user.can_see_own_file_uploads? || user.can_use_separated_consent?
    end

    def editable_by?(user)
      return true if user.can_manage_client_files?
      return true if (user.can_manage_window_client_files? || user.can_see_own_file_uploads?) && user_id == user.id

      false
    end

    def uploaded_by?(user)
      user_id == user.id
    end

    def active_consent_form?
      client.consent_form_id == id
    end

    def consent_form?
      self.class.consent_forms.where(id: id).exists?
    end

    def revoked?
      consent_revoked_at.present?
    end

    def consent_type
      if GrdaWarehouse::AvailableFileTag.coc_level_release?(tag_list)
        # release_type = GrdaWarehouse::Hud::Client.full_release_string
        # if self.coc_codes.present?
        #   "#{release_type} for CoC #{coc_codes.to_sentence}"
        # else
        #   "#{release_type} for all CoCs"
        # end
        GrdaWarehouse::Hud::Client.full_release_string
      elsif GrdaWarehouse::AvailableFileTag.full_release?(tag_list)
        GrdaWarehouse::Hud::Client.full_release_string
      elsif GrdaWarehouse::AvailableFileTag.partial_consent?(tag_list)
        GrdaWarehouse::Hud::Client.partial_release_string
      end
    end

    def consent_type_with_extras
      full_string = _(consent_type)
      full_string += " in #{coc_codes.to_sentence}" if coc_codes&.any?
      full_string
    end

    def confirm_consent!
      update(consent_form_confirmed: true)
      note_changes_in_consent
      set_client_consent
    end

    def adjust_consent_date
      self.consent_form_signed_on = effective_date if GrdaWarehouse::AvailableFileTag.contains_consent_form?(tag_list)
    end

    def note_changes_in_consent
      @consent_form_signed_on_changed_recently = saved_change_to_consent_form_signed_on? || false
      @consent_form_confirmed_changed_recently = saved_change_to_consent_form_confirmed? || false
    end

    def set_client_consent
      # If the client consent is not valid,
      # update client to match file (don't overwrite with blanks)
      #
      # If the consent if valid on the client,
      # remove consent only if the confirmation was also changed and this is the only confirmed consent file

      return unless consent_form?

      coc_codes_chosen = if coc_codes.include?('All CoCs')
        ['All CoCs']
      elsif coc_available?
        coc_codes.presence || ['All CoCs']
      else
        []
      end

      if ! client.consent_form_valid?
        client.update_column(:consent_form_signed_on, consent_form_signed_on) if consent_form_signed_on.present? && consent_revoked_at.blank?

        if consent_form_confirmed && consent_revoked_at.blank?
          client.update_columns(
            housing_release_status: consent_type,
            consent_form_signed_on: consent_form_signed_on,
            consent_form_id: id,
            consented_coc_codes: coc_codes_chosen,
          )
        end
      else
        consent_form_ids = self.class.consent_forms.confirmed.where(client_id: client_id).pluck(:id)
        no_other_confirmed_consent_files = consent_form_ids.count.zero? && ! consent_form_confirmed || consent_form_ids.count == 1 && consent_form_ids.first == id

        if consent_form_confirmed && consent_revoked_at.blank?
          client.update_columns(
            housing_release_status: consent_type,
            consent_form_signed_on: consent_form_signed_on,
            consent_form_id: id,
            consented_coc_codes: coc_codes_chosen,
          )
        elsif no_other_confirmed_consent_files || consent_form_ids.blank?
          client.invalidate_consent!
        end
      end
    end

    private def coc_available?
      (GrdaWarehouse::AvailableFileTag.consent_forms.where(coc_available: true).pluck(:name) & tag_list).present?
    end

    def notify_users
      return if name == 'Client Headshot Cache'
      return unless client.present?

      # notify related users if the client has a full release and the file is visible in the window
      NotifyUser.file_uploaded(id).deliver_later if client.release_valid? && visible_in_window
      # Send out administrative notifications as appropriate
      FileNotificationMailer.notify(client.id).deliver_later if GrdaWarehouse::AvailableFileTag.should_send_notifications?(tag_list)
    end

    def file_exists_and_not_too_large
      errors.add :file, 'No uploaded file found' if (content&.size || 0) < 100
      errors.add :file, 'File size should be less than 4 MB' if (content&.size || 0) > 4.megabytes
    end

    def note_if_other
      errors.add :note, 'Note is required if Other is chosen above' if tag_list.include?('Other') && note.blank?
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
