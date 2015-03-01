
module CDQ
  module Deprecation

    class << self
      attr_accessor :silence_deprecation
    end

    def deprecate(message)
      puts message unless CDQ::Deprecation.silence_deprecation
    end
  end
end
