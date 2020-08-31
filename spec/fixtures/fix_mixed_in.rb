require_relative 'fix_module'
class FixMixedIn
  include FixModule

  # def do_foo(x)
  #   mod_foo(x)
  # end
end