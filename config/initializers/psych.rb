#
# This is a fix for a parse error for integers with trailing underscore
# To test: YAML.load('1_')
#
module Psych
  class ScalarScanner
    if INTEGER.to_s.include?('|[-+]?(?:0|[1-9][0-9_,]*)')
      remove_const(:INTEGER)
      INTEGER = /^(?:[-+]?0b[0-1_,]+                        (?# base 2)
                     |[-+]?0[0-7_,]+                         (?# base 8)
                     |[-+]?(?:0|[1-9](?:[0-9]|,[0-9]|_[0-9])*) (?# base 10)
                     |[-+]?0x[0-9a-fA-F_,]+                  (?# base 16))$/x
    else
      puts 'Check Psych monkeypatch!'
    end
  end
end