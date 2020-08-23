# -*- encoding: utf-8 -*-
# stub: chaos_detector 0.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "chaos_detector".freeze
  s.version = "0.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Miers".freeze]
  s.date = "2020-08-10"
  s.description = "Discover and graph dependencies for ruby and RoR apps".freeze
  s.email = "steven.miers@gmail.com".freeze
  s.executables = ["detect_chaos".freeze]
  s.files = ["bin/detect_chaos".freeze, "lib/chaos_detector.rb".freeze, "lib/chaos_detector/atlas.rb".freeze, "lib/graph_theory/edge.rb".freeze, "lib/graph_theory.rb".freeze, "lib/graph_theory/domain_metrics.rb".freeze, "lib/graph_theory/edge_metrics.rb".freeze, "lib/graph_theory/node_metrics.rb".freeze, "lib/graph_theory/stack_metrics.rb".freeze, "lib/chaos_detector/grapher.rb".freeze, "lib/chaos_detector/navigator.rb".freeze, "lib/chaos_detector/node.rb".freeze, "lib/chaos_detector/options.rb".freeze, "lib/chaos_detector/scratch.rb".freeze, "lib/chaos_detector/stack_frame.rb".freeze, "lib/chaos_detector/utils.rb".freeze, "lib/chaos_detector/walkman.rb".freeze]
  s.homepage = "http://github.com/tangledpath/chaos_detector".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Discover and graph dependencies for ruby and RoR apps".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
      s.add_runtime_dependency(%q<ruby-graphviz>.freeze, ["~> 1.2.5"])
      s.add_runtime_dependency(%q<thor>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
      s.add_dependency(%q<ruby-graphviz>.freeze, ["~> 1.2.5"])
      s.add_dependency(%q<thor>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
    s.add_dependency(%q<ruby-graphviz>.freeze, ["~> 1.2.5"])
    s.add_dependency(%q<thor>.freeze, [">= 0"])
  end
end
