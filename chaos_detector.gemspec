# -*- encoding: utf-8 -*-
# stub: chaos_detector 0.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "chaos_detector".freeze
  s.version = "0.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Miers".freeze]
  s.date = "2020-11-12"
  s.description = "Infer and discover and graph dependencies for ruby and RoR apps during EXECUTION".freeze
  s.email = "steven.miers@gmail.com".freeze
  s.executables = ["detect_chaos".freeze]
  s.files = ["bin/detect_chaos".freeze, "lib/chaos_detector.rb".freeze, "lib/chaos_detector/chaos_graphs/chaos_edge.rb".freeze, "lib/chaos_detector/chaos_graphs/chaos_graph.rb".freeze, "lib/chaos_detector/chaos_graphs/domain_metrics.rb".freeze, "lib/chaos_detector/chaos_graphs/domain_node.rb".freeze, "lib/chaos_detector/chaos_graphs/function_node.rb".freeze, "lib/chaos_detector/chaos_graphs/module_node.rb".freeze, "lib/chaos_detector/chaos_utils.rb".freeze, "lib/chaos_detector/graph_theory/appraiser.rb".freeze, "lib/chaos_detector/graph_theory/edge.rb".freeze, "lib/chaos_detector/graph_theory/graph.rb".freeze, "lib/chaos_detector/graph_theory/loop_detector.rb".freeze, "lib/chaos_detector/graph_theory/node.rb".freeze, "lib/chaos_detector/graph_theory/node_metrics.rb".freeze, "lib/chaos_detector/graph_theory/reduction.rb".freeze, "lib/chaos_detector/graphing/directed_graphs.rb".freeze, "lib/chaos_detector/graphing/graphs.rb".freeze, "lib/chaos_detector/graphing/matrix_graphs.rb".freeze, "lib/chaos_detector/navigator.rb".freeze, "lib/chaos_detector/options.rb".freeze, "lib/chaos_detector/stacker/comp_info.rb".freeze, "lib/chaos_detector/stacker/fn_info.rb".freeze, "lib/chaos_detector/stacker/frame.rb".freeze, "lib/chaos_detector/stacker/frame_stack.rb".freeze, "lib/chaos_detector/stacker/mod_info.rb".freeze, "lib/chaos_detector/tracker.rb".freeze, "lib/chaos_detector/utils/core_util.rb".freeze, "lib/chaos_detector/utils/fs_util.rb".freeze, "lib/chaos_detector/utils/lerp_util.rb".freeze, "lib/chaos_detector/utils/log_util.rb".freeze, "lib/chaos_detector/utils/str_util.rb".freeze, "lib/chaos_detector/utils/tensor_util.rb".freeze, "lib/chaos_detector/walkman.rb".freeze]
  s.homepage = "http://github.com/tangledpath/chaos_detector".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Discover and graph dependencies for ruby and RoR apps".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
    s.add_runtime_dependency(%q<ruby-graphviz>.freeze, ["~> 1.2.5"])
    s.add_runtime_dependency(%q<rubyvis>.freeze, ["~> 0.7.0"])
    s.add_runtime_dependency(%q<thor>.freeze, ["~> 0.20.3"])
  else
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
    s.add_dependency(%q<ruby-graphviz>.freeze, ["~> 1.2.5"])
    s.add_dependency(%q<rubyvis>.freeze, ["~> 0.7.0"])
    s.add_dependency(%q<thor>.freeze, ["~> 0.20.3"])
  end
end
