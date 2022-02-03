###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class Import < HealthBase
    include ElapsedTimeHelper

    validates :source_url, presence: true

    def source_url_parsed
      # URI.schema_list for some reason doest
      # have file or sftp registered
      URI.scheme_list['SFTP'] ||=  URI::Generic
      URI.scheme_list['FILE'] ||=  URI::Generic

      @source_url_parsed ||= begin
                               URI.parse(source_url)
                             rescue StandardError
                               nil
                             end
    end

    # a possibly Rails.root relative path to identify the source file
    def source_path
      return source_url unless source_url_parsed

      if source_url_parsed.scheme == 'file'
        source_url_parsed.path.gsub(Rails.root.to_s + '/', '')
      else
        source_url_parsed.path
      end
    end

    def status_text
      if completed_at && successful
        "Completed after #{elapsed_time processing_time} seconds. #{lines_read} lines read."
      elsif completed_at && !successful
        "Failed after #{elapsed_time processing_time} seconds"
      elsif started_at && !successful
        'Started'
      end
    end

    def processing_time
      return unless started_at && completed_at

      completed_at - started_at
    end

    def lines_read
      return unless results.is_a?(Hash)

      results.values.map { |v| v['lines_read'] }.compact.sum
    end
  end
end
