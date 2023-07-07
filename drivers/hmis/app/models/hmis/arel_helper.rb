# contain our arel-helper methods, reduce name space pollution
class Hmis::ArelHelper
  include Singleton
  include Hmis::Concerns::HmisArelHelper
end
