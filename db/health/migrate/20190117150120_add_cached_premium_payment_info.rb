class AddCachedPremiumPaymentInfo < ActiveRecord::Migration
  def change
    add_column :premium_payments, :converted_content, :jsonb
    add_column :premium_payments, :started_at, :datetime
    add_column :premium_payments, :completed_at, :datetime
  end
end
