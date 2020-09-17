class Foo
  def self.foo
    Bar.bar
  end
end

class Bar
  def self.bar
    Baz.baz
  end
end

class Baz
  def self.baz
    puts 'bazzzzzz'
  end
end
