class AddHasBatchToEligiblityInquiries < ActiveRecord::Migration[4.2]
  def change
    add_column :eligibility_inquiries, :has_batch, :boolean, default: false
  end
end
