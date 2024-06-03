class AddFormProcessorOwner < ActiveRecord::Migration[7.0]
  disable_ddl_transaction! # needed for index creation

  # rails db:migrate:up:warehouse VERSION=20240531152432
  # rails db:migrate:down:warehouse VERSION=20240531152432
  def change
    # note: owner will be made non-nullable at a later step
    add_reference :hmis_form_processors, :owner, polymorphic: true, index: { algorithm: :concurrently, unique: true }, null: true
  end
end
