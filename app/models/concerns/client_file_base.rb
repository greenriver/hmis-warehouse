###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientFileBase
  extend ActiveSupport::Concern
  include ArelHelper

  included do
    has_one_attached :client_file

    validates_presence_of :name
    validate :file_exists_and_not_too_large
    validate :note_if_other

    scope :newest_first, -> do
      order(created_at: :desc)
    end

    scope :non_cache, -> do
      where.not(name: 'Client Headshot Cache')
    end

    scope :client_photos, -> do
      tagged_with('Client Headshot')
    end

    # def tags
    #   GrdaWarehouse::AvailableFileTag.where(id: tag_list)
    # end

    def file_exists_and_not_too_large
      errors.add :client_file, 'No uploaded file found' if (client_file.byte_size || 0) < 100
      errors.add :client_file, 'File size should be less than 4 MB' if (client_file.byte_size || 0) > 4.megabytes
    end

    def note_if_other
      errors.add :note, 'Note is required if Other is chosen above' if tag_list.include?('Other') && note.blank?
    end

    def self.all_available_tags
      GrdaWarehouse::AvailableFileTag.all
    end

    def self.grouped_available_tags
      GrdaWarehouse::AvailableFileTag.grouped
    end

    def self.available_tags
      # To maintain default behavior for warehouse
      grouped_available_tags
    end

    def as_preview
      return client_file.download unless client_file.variable?

      client_file.variant(resize_to_limit: [1920, 1080]).processed.download
    end

    def as_thumb
      return nil unless client_file.variable?

      client_file.variant(resize_to_limit: [400, 400]).processed.download
    end
  end
end
