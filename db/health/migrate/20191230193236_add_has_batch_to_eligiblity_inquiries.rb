class AddHasBatchToEligiblityInquiries < ActiveRecord::Migration
  def change
    add_column :eligibility_inquiries, :has_batch, :boolean, default: false
  end
end
