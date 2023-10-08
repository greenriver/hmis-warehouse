###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Publish
  extend ActiveSupport::Concern
  include WarehouseReports::S3Toolset
  included do
    def self.published(version_slug)
      where(version_slug: version_slug).where.not(published_url: nil).first
    end

    def publish_warning
      previously_published = self.class.published(version_slug)
      return nil if previously_published.blank? || previously_published.id == id

      "Publishing this version of the #{instance_title} will remove any similar previously published version regardless of who published it.  The currently published version is from #{previously_published.completed_at.to_date}.  Are you sure you want to un-publish the previous version and publish this version?"
    end

    def un_publish_warning
      'Un-publishing this report will prevent anyone from accessing the published version of this report.  It will delete any existing web pages that have been published, and if the pages are embedded in a public website, those pages may not function correctly.'
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
      self.class.transaction do
        unpublish_similar
        update(
          html: as_html,
          published_url: generate_publish_url,
          embed_code: generate_embed_code,
          state: :published,
        )
      end
      push_to_s3
    end

    # Remove the files from S3
    # mark the report as not published
    def unpublish!
      remove_from_s3
      update(
        published_url: nil,
        embed_code: nil,
        html: nil,
        state: 'pre-calculated',
      )
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
        where.not(id: id).
        update_all(
          type: type,
          published_url: nil,
          embed_code: nil,
          html: nil,
          state: 'pre-calculated',
        )
    end
  end
end
