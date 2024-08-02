class AddPolymorphicMetadataToQualifyingActivity < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_reference :qualifying_activities, :claim_metadata, polymorphic: true, null: true, index: {algorithm: :concurrently}
  end
end
