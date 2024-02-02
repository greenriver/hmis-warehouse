###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class AvailableFileTag < GrdaWarehouseBase
    include DefaultFileTypes

    belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', primary_key: :name, foreign_key: :name, optional: true

    scope :ordered, -> do
      order(group: :asc, weight: :asc, name: :asc)
    end

    scope :consent_forms, -> do
      where(consent_form: true)
    end

    scope :verified_homeless_history, -> do
      where(verified_homeless_history: true)
    end

    scope :full_release, -> do
      consent_forms.where(full_release: true)
    end

    scope :partial_consent, -> do
      consent_forms.where(full_release: false)
    end

    scope :document_ready, -> do
      where(document_ready: true)
    end

    scope :notification_triggers, -> do
      where(notification_trigger: true)
    end

    scope :ce_self_report_certification, -> do
      where(ce_self_report_certification: true)
    end

    def required_by?(client)
      return true unless required_for.present? && self.class.available_required_for_options.values.include?(required_for)

      GrdaWarehouse::Hud::Client.send(required_for).where(id: client).exists?
    end

    def self.available_required_for_options
      {
        'Veterans' => 'veteran',
      }
    end

    def self.contains_consent_form?(tag_names = [])
      consent_forms.where(name: tag_names).exists?
    end

    def self.full_release?(tag_names = [])
      full_release.where(name: tag_names).exists?
    end

    def self.coc_level_release?(tag_names = [])
      full_release.where(name: tag_names, coc_available: true).exists?
    end

    def self.partial_consent?(tag_names = [])
      partial_consent.where(name: tag_names).exists?
    end

    def self.should_send_notifications?(tag_names = [])
      notification_triggers.where(name: tag_names).exists?
    end

    def self.grouped
      ordered.group_by(&:group)
    end

    def self.tag_includes(info_type)
      all.select do |tag|
        tag.included_info.present? && tag.included_info.split(',').map(&:strip).include?(info_type)
      end
    end

    # Taken from here:https://github.com/carrierwaveuploader/carrierwave-i18n/blob/master/rails/locales/en.yml
    # These don't get translated appropriately unless they are here
    # def translations
    #   Translation.translate("failed to be processed")
    #   Translation.translate("is not of an allowed file type")
    #   Translation.translate("could not be downloaded")
    #   Translation.translate("You are not allowed to upload %{extension} files, allowed types: %{allowed_types}")
    #   Translation.translate("You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}")
    #   Translation.translate("You are not allowed to upload %{content_type} files")
    #   Translation.translate("You are not allowed to upload %{content_type} files")
    #   Translation.translate("Failed to manipulate with rmagick, maybe it is not an image?")
    #   Translation.translate("Failed to manipulate with MiniMagick, maybe it is not an image? Original Error: %{e}")
    #   Translation.translate("File size should be greater than %{min_size}")
    #   Translation.translate("File size should be less than %{max_size}")
    # end
  end
end
