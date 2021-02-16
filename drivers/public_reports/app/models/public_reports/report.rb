###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
module PublicReports
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
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

    private def generate_embed_code
      "<iframe width='500' height='400' src='#{generate_publish_url}' frameborder='0' sandbox><a href='#{generate_publish_url}'>#{instance_title}</a></iframe>"
    end

    private def unpublish_similar
      self.class.update_all(type: type, published_url: nil, embed_code: nil, state: 'pre-calculated')
    end

    private def s3_bucket
      ENV.fetch('S3_PUBLIC_BUCKET', "#{ENV.fetch('CLIENT')}-#{Rails.env}-public")
    end

    private def push_to_s3
      client = if ENV['S3_PUBLIC_ACCESS_KEY_ID'].present? && ENV['S3_PUBLIC_ACCESS_KEY_SECRET'].present?
        Aws::S3::Client.new(
          access_key_id: ENV.fetch('S3_PUBLIC_ACCESS_KEY_ID'),
          secret_access_key: ENV.fetch('S3_PUBLIC_ACCESS_KEY_SECRET'),
        )
      else
        Aws::S3::Client.new
      end
      bucket = s3_bucket
      prefix = public_s3_directory

      key = File.join(prefix, 'index.html')

      resp = client.put_object(
        acl: 'public-read',
        bucket: bucket,
        key: key,
        body: html,
      )
      if resp.etag
        Rails.logger.info 'Successfully uploaded maintenance file to s3'
      else
        Rails.logger.info 'Unable to upload maintenance file'
      end
    end

    def font_path
      # TODO: use settings object
      '//fonts.googleapis.com/css?family=Open+Sans:300,400,400italic,600,700|Open+Sans+Condensed:700|Poppins:400,300,500,700'
    end
  end
end
