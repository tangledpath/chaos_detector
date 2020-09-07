require_relative 'fixture_module'
class FixtureMixedIn
  include FixtureModule

  def do_foo(x)
    mixed_foo(x)
  end
end
