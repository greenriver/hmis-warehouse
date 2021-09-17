class IndexRaceColumns < ActiveRecord::Migration[5.2]
  def change
    [
      :AmIndAKNative,
      :Asian,
      :BlackAfAmerican,
      :NativeHIOtherPacific,
      :NativeHIPacific,
      :White,
      :RaceNone,
    ].each do |column|
      add_index :Client, column
    end
  end
end
