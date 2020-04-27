class CreateDisenrollmentReasons < ActiveRecord::Migration[5.2]
  def change
    create_table :disenrollment_reasons do |t|
      t.string :reason_code, index: true
      t.string :reason_description
      t.string :referral_reason_code
    end
  end
end
