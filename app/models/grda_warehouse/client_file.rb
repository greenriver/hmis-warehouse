###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientFile < GrdaWarehouse::File
    # attr_accessor :requires_expiration_date
    # attr_accessor :requires_effective_date
    attr_accessor :callbacks_skipped
    include ClientFileBase
    include ArelHelper

    mount_uploader :file, FileUploader # This is probably no necessary, but added to be safe
    acts_as_taggable

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :vispdat, class_name: 'GrdaWarehouse::Vispdat::Base', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
    validates_inclusion_of :visible_in_window, in: [true, false]
    validates_presence_of :expiration_date, on: :requires_expiration_date, message: 'Expiration date is required'
    validates_presence_of :effective_date, on: :requires_effective_date, message: 'Effective date is required'

    # because Rails cannot supply two contexts at once
    validates_presence_of :effective_date, on: :requires_expiration_and_effective_dates, message: 'Effective date is required'
    validates_presence_of :expiration_date, on: :requires_expiration_and_effective_dates, message: 'Expiration date is required'

    validates :data_source, presence: true, if: ->(o) { o.confidential? && o.enrollment_id.blank? }
    validates :enrollment, presence: true, if: ->(o) { o.confidential? && o.data_source_id.blank? }

    scope :confidential, -> do
      where(confidential: true)
    end

    scope :non_confidential, -> do
      where(confidential: false)
    end

    scope :window, -> do
      where(visible_in_window: true)
    end

    # Confidential files are visible by users who have access to confidential files at the associated project,
    # OR if the file does not have an associated enrollment and the user can view some confidential files
    scope :confidential_visible_by, ->(user) do
      permission = :can_see_confidential_files
      return none unless user&.send("#{permission}?")

      project_ids = user.viewable_project_ids(permission)
      return none unless project_ids.present?
      # If have a set (not a nil) and it's empty, this user can't access any projects
      raise 'Unexpected response from user.viewable_project_ids' unless project_ids.is_a?(Set)

      data_source_ids = GrdaWarehouse::Hud::Project.where(id: project_ids).distinct.pluck(:data_source_id)
      confidential_data_source_scope = confidential.where(data_source_id: data_source_ids)

      return confidential_data_source_scope if project_ids.empty?

      confidential_with_enrollment_scope = confidential.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(id: project_ids)).select(:id)

      where(id: confidential_with_enrollment_scope).
        or(where(id: confidential_data_source_scope.select(:id)))
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
      consent_form_tagging_ids = Rails.cache.fetch('consent_form_tagging_ids/tag_ids', expires_in: 2.minutes) do
        consent_form_tag_ids = ActsAsTaggableOn::Tag.where(
          name: GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name),
        ).pluck(:id)

        ActsAsTaggableOn::Tagging.where(tag_id: consent_form_tag_ids).
          where(taggable_type: 'GrdaWarehouse::File').
          pluck(:taggable_id)
      end

      where(id: consent_form_tagging_ids)
    end

    scope :non_consent, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), exclude: true)
      consent_form_tagging_ids = Rails.cache.fetch('consent_form_tagging_ids/tag_ids', expires_in: 2.minutes) do
        consent_form_tag_ids = ActsAsTaggableOn::Tag.where(
          name: GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name),
        ).pluck(:id)

        ActsAsTaggableOn::Tagging.where(tag_id: consent_form_tag_ids).
          where(taggable_type: 'GrdaWarehouse::File').
          pluck(:taggable_id)
      end

      where.not(id: consent_form_tagging_ids)
    end

    scope :verified_homeless_history, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), any: true)
      verified_homeless_history_tagging_ids = Rails.cache.fetch('verified_homeless_history_tagging_ids/tag_ids', expires_in: 2.minutes) do
        verified_homeless_history_tag_ids = ActsAsTaggableOn::Tag.where(
          name: GrdaWarehouse::AvailableFileTag.verified_homeless_history.pluck(:name),
        ).pluck(:id)

        ActsAsTaggableOn::Tagging.where(tag_id: verified_homeless_history_tag_ids).
          where(taggable_type: 'GrdaWarehouse::File').
          pluck(:taggable_id)
      end

      where(id: verified_homeless_history_tagging_ids)
    end

    scope :recent_ce_self_report_certification, -> do
      # NOTE: tagged_with does not work correctly in testing
      # tagged_with(GrdaWarehouse::AvailableFileTag.consent_forms.pluck(:name), any: true)
      ce_self_report_certification_tag_ids_tagging_ids = Rails.cache.fetch('ce_self_report_certification_tag_ids_tagging_ids/tag_ids', expires_in: 2.minutes) do
        ce_self_report_certification_tag_ids = ActsAsTaggableOn::Tag.where(
          name: GrdaWarehouse::AvailableFileTag.ce_self_report_certification.pluck(:name),
        ).pluck(:id)

        ActsAsTaggableOn::Tagging.where(tag_id: ce_self_report_certification_tag_ids).
          where(taggable_type: 'GrdaWarehouse::File').
          pluck(:taggable_id)
      end
      where(id: ce_self_report_certification_tag_ids_tagging_ids, effective_date: 1.years.ago.to_date..)
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

    scope :unprocessed_s3_migration, -> do
      # plucking these seems to be 100x faster than where.not(id: migrated)
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::File').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    ####################
    # Callbacks
    ####################
    after_create_commit :notify_users, if: ->(m) { m.should_run_callbacks? }
    before_save :adjust_consent_date, if: ->(m) { m.should_run_callbacks? }
    after_save :note_changes_in_consent, if: ->(m) { m.should_run_callbacks? }
    after_commit :set_client_consent, on: [:create, :update], if: ->(m) { m.should_run_callbacks? }

    def should_run_callbacks?
      callbacks_skipped.nil? || ! callbacks_skipped
    end

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
      full_string = Translation.translate(consent_type)
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
            consent_expires_on: expiration_date,
          )
        end
      else
        consent_form_ids = self.class.consent_forms.confirmed.where(client_id: client_id).pluck(:id)
        no_other_confirmed_consent_files = (consent_form_ids.count.zero? && ! consent_form_confirmed) || (consent_form_ids.count == 1 && consent_form_ids.first == id)

        if consent_form_confirmed && consent_revoked_at.blank?
          client.update_columns(
            housing_release_status: consent_type,
            consent_form_signed_on: consent_form_signed_on,
            consent_form_id: id,
            consented_coc_codes: coc_codes_chosen,
            consent_expires_on: expiration_date,
          )
        elsif no_other_confirmed_consent_files
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
      errors.add :client_file, 'No uploaded file found' if (client_file.byte_size || 0) < 100
      errors.add :client_file, 'File size should be less than 12 MB' if (client_file.byte_size || 0) > 12.megabytes
    end

    def note_if_other
      errors.add :note, 'Note is required if Other is chosen above' if tag_list.include?('Other') && note.blank?
    end

    def enrollments_for_confidential_files(user, destination_client)
      permission = :can_see_confidential_files
      ids = user.viewable_project_ids(permission)
      destination_client.source_enrollments.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(id: ids)).
        preload(:project).
        map do |en|
          [
            "#{en.entry_date} - #{en.project.name(user, include_project_type: true)}",
            en.id,
          ]
        end
    end

    # Any data sources where this user can see confidential filees
    def data_sources_for_confidential_files(user)
      permission = :can_see_confidential_files
      project_ids = user.viewable_project_ids(permission)
      return [] if project_ids.blank?

      GrdaWarehouse::DataSource.where(id: GrdaWarehouse::Hud::Project.where(id: project_ids).select(:data_source_id)).
        map do |ds|
          [
            ds.name,
            ds.id,
          ]
        end
    end

    def copy_to_s3!
      return unless content.present?
      return if client_file.attached? # don't re-process

      # Prevent any callbacks
      @callbacks_skipped = true

      puts "Migrating #{file} to S3 for client_id: #{client_id}"

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        client_file.attach(io: tmp_file, content_type: content_type, filename: file, identify: false)

        # Save no-matter validity state
        save!(validate: false)
      end
      @callbacks_skipped = nil
    end
  end
end
