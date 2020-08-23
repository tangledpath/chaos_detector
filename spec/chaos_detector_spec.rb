
require 'chaos_detector/atlas'
require 'chaos_detector/navigator'
require 'chaos_detector/stack_frame'
require 'chaos_detector/grapher'
require 'chaos_detector/options'
require 'chaos_detector/utils'
require 'graph_theory/appraiser'

require 'fixtures/Fubar'
describe "ChaosDetector" do
  describe "Navigator" do
    let (:dec1) { "#<Class:Authentication>"}
    let (:dec2) { "#<Class:Person(id: integer)>"}
    let (:dec3) { "#<ChaosDetector::Node:0x00007fdd5d2c6b08>"}
    let (:opts) {
      opts = ChaosDetector::Options.new
      opts.app_root_path = __dir__
      opts.log_root_path = __dir__
      opts.path_domain_hash = { 'fixtures': 'FuDomain' }
      opts
    }

    # a="#<Class:Authentication>"
    # b="#<Class:Person(id: integer, first"
    # c="#<ChaosDetector::Node:0x00007fdd5d2c6b08>"
    it "should undecorate module names" do
      ChaosDetector::Navigator.undecorate_module_name(dec2).should eq("Person")
      ChaosDetector::Navigator.undecorate_module_name(dec1).should eq("Authentication")
      ChaosDetector::Navigator.undecorate_module_name(dec3).should eq("ChaosDetector::Node")
    end

    it "should record and graph" do
      ChaosDetector::Navigator.record(options: opts)
      Foo.foo
      Fubar::Foo.foo
      expect(ChaosDetector::Navigator.atlas).to_not be_nil

      atlas = ChaosDetector::Navigator.stop
      ChaosDetector::Utils.print_line ("Nodes: #{atlas.graph_nodes.length}")
      expect(atlas).to eq(ChaosDetector::Navigator.atlas)
      grapher = ChaosDetector::Grapher.new(atlas)
      grapher.build_graphs()

      atlas.graph_edges.each do |edge|
        ChaosDetector::Utils.print_line "edge: #{edge}" if edge.src_node.is_root# =='root'
      end
    end

    it "should graph theorize" do
      ChaosDetector::Navigator.record(options: opts)
      Foo.foo
      Fubar::Foo.foo
      atlas = ChaosDetector::Navigator.stop

      graph_metrics = GraphTheory::Appraiser.new(atlas.graphus)
      graph_metrics.appraise
    end

    it "should save recording to walkman" do
      ChaosDetector::Navigator.record(options: opts)
      Foo.foo
      Fubar::Foo.foo
      _atlas = ChaosDetector::Navigator.stop

      expect(ChaosDetector::Navigator.walkman).to_not be_nil
      walkman = ChaosDetector::Navigator.walkman
      expect(walkman).to_not be_nil
      expect(walkman.csv_path).to_not be_nil
      expect(walkman.csv_path).to_not be_empty
      csv_content = `cat #{walkman.csv_path}`
      expect(csv_content).to_not be_nil
      expect(csv_content).to_not be_empty
      csv_lines = csv_content.split
      expect(csv_lines.length).to eq(13)
      # csv_lines = csv_content.split
      # puts csv_lines.length
      # puts '-' * 50
      # puts csv_lines
      # puts '-' * 50
    end

    it "should playback from file" do
      ChaosDetector::Navigator.record(options: opts)
      Foo.foo
      Fubar::Foo.foo
      recorded_atlas = ChaosDetector::Navigator.stop
      expect(recorded_atlas).to_not be_nil

      # TODO: instaantize Navigator class and whack this:
      ChaosDetector::Navigator::atlas = nil
      ChaosDetector::Navigator::options = nil
      playback_atlas = ChaosDetector::Navigator.playback(options: opts)
      expect(playback_atlas).to_not be_nil

      # Playback should graph:
      grapher = ChaosDetector::Grapher.new(playback_atlas)
      grapher.build_graphs()
    end
  end

  describe "Atlas" do
    it "should do basic frame stacking" do
      graph = ChaosDetector::Atlas.new
      frame1 = ChaosDetector::StackFrame.new(mod_type: :class, mod_name: 'Bam', domain_name: 'bar', fn_path: 'foo/bar', fn_name: 'baz', line_num: 2112)
      frame2 = ChaosDetector::StackFrame.new(mod_type: :module, mod_name: 'Gork', domain_name: 'MEP', fn_path: 'foo/mepper', fn_name: 'blop', line_num: 3112)

      expect(graph.stack_depth).to eq(0)

      graph.open_frame(frame1)
      expect(graph.stack_depth).to eq(1)

      graph.open_frame(frame2)
      expect(graph.stack_depth).to eq(2)

      graph.close_frame(frame2)
      expect(graph.stack_depth).to eq(1)

      graph.close_frame(frame1)
      expect(graph.stack_depth).to eq(0)

    end
  end

  describe "Utils" do
    it "should self-test" do
      ChaosDetector::Utils.test
    end
  end
end

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
    puts "bazzzzzz"
  end
