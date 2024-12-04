class StreamlineTranslations < ActiveRecord::Migration[7.0]
  def up
    raise "FIXME: this still needs a down"
    keys = {
      'the Boston Emergency Shelter Commission' => 'the Emergency Shelter Commission',
      'MA-500 Boston Continuum of Care FY2022 Renewal Project Scoring Tool' => 'FY2022 Renewal Project Scoring Tool',
      'Boston HMIS staff at DND' => 'HMIS staff at the CoC',
      'City of Boston DND Warehouse' => 'Open Path HMIS Warehouse',
      'The Boston DND Warehouse is operated by the Department of Neighborhood Development as the lead agency of the Boston Continuum of Care.' => 'The Open Path HMIS Warehouse',
      'Boston DND HMIS Warehouse' => 'Open Path HMIS Warehouse',
      'Boston DND Warehouse' => 'Open Path HMIS Warehouse',
      'Ending Veteran & Chronic Homelessness in Boston' => 'Ending Homelessness',
    }

    replaced = [
      'City of Boston DND Warehouse', # used in emails
      'Boston DND HMIS Warehouse',
    ]
    keys.each do |old_key, new_key|
      next t.destroy! if t.in?(replaced)

      t = Translation.find_by(key: old_key)
      t.text ||= old_key # If we never translated it, just use the old key as the translation
      t.key = new_key # set the new key as the key
      t.save!
    end
  end

  def down

  end
end
