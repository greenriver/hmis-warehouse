class CreateTransactionAcknowledgements < ActiveRecord::Migration
  def change
    create_table :transaction_acknowledgements do |t|
      t.references :user
      t.text :content
      t.string :original_filename
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end

    add_column :claims, :result, :string
    add_reference :claims, :transaction_acknowledgement
  end
end
