module HealthFiles
  extend ActiveSupport::Concern
  included do

    accepts_nested_attributes_for :health_file, allow_destroy: true, reject_if: proc {|att| att['file'].blank? && att['file_cache'].blank? && att['note'].blank?}
    validates_associated :health_file

    def can_display_health_file?
      health_file.present? && health_file.size
    end

    def downloadable?
      health_file.present? && health_file.persisted?
    end

  end
end