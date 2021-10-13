class AddFailureMessageToEdIpVisitFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :ed_ip_visit_files, :message, :string
  end
end
