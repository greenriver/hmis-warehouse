###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module ClaimsReporting
  class CpPaymentUpload < HealthBase
    has_paper_trail ignore: [:content]

    MAX_UPLOAD_SIZE = 50.megabytes
    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation
    phi_attr :content, Phi::Bulk # contains serialized medicaid_ids, name, service dates

    belongs_to :user, class_name: 'User', required: true
    validate :validate_contents

    has_many :details, class_name: '::ClaimsReporting::CpPaymentDetail'

    scope :unprocessed, -> do
      where(started_at: nil)
    end

    scope :complete, -> do
      where.not(completed_at: nil)
    end

    def process!
      update(
        started_at: Time.current,
        completed_at: nil,
      )
      transaction do
        details.import content_as_details

        # TODO? the  XLSX file also contains a summary
        # with "Number Claims", ""Total Claims Amount" etc we could cross check
        update(completed_at: Time.current)
      end
    end

    DETAIL_COLS = [
      'Medicaid_ID',
      'Member_CP_Assignment_Plan',
      'CP_Enrollment_Start_Date',
      'CP_Name_DSRIP',
      'CP_Name_Official',
      'CP_PID',
      'CP_SL',
      'Month_Payment_Issued',
      'Paid_DOS',
      'Paid_Num_ICN',
      'Adjustment_Amount',
      'Amount_Paid',
      'Payment_Date',
    ].freeze

    # We are excluding these unneeded columns for the moment
    # Member_Name_Last
    # Member_Name_First
    # Member_Middle_Initial
    # Member_Suffix

    def validate_contents
      if content.length > MAX_UPLOAD_SIZE
        errors.add(:content, "is too large. Max size is #{MAX_UPLOAD_SIZE.to_s(:human_size)}")
        return
      end
      content_as_details.any? # we call this just to provoke Roo to throw validation errors
    rescue Zip::Error
      errors.add(:content, 'must be a valid XLSX file')
    rescue RangeError => e # raised when looking for a sheet in Roo
      errors.add(:content, e.message)
    rescue Roo::HeaderRowNotFoundError => e
      errors.add(:content, "does not contain the following required headers: #{e.message}")
    rescue Roo::Error => e
      errors.add(:content, e.message)
    end

    def content_as_details
      roo = ::Roo::Excelx.new(StringIO.new(content).binmode)

      required_cols = DETAIL_COLS.map { |c| [c.downcase, Regexp.new(c, true)] }.to_h
      roo.sheet('DETAIL').parse(
        required_cols,
      ).map(&:symbolize_keys)
    end

    def started?
      started_at.present?
    end

    def completed?
      completed_at.present?
    end

    def status
      if completed?
        'Processed'
      elsif started?
        'Processing'
      else
        'Queued for processing'
      end
    end

    def paid_dos_range
      details.pluck(
        details.arel_table[:paid_dos].minimum,
        details.arel_table[:paid_dos].maximum,
      ).first
    end
  end
end
