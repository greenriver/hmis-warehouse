require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 1_000
IRB.conf[:HISTORY_FILE] = File.join(__dir__, '.pry_history')
IRB.conf[:USE_AUTOCOMPLETE] = false
