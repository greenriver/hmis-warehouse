###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    belongs_to :user
    scope :viewable_by, ->(user) do
      return current_scope if user.can_view_all_reports?

      where(user_id: user.id)
    end

    def status
      if started_at.blank?
        "Queued at #{created_at}"
      elsif started_at.present? && completed_at.blank?
        if started_at < 24.hours.ago
          'Failed'
        else
          "Running since #{started_at}"
        end
      elsif completed?
        'Complete'
      end
    end

    def completed?
      completed_at.present?
    end

    def filter_object
      @filter_object ||= ::Filters::FilterBase.new.set_from_params(filter['filters'].merge(enforce_one_year_range: false).with_indifferent_access)
    end

    def published?
      published_url.present?
    end

    def published_at
      return unless published?

      updated_at
    end

    def publish!(content)
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      update(
        html: content,
        published_url: generate_publish_url,
        embed_code: generate_embed_code,
        state: :published,
      )
      push_to_s3
    end

    private def push_to_s3
      'TODO'
    end

    def font_path
      # TODO: use settings object
      '//fonts.googleapis.com/css?family=Open+Sans:300,400,400italic,600,700|Open+Sans+Condensed:700|Poppins:400,300,500,700'
    end
  end
end
