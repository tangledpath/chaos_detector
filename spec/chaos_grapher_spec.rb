require 'chaos_detector/navigator'
require 'chaos_detector/tracker'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/graphing/graphs'
require 'chaos_detector/options'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'chaos_detector/chaos_utils'

require 'chaos_detector/graph_theory/appraiser'

require 'fixtures/foobar'
require 'fixtures/fubarm'
require 'fixtures/fixture_relations'

shared_examples_for 'PlaybackTraversal' do |expected_traversal_str, graph_name=:function_graph|
  it 'should match traversal' do
    options = ChaosDetector::Options.new
    options.app_root_path = File.expand_path(__dir__)
    options.log_root_path = File.join('tmp', 'chaos_logs')
    options.path_domain_hash = { 'fixtures': 'FuDomain' }

    tracker = ChaosDetector::Tracker.new(options: options)
    nav = ChaosDetector::Navigator.new(options: options)

    tracker.record
    fn_calls
    tracker.stop

    nav_graph, mod_rel_graph = nav.playback
    chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(nav_graph, mod_rel_graph)
    chaos_graph.infer_all

    traversal_str = chaos_graph.send(graph_name).traversal.map(&:name).join(' -> ')
    puts "Found traversal string: #{traversal_str}"
    expect(traversal_str).to eq(expected_traversal_str)
  end
end

