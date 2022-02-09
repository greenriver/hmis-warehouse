###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    include Reporting::Status
    belongs_to :user, optional: true
    scope :viewable_by, ->(user) do
      return current_scope if user.can_view_all_reports?

      where(user_id: user.id)
    end

    scope :diet, -> do
      select(attribute_names - ['html', 'precalculated_data'])
    end

    def self.published(version_slug)
      where(version_slug: version_slug).where.not(published_url: nil).first
    end

    def publish_warning
      previously_published = self.class.published(version_slug)
      return nil if previously_published.blank? || previously_published.id == id

      "Publishing this version of the #{instance_title} will remove any similar previously published version regardless of who published it.  The currently published version is from #{previously_published.completed_at.to_date}.  Are you sure you want to un-publish the previous version and publish this version?"
    end

    # Override as necessary
    def generate_publish_url
      publish_url = if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}"
      end
      publish_url = "#{publish_url}/#{version_slug}" if version_slug.present?
      "#{publish_url}/index.html"
    end

    def settings
      @settings ||= PublicReports::Setting.first_or_create
    end

    def chart_color_pattern(category = nil)
      settings.color_pattern(category).to_json.html_safe
    end

    def chart_color_shades(category = nil)
      (settings.color_shades(category) + ['#FFFFFF']).reverse
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

    def publish!
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      unless published?
        self.class.transaction do
          unpublish_similar
          update(
            html: as_html,
            published_url: generate_publish_url,
            embed_code: generate_embed_code,
            state: :published,
          )
        end
      end
      push_to_s3
    end

    def as_html
      return controller_class.render(view_template, layout: 'raw_public_report', assigns: { report: self }) unless view_template.is_a?(Array)

      view_template.map do |template|
        string = html_section_start(template)
        string << controller_class.render(template, layout: 'raw_public_report', assigns: { report: self })
        string << html_section_end(template)
      end.join
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
      html[/(#{html_section_start(section)}.*?#{html_section_end(section)})/m, 1]
    end

    private def generate_embed_code
      "<iframe width='500' height='400' src='#{generate_publish_url}' frameborder='0' sandbox='allow-scripts'><a href='#{generate_publish_url}'>#{instance_title}</a></iframe>"
    end

    private def unpublish_similar
      self.class.
        where(version_slug: version_slug).
        update_all(
          type: type,
          published_url: nil,
          embed_code: nil,
          html: nil,
          state: 'pre-calculated',
        )
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
