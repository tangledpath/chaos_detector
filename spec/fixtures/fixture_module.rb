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

module MixinCD
  # class << self
    def mix_c; end
    def mix_d; end
  # end
end

# class Outer
#   prepend MixinAB
#   extend MixinCD
# end

# Outer.included_modules
# Outer.class.included_modules
# Outer.ancestors

# 2.7.1 :018 > Outer.included_modules
#  => [MixinAB, Kernel]
# 2.7.1 :019 > Outer.class.included_modules
#  => [Kernel]
# 2.7.1 :020 > Outer.ancestors
#  => [MixinAB, Outer, Object, Kernel, BasicObject]
# 2.7.1 :021 > Outer.mix_
# Outer.mix_c
# Outer.mix_d
# 2.7.1 :021 > Outer.mix_c
#  => nil
# 2.7.1 :022 > Outer.is_a?MixinCD
#  => true
# 2.7.1 :023 > obj=Outer.new
# 2.7.1 :024 > obj.is_a?MixinCD
#  => false
# 2.7.1 :025 > obj.is_a?MixinAB
#  => true