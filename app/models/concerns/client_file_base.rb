###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientFileBase
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    acts_as_taggable

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    validates_presence_of :name
    validate :file_exists_and_not_too_large
    validate :note_if_other
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
    has_one_attached :client_file

    scope :newest_first, -> do
      order(created_at: :desc)
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

    scope :non_cache, -> do
      where.not(name: 'Client Headshot Cache')
    end

    scope :client_photos, -> do
      tagged_with('Client Headshot')
    end
  end

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

  def file_exists_and_not_too_large
    errors.add :client_file, 'No uploaded file found' if (client_file.byte_size || 0) < 100
    errors.add :client_file, 'File size should be less than 4 MB' if (client_file.byte_size || 0) > 4.megabytes
  end

  def note_if_other
    errors.add :note, 'Note is required if Other is chosen above' if tag_list.include?('Other') && note.blank?
  end

  def self.available_tags
    GrdaWarehouse::AvailableFileTag.grouped
  end

  def as_preview
    return client_file.download unless client_file.variable?

    client_file.variant(resize_to_limit: [1920, 1080]).processed.download
  end

  def as_thumb
    return nil unless client_file.variable?

    client_file.variant(resize_to_limit: [400, 400]).processed.download
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
