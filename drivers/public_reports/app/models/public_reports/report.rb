###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
module PublicReports
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    include S3Toolset
    include Filter::FilterScopes
    include ArelHelper
    belongs_to :user
    scope :viewable_by, ->(user) do
      return current_scope if user.can_view_all_reports?

      where(user_id: user.id)
    end

    scope :diet, -> do
      select(attribute_names - ['html', 'precalculated_data'])
    end

    def self.published
      where.not(published_url: nil).first
    end

    def publish_warning
      previously_published = self.class.published
      return unless previously_published.present?

      "Publishing this version of the #{instance_title} will remove any previously published version regardless of who published it.  The currently published version is from #{self.class.published.completed_at.to_date}.  Are you sure you want to un-publish the previous version and publish this version?"
    end

    def settings
      @settings ||= PublicReports::Setting.first_or_create
    end

    def chart_color_pattern
      settings.color_pattern.to_json.html_safe
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
      @filter_object ||= ::Filters::FilterBase.new(user_id: user.id).set_from_params(filter['filters'].merge(enforce_one_year_range: false).with_indifferent_access)
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
      self.class.transaction do
        unpublish_similar
        update(
          html: content,
          published_url: generate_publish_url,
          embed_code: generate_embed_code,
          state: :published,
        )
      end
      push_to_s3
    end

    def view_template
      :raw
    end

    def html_section_start(section)
      "<!-- SECTION START #{section} -->"
    end

    def html_section_end(section)
      "<!-- SECTION END #{section} -->"
    end

    # return only the "page" for a given section
    def html_section(section)
      html[/#{html_section_start(section)}(.*?)#{html_section_end(section)}/m, 1]
    end

    private def generate_embed_code
      "<iframe width='500' height='400' src='#{generate_publish_url}' frameborder='0' sandbox><a href='#{generate_publish_url}'>#{instance_title}</a></iframe>"
    end

    private def unpublish_similar
      self.class.update_all(type: type, published_url: nil, embed_code: nil, html: nil, state: 'pre-calculated')
    end

    def font_path
      settings.font_path
    end

    def font_family
      settings.font_family
    end

    def font_size
      settings.font_size
    end

    def font_weight
      settings.font_weight
    end

    private def start_report
      update(started_at: Time.current, state: :started)
    end

    private def complete_report
      update(completed_at: Time.current, state: 'pre-computed')
    end
  end
end
