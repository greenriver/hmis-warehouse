class PreCreateAvailableTags < ActiveRecord::Migration
  def change
    return unless ActiveRecord::Base.connection.table_exists? :available_file_tags
    GrdaWarehouse::ClientFile.available_tags.each do |name|
      ActsAsTaggableOn::Tag.where(name: name).first_or_create
    end
  end
end