describe 'ChaosGrapher' do
  let(:chaos_options) do
    ChaosDetector::Options.new.tap do |opts|
      opts.app_root_path = File.expand_path(__dir__)
      opts.log_root_path = File.join('tmp', 'chaos_logs')
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
      opts.graph_render_folder = File.join('render')
    end
  end

  let(:chaos_tracker) { ChaosDetector::Tracker.new(options: chaos_options) }
  let(:chaos_nav) { ChaosDetector::Navigator.new(options: chaos_options) }

  let(:simple_tracking) do
    chaos_tracker.record
    Foo.foo
    Fubarm::Foom.foom
    chaos_tracker.stop
  end

  let(:associated_tracking) do
    chaos_tracker.record
    fracker = DerivedFracker.new
    fracker.frack
    chaos_tracker.stop
  end

  let(:graphing) do
    simple_tracking
    chaos_nav.playback
  end

  it 'domain graphs' do
    chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(*graphing)
    chaos_graph.infer_all

    grapher = ChaosDetector::Graphing::Directed.new(render_folder: chaos_options.path_with_root(path: 'render'))
    grapher.create_directed_graph('domain-test')

    grapher.append_nodes(chaos_graph.domain_nodes)
    grapher.add_edges(chaos_graph.domain_edges)

    grapher.render_graph
    graph_fs = `ls spec/render/domain-test.png`
    p(ChaosUtils.decorate(graph_fs))
    expect(graph_fs).to be
    expect(graph_fs.split.first).to eq('spec/render/domain-test.png')
  end

  describe 'function graphs' do
    it_should_behave_like 'PlaybackTraversal', 'ROOT -> foo -> bar -> baz -> foom -> barm -> bazm' do
      let(:fn_calls) do
        Foo.foo
        Fubarm::Foom.foom
      end
    end
    it_should_behave_like 'PlaybackTraversal', 'ROOT -> foom -> barm -> bazm -> foo -> bar -> baz' do
      let(:fn_calls) do
        Fubarm::Foom.foom
        Foo.foo
      end
    end

    describe 'Associations' do
      EXPECTED_TRAVERSAL_STR = 'ROOT -> initialize -> initialize -> frack'
      context 'Simple' do
        it_should_behave_like 'PlaybackTraversal', EXPECTED_TRAVERSAL_STR, graph_name=:function_graph do
          let(:fn_calls) do
            chaos_tracker.record
            fracker = DerivedFracker.new
            fracker.frack
            chaos_tracker.stop
          end
        end
      end

      context 'Dupes' do
        it_should_behave_like 'PlaybackTraversal', EXPECTED_TRAVERSAL_STR, graph_name=:function_graph do
          let(:fn_calls) do
            chaos_tracker.record
            fracker = DerivedFracker.new
            fracker.frack
            fracker.frack
            chaos_tracker.stop
          end
        end
      end
    end
  end

  describe 'nested traversals' do
    it_should_behave_like 'PlaybackTraversal', 'ROOT -> nester1 -> nest2 -> nest3 -> nest2 -> nest4 -> nest2 -> nest4' do
      let(:fn_calls) do
        Fubarm::Bazm.nester1(recurse: true)
      end

      it 'should do fn graph' do
        graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
        expect(graphs.navigator).to_not be_nil

        graphs.playback
        expect(graphs.chaos_graph).to_not be_nil

        graphs.render_fn_dep
      end
    end
  end

  describe 'function graphs' do
    it 'arranges' do
      walkman = simple_tracking
      expect(walkman).to_not be_nil
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      graphs.playback
      chaos_graph = graphs.chaos_graph
      expect(chaos_graph).to_not be_nil
      fn_graph = graphs.chaos_graph.function_graph

      top_size = 6
      expect(fn_graph.nodes).to_not be_nil
      expect(fn_graph.nodes.length).to be >= top_size+1

      arranged_graph = chaos_graph.arrange_graph(graph_type: :function, top: top_size)
      expect(arranged_graph.nodes).to_not be_nil
      expect(arranged_graph.nodes.length).to eq(top_size)
    end
  end

  describe 'module graphs' do
    EXPECTED_TRAVERSAL_STR = 'ROOT -> DerivedFracker -> SuperFracker -> MixinAB -> MixinAD -> MixinCD -> SuperFracker'

    it_should_behave_like 'PlaybackTraversal', EXPECTED_TRAVERSAL_STR, graph_name=:module_graph do
      let(:fn_calls) do
        chaos_tracker.record
        fracker = DerivedFracker.new
        fracker.frack
        chaos_tracker.stop
      end
    end

    it 'renders' do
      chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(*graphing)
      chaos_graph.infer_all

      grapher = ChaosDetector::Graphing::Directed.new(render_folder: chaos_options.path_with_root(path: 'render'))
      grapher.create_directed_graph('module-test')

      grapher.append_nodes(chaos_graph.module_nodes)

      chaos_graph.module_nodes.each do |n|
        p("ModNode: #{ChaosUtils.decorate(n.title)}")
      end

      chaos_graph.module_edges.each do |e|
        p("ModEdge: #{ChaosUtils.decorate(e.src_node.class)} -> #{ChaosUtils.decorate(e.dep_node.class)}")
      end
      grapher.add_edges(chaos_graph.module_edges)

      grapher.render_graph
      graph_fs = `ls spec/render/module-test.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/module-test.png')
    end

    it 'module deps using graphs' do
      walkman = simple_tracking
      expect(walkman).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      expect(graphs.navigator).to_not be_nil

      graphs.playback
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_mod_dep
      graph_fs = `ls spec/render/module-dep.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/module-dep.png')
    end


    context 'double frack' do
      let(:frack_tracking) do
        chaos_tracker.record
        fracker = DerivedFracker.new
        fracker.frack
        fracker.frack2
        chaos_tracker.stop
      end

      it 'finds associations' do
        walkman = frack_tracking
        expect(walkman).to_not be_nil

        # Playback should graph:
        graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
        expect(graphs.navigator).to_not be_nil

        graphs.playback
        expect(graphs.chaos_graph).to_not be_nil

        mod_graph = graphs.chaos_graph.module_graph
        puts "Module traversal string: #{mod_graph.traversal.map(&:mod_name).join(' -> ')}"

        fn_graph = graphs.chaos_graph.function_graph
        puts "FN traversal string: #{fn_graph.traversal.map(&:name).join(' -> ')}"

        mod_graph.nodes.each do |n|
          p("ModNode: #{n.reduction}")
        end

        graphs.render_mod_dep(graph_name: 'module-rel-dep')
        graph_fs = `ls spec/render/module-rel-dep.png`
        p(ChaosUtils.decorate(graph_fs))
        expect(graph_fs).to be
        expect(graph_fs.split.first).to eq('spec/render/module-rel-dep.png')
      end
    end
  end

  describe 'domain dependencies' do
    it 'domain deps using graphs' do
      walkman = simple_tracking
      expect(walkman).to_not be_nil

      # Playback should graph:
      graphs = ChaosDetector::Graphing::Graphs.new(options: chaos_options)
      expect(graphs.navigator).to_not be_nil

      graphs.playback
      expect(graphs.chaos_graph).to_not be_nil

      graphs.render_domain_dep
      graph_fs = `ls spec/render/domain-dep.png`
      p(ChaosUtils.decorate(graph_fs))
      expect(graph_fs).to be
      expect(graph_fs.split.first).to eq('spec/render/domain-dep.png')
    end

    # TODO: maybe extract all unique paths from graph struture?
    # chaos_tracker.record
    # fracker = DerivedFracker.new
    # fracker.frack
    # chaos_tracker.stop

    # super_event = chaos_walkman.frames_within.find{|f| f.event==:superclass}
    # expect(super_event).to_not be_nil
    # expect(super_event.event).to eq(:superclass)
    # expect(super_event.caller_info).to_not be_nil
    # expect(super_event.caller_info.mod_name).to eq('SuperFracker')
    # expect(super_event.caller_info.class).to eq(ChaosDetector::Stacker::ModInfo)


    # ab_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinAB' rescue nil
    # end

    # cd_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinCD' rescue nil
    # end

    # ad_frame = chaos_walkman.frames_within.find do |f|
    #   f.caller_info&.mod_name == 'MixinAD' rescue nil
    # end

    # expect(ab_frame).to_not be_nil
    # expect(ad_frame).to_not be_nil
    # expect(cd_frame).to_not be_nil

    # expect(ab_frame.event).to eq(:association)
    # expect(ad_frame.event).to eq(:association)
    # expect(cd_frame.event).to eq(:class_association)

    # puts 'TOTAL FRAMES: %d' % chaos_walkman.count
    # chaos_walkman.playback { |r,f| puts("#{r}: #{f}") }

  end
end
