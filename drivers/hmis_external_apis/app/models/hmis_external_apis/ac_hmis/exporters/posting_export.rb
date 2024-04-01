###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class PostingExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating content of posting export'

      write_row(columns)
      total = postings.count

      Rails.logger.error "There are #{total} postings to export. That doesn't look right" if total < 10

      postings.find_each.with_index do |posting, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        enrollment = posting.hoh_enrollment

        if enrollment.nil?
          Rails.logger.info "Skipping posting #{posting.identifier} because it's missing a HoH Enrollment"
          next
        end

        warehouse_id = enrollment.client.warehouse_id
        next unless warehouse_id.present?

        values = [
          warehouse_id, # PersonalID matching HMIS CSV export
          enrollment.id, # EnrollmentID matching HMIS CSV export
          posting.identifier, # EntityPostingID
          posting.created_at.strftime('%Y-%m-%d %H:%M:%S'), # AssignedDate
        ]
        write_row(values)
      end
    end

    private

    def columns
      ['PersonalID', 'EnrollmentID', 'EntityPostingID', 'AssignedDate']
    end

    def postings
      HmisExternalApis::AcHmis::ReferralPosting.from_link.
        where(status: ['accepted_status', 'closed_status']).
        preload(hoh_enrollment: [client: [:warehouse_client_source]])
    end
  end
end
