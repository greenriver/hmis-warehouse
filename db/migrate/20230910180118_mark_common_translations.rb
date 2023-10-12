class MarkCommonTranslations < ActiveRecord::Migration[6.1]
  def up
    Translation.where("key ilike '%boston%'").update_all(common: true)
    Translation.where("key ilike '%dnd%'").update_all(common: true)
  end
end
