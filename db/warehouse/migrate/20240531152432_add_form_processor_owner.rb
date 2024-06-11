class AddFormProcessorOwner < ActiveRecord::Migration[7.0]
  # rails db:migrate:up:warehouse VERSION=20240531152432
  # rails db:migrate:down:warehouse VERSION=20240531152432
  def change
    # note: owner will be made non-nullable at a later step
    add_reference :hmis_form_processors, :owner, polymorphic: true, index: false, null: true
  end
end
