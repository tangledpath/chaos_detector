module Fubarm
  class Foom
    def self.foom
      Barm.barm
    end
  end

  class Barm
    def self.barm
      Bazm.bazm
    end
  end

  class Bazm
    def self.bazm
      # Comment
      puts 'fubar_mod::bazzzzzz'
      # Stuff
      puts 'again'
    end

    def self.nester1(recurse: false)
      b = Bazm.new
      b.nest2
      b.nest3(recurse: recurse)
      b.nest4(recurse: recurse)
    end

    def nest2(recurse: false)
      nest3 if recurse
    end

    def nest3(recurse: false)
      nest2 if recurse
      nest4(recurse: recurse)
    end

    def nest4(recurse: false)
      nest2 if recurse
    end
  end
end
