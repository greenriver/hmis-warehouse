class StreamlineTranslations < ActiveRecord::Migration[7.0]
  def up
    translations.each do |old_key, new_key|
      t = Translation.find_by(key: old_key)
      next unless t
      next t.destroy! if old_key.in?(replaced)

      t.text ||= old_key # If we never translated it, just use the old key as the translation
      t.key = new_key # set the new key as the key
      t.save!
    end
  end

  def down
    translations.each do |old_key, new_key|
      t = Translation.find_by(key: new_key)
      next unless t

      t.key = old_key
      # never translated, reset the translation to empty
      t.text = nil if t.text == old_key
      t.save!
    end
    replaced.each do |old_key|
      Translation.create(key: old_key)
    end
  end

  def translations
    {
      'the Boston Emergency Shelter Commission' => 'the Emergency Shelter Commission',
      'MA-500 Boston Continuum of Care FY2022 Renewal Project Scoring Tool' => 'FY2022 Renewal Project Scoring Tool',
      'Boston HMIS staff at DND' => 'HMIS staff at the CoC',
      'City of Boston DND Warehouse' => 'Open Path HMIS Warehouse',
      'The Boston DND Warehouse is operated by the Department of Neighborhood Development as the lead agency of the Boston Continuum of Care.' => 'The Open Path HMIS Warehouse',
      'Boston DND HMIS Warehouse' => 'Open Path HMIS Warehouse',
      'Boston DND Warehouse' => 'Open Path HMIS Warehouse',
      'Ending Veteran & Chronic Homelessness in Boston' => 'Ending Homelessness',
    }
  end

  def replaced
    [
      'City of Boston DND Warehouse',
      'Boston DND HMIS Warehouse',
    ]
  end
end
