class EnableFuzzystrmatch < ActiveRecord::Migration[4.2]
  def change
    enable_extension "fuzzystrmatch"
  end
end
