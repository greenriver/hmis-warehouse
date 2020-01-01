class SetHasBatchOnEligibilityInquiries < ActiveRecord::Migration
  def change
    Health::EligibilityInquiry.where(internal: false).find_each do |inquiry|
      inquiry.update(has_batch: true) if inquiry.batches.present?
    end
  end
end
