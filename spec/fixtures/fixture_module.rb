module FixtureModule
  def FixtureModule.mod_foo(x)

  end

  def FixtureModule.mod_bar(y)

  end

  def mixed_foo(x)

  end

  def mixed_bar(y)

  end
end

module MixinAB
  def mix_a;end
  def mix_b;end
end

module MixinAD
  def mix_a;end
  def mix_d;end
end

module MixinCD
  # class << self
    def mix_c; end
    def mix_d; end
  # end
end

class Out
  def self.frack; end
end

class Outer < Out
  prepend MixinAB # Adds to instance (strongly)
  include MixinAD # Adds to instance
  extend MixinCD # Adds to class methods
end
Outer.superclass # Out
Outer.included_modules # [MixinAB, MixinAD, Kernel]
Outer.singleton_class.included_modules # MixinCD, Kernel
