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

class FixtureMixedIn
  include FixtureModule

  def do_foo(x)
    mixed_foo(x)
  end
end
