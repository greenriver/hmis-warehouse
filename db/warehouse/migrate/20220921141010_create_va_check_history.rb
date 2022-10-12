class CreateVaCheckHistory < ActiveRecord::Migration[6.1]
  def change
    create_table :va_check_histories do |t|
      t.references :client
      t.string :response
      t.date :check_date
      t.references :user

      t.timestamps
    end

    remove_column :Client, :va_check_date
  end
end
