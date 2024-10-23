class UpdateTalentConfigRecords < ActiveRecord::Migration[7.0]
  def change
    Talentlms::Config.all.each do |c|
      c.update(default: true, configuration_name: c.subdomain)
    end
  end
end
