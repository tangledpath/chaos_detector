module Fubar;end
class Fubar::Foo
  def self.foo
    Fubar::Bar.bar
  end
end

class Fubar::Bar
  def self.bar
    Fubar::Baz.baz
  end
end

class Fubar::Baz
  def self.baz
    puts "fubar::bazzzzzz"
  end
end