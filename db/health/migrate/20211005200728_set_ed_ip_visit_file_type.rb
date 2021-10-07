class SetEdIpVisitFileType < ActiveRecord::Migration[5.2]
  def up
    Health::EdIpVisitFile.update_all(type: 'Health::EdIpVisitFileV1')
  end

  def down
  end
end