end

  # it "should show the class level dependencies" do
  #   dependencies, _ = ::ChaosDetector.dependency_hash_for do
  #     class IHaveAClassLevelDependency
  #       Son.class_method
  #     end
  #   end

  #   dependencies.should == {"Parent"=>["Son"]}
  # end




# require 'file_test_helper'


# module GrandparentModule
#   def class_method
#   end
# end

# class Grandparent
#   extend GrandparentModule

#   def instance_method
#   end
# end

# class Parent
#   def self.class_method
#     Grandparent.class_method
#   end

#   def instance_method
#   end
# end

# class Son
#   def self.class_method
#     parent = Parent.new
#     parent.instance_method
#     parent.instance_method
#     class_method2
#     class_method2
#   end

#   def self.class_method2
#   end

#   def instance_method_that_calls_parent_class_method
#     Parent.class_method
#   end

#   def instance_method_calling_another_instance_method(second_receiver)
#     second_receiver.instance_method
#   end

#   def instance_method
#     Parent.class_method
#     Grandparent.class_method
#   end
# end

# describe "ChaosDetector" do

#   it "should show the class level dependencies" do
#     dependencies, _ = ::ChaosDetector.dependency_hash_for do
#       class IHaveAClassLevelDependency
#         Son.class_method
#       end
#     end

#     dependencies.should == {"Parent"=>["Son"]}
#   end

#   it "should be idempotent" do
#     ::ChaosDetector.dependency_hash_for do
#       class IHaveAClassLevelDependency
#         Son.class_method
#       end
#     end

#     dependencies, _ = ::ChaosDetector.dependency_hash_for do
#       class IHaveAClassLevelDependency
#         Son.class_method
#       end
#     end

#     dependencies.should == {"Parent"=>["Son"]}
#   end

#   it "should show the dependency from an object singleton method" do
#     dependencies, _ = ::ChaosDetector.dependency_hash_for do
#       s = Son.new
#       def s.attached_method
#         Grandparent.class_method
#       end
#       s.attached_method
#     end

#     dependencies.keys.should == ["Grandparent", "GrandparentModule"]
#     dependencies["Grandparent"].should == ["Son"]
#     dependencies["GrandparentModule"].should == ["Grandparent"]
#   end

#   it "should show the dependencies between the classes inside the block" do
#     dependencies, _ = ::ChaosDetector.dependency_hash_for do
#       Son.new.instance_method
#     end

#     dependencies.keys.should =~ ["Parent", "Grandparent", "GrandparentModule"]
#     dependencies["Parent"].should == ["Son"]
#     dependencies["Grandparent"].should =~ ["Son", "Parent"]
#     dependencies["GrandparentModule"].should == ["Grandparent"]
#   end

#   it "should create correct dependencies for 2 instance methods called in a row" do
#     dependencies, _ = ::ChaosDetector.dependency_hash_for do
#       Son.new.instance_method_calling_another_instance_method(Parent.new)
#     end

#     dependencies.should == {"Parent"=>["Son"]}
#   end

#   context "with a dumped dependencies file" do
#     include FileTestHelper

#     sample_dir_structure = {'path1/class_a.rb' => <<-CLASSA,
#                                require '#{File.dirname(__FILE__)}/../lib/chaos_detector'

#                                require './path1/class_b'
#                                require './path2/class_c'
#                                class A
#                                  def depend_on_b_and_c
#                                    B.new.b
#                                    C.new.c
#                                  end
#                                end

#                                ChaosDetector.start
#                                A.new.depend_on_b_and_c
#                              CLASSA
#                              'path1/class_b.rb' => 'class B; def b; end end',
#                              'path2/class_c.rb' => 'class C; def c; end end'}

#     def run(command)
#       system("ruby -I#{File.dirname(__FILE__)}/../lib #{command}")
#     end

#     it "should create a dot file" do
#       with_files(sample_dir_structure) do
#         run("./path1/class_a.rb")
#         run("#{File.dirname(__FILE__)}/../bin/chaos_detector")

#         File.read("chaos_detector.dot").should match("digraph G")
#       end
#     end

#     it "should be a correct test file" do
#       with_files(sample_dir_structure) do
#         status = run("./path1/class_a.rb")
#         status.should be_true
#       end
#     end

#     it "should not filter classes when no filter is specified" do
#       with_files(sample_dir_structure) do
#         run("./path1/class_a.rb")

#         dependencies, _ = ::ChaosDetector.dependency_hash_for(:from_file => 'chaos_detector.dump')
#         dependencies.should == {"B"=>["A"], "C"=>["A"]}
#       end
#     end

#     it "should filter classes when a path filter is specified" do
#       with_files(sample_dir_structure) do
#         run("./path1/class_a.rb")

#         dependencies, _ = ::ChaosDetector.dependency_hash_for(:from_file => 'chaos_detector.dump', :path_filter => /path1/)
#         dependencies.should == {"B"=>["A"]}
#       end
#     end

#     it "should filter classes when a class name filter is specified" do
#       with_files(sample_dir_structure) do
#         run("./path1/class_a.rb")

#         dependencies, _ = ::ChaosDetector.dependency_hash_for(:from_file => 'chaos_detector.dump', :class_name_filter => /C|A/)
#         dependencies.should == {"C"=>["A"]}
#       end
#     end
#   end
# end
