class MoveTranslations < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute <<-SQL
        insert into translations (key, text, created_at, updated_at)
        select translation_keys.key, translation_texts.text, translation_keys.created_at, translation_keys.updated_at
        from translation_keys
        left outer join translation_texts
        on translation_keys.id = translation_texts.translation_key_id
      SQL
    end
  end
end
