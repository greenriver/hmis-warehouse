class SetEdIpVisitFileType < ActiveRecord::Migration[5.2]
  def change
    Health::EdIpVisitFile.update_all(type: 'Health::EdIpVisitFileV1')
  end
end
