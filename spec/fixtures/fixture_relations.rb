module MixinAB
  def mix_a
    mix_aa
  end
  def mix_b; end
end

module MixinAD
  def mix_aa
    mix_ad
  end
  def mix_ad; end
end

module MixinCD
  def mix_c; end
  def mix_d; end
end

class SuperFracker
  def initialize
    @frack_count = 0
  end

  def frack
    @frack_count += 1
  end

  def frack2
    @frack_count += 1
  end

  def self.frack_it
    SuperFracker.new.frack
  end
end

class DerivedFracker < SuperFracker
  prepend MixinAB # Adds to instance (strongly)
  include MixinAD # Adds to instance
  extend MixinCD # Adds to class methods

  def initialize
    super
    @hmmm = true
  end
end

# DerivedFracker.superclass # SuperFracker
# DerivedFracker.included_modules # [MixinAB, MixinAD, Kernel]
# DerivedFracker.singleton_class.included_modules # MixinCD, Kernel
