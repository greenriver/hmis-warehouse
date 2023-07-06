class AddAdditionalContactsToPctp < ActiveRecord::Migration[6.1]
  def change
    [:guardian, :social_support].each do |label|
      [:name, :phone, :email].each do |kind|
        add_column :pctp_careplans, "#{label}_#{kind}", :string
      end
    end

    add_column :pctp_careplans, :name_sent_to, :string
  end
end
