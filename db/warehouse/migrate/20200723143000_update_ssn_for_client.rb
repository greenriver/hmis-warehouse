class UpdateSSNForClient < ActiveRecord::Migration[5.2]
  # disable_ddl_transaction!

  # def change
  #   reversible do |r|
  #     r.up do
  #       remove_bi_views!

  #       # It might be encrypted, which will be longer than 9
  #       # change_column :Client, :SSN, :string, length: 255

  #       add_bi_views!
  #     end

  #     r.down do
  #       remove_bi_views!

  #       # change_column :Client, :SSN, :string, length: 9

  #       add_bi_views!
  #     end
  #   end
  # end

  # def remove_bi_views!
  #   say_with_time 'Removing BI views' do
  #     Bi::ViewMaintainer.new.remove_views
  #   end
  # end

  # def add_bi_views!
  #   say_with_time 'Adding new BI views' do
  #     Bi::ViewMaintainer.new.create_views
  #   end
  # end
end
