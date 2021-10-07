class PopulateEdIpVisits < ActiveRecord::Migration[5.2]
  def change
    Health::EdIpVisitFile.find_each do |file|
      file.ingest!(Health::LoadedEdIpVisit.from_file(file))
    end
  end
end
