###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Publish
  extend ActiveSupport::Concern
  include WarehouseReports::S3Toolset
  included do
    def self.published(path)
      GrdaWarehouse::PublishedReport.where(report_type: sti_name, path: path, state: 'published').first
    end

    # Override as necessary
    def publish_files
      [
        {
          name: 'index.html',
          content: -> { as_html },
          type: 'text/html',
        },
      ]
    end

    def publish_summary?
      false
    end

    def publish_warning
      previously_published = self.class.published(path)
      return nil if previously_published.blank?

      "Publishing this version of the #{instance_title} will remove any similar previously published version regardless of who published it.  The currently published version is from #{previously_published.updated_at.to_date}.  Are you sure you want to un-publish the previous version and publish this version?"
    end

    def un_publish_warning
      'Un-publishing this report will prevent anyone from accessing the published version of this report.  It will delete any existing web pages that have been published, and if the pages are embedded in a public website, those pages may not function correctly.'
    end

    # Your report is required to define public_s3_directory
    # private def public_s3_directory
    #   # This should return a string that represends the unique path for aLl reports of this type
    #   'path-to-report'
    # end

    # Override as necessary
    def generate_publish_url
      publish_url = if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}"
      end
      publish_url = "#{publish_url}/#{path}" if path.present?
      "#{publish_url}/index.html"
    end

    def published_report
      published&.last
    end

    private def published
      published_reports.published
    end

    def published?
      published.exists?
    end

    def published_at
      return unless published?

      published_report.updated_at
    end

    def publish!(user_id)
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      self.class.transaction do
        unpublish_similar
        published_report = published_reports.where(path: path).first_or_create
        premailer = Premailer.new(
          as_html,
          with_html_string: true,
          remove_scripts: false,
          reset_contenteditable: false,
          include_link_tags: false,
          escape_url_attributes: false,
        )

        published_report.update!(
          user_id: user_id,
          html: premailer.to_inline_css,
          published_url: generate_publish_url,
          embed_code: generate_embed_code,
          state: :published,
        )
      end
      push_all_to_s3
    end

    # Remove the files from S3
    # mark the report as not published
    def unpublish!
      remove_all_from_s3
      published_report = published_reports.where(path: path).first
      return unless published_report.present?

      published_report.update!(
        published_url: nil,
        embed_code: nil,
        html: nil,
        state: :unpublished,
      )
    end

    def as_html
      return controller_class.render(view_template, layout: raw_layout, assigns: { report: self }) unless view_template.is_a?(Array)

      view_template.map do |template|
        string = html_section_start(template)
        string << controller_class.render(template, layout: raw_layout, assigns: { report: self })
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
      published_reports.
        where(path: path).
        update_all(
          published_url: nil,
          embed_code: nil,
          html: nil,
          state: :unpublished,
        )
    end
  end
end
