require "spec_helper"

module Fastout

  describe Ranker do

    describe Ranker::Point do

      before { @point = Ranker::Point.new 1.0, 4.2, -1 }

      context "#[]" do
        it("should be able to index the attributes directly") { @point[0].should == 1.0 }
      end

      context "#clustered?" do
        it "should be false when cluster is nil" do
          mock(@point).cluster { nil }
          @point.clustered?.should be_false
        end

        it "should be true when cluster is not nil" do
          mock(@point).cluster { 42 }
          @point.clustered?.should be_true
        end
      end

      context "#uncluster!" do
        it "should set cluster equal to nil" do
          @point.cluster = 42
          @point.uncluster!
          @point.cluster.should be_nil
        end
      end

      context "#in_the_neighborhood_of?" do
        before(:each) do
          stub(@point).bins { [2, 2] }
          @test_point = Ranker::Point.new
        end

        it "should be false when the test point is two bins away for an attribute" do
          mock(@test_point).bins { [0, 2] }
          @point.in_the_neighborhood_of?(@test_point, [0, 1], [1, 1]).should be_false
        end

        it "should be false when the test point is more than half a neighborhood away for an attribute" do
          mock(@test_point).bins { [1, 2] }.times(2)
          mock(@point).attributes { [2.5, 2.5] }
          mock(@test_point).attributes { [1.75, 2.5] }

          @point.in_the_neighborhood_of?(@test_point, [0, 1], [1, 1]).should be_false
        end

        it "should be true when the test point is less than half a neighborhood away for an attribute" do
          mock(@test_point).bins { [3, 2] }.times(2)
          mock(@point).attributes { [2.5, 2.5] }.times(2)
          mock(@test_point).attributes { [2.75, 2.5] }.times(2)

          @point.in_the_neighborhood_of?(@test_point, [0, 1], [1, 1]).should be_true
        end
      end

      context "#neighbor_of_any?" do

        it "should check to see if any point is a neighbor" do
          mock(@point).in_the_neighborhood_of?(:point_0, :attribute_indexes, :neighborhoods) { false }
          mock(@point).in_the_neighborhood_of?(:point_1, :attribute_indexes, :neighborhoods) { true }

          @point.neighbor_of_any?([:point_0, :point_1], :attribute_indexes, :neighborhoods).should be_true
        end

      end

    end

    it("should raise an error when given an empty array") { lambda { Ranker.new([]) }.should raise_error }
    it("should raise an error when given an array containing an empty array") { lambda { Ranker.new([[]]) }.should raise_error }
    it("should raise an error when given an array containing one non-empty array") { lambda { Ranker.new([[1, 2, 3]]) }.should raise_error }
    it("should raise an error when given an array containing only one attribute") { lambda { Ranker.new([[1], [2], [3]]) }.should raise_error }

    context "given 3 attributes and 4 data points" do
      before(:each) do
        @ranker = Ranker.new [[ 1.0,  3, -1],
                              [ 2.0, 50,  1],
                              [ 3.0,  5,  1],
                              [ 4.2,  2,  1]]
      end

      context ".pointify" do
        it "should generate a point object for each row" do
          @ranker.points.size.should == 4
        end
      end

      context "#ranked_outliers" do

        it "should compute the necessary parameters and return the points sorted by score" do
          mock(@ranker).compute_bin_count(42) { :bin_count }
          mock(@ranker).compute_bin_widths(42, :bin_count) { :bin_widths }
          mock(@ranker).assign_points_to_bins!(:bin_widths, :bin_count)
          mock(@ranker).score_points_from_a_random_set_of_attributes!(5, :bin_widths).times(100)
          mock(@ranker.points).sort_by { :answer }

          @ranker.ranked_outliers(100, 5, 42).should == :answer
        end
      end

      context "#score_points_from_a_random_set_of_attributes!" do

        it "should pick a random set of attributes and cycle through the points" do
          mock(@ranker).random_attribute_indexes(5) { [2, 0] }
          mock(@ranker).find_neighbors(is_a(Ranker::Point), [2, 0], [2, 0]) { [] }.times(4)

          @ranker.score_points_from_a_random_set_of_attributes!(5, [0, 1, 2])
        end
      end

      context "#random_attribute_indexes" do
        it("should give me back the correct number of indexes") { @ranker.random_attribute_indexes(3).size.should == 3 }
      end

      context "#find_neighbors" do
        it "should call recursively_find_neighbors" do
          mock(@ranker).recursively_find_neighbors(:point, :attribute_indexes, :bin_widths, [])

          @ranker.find_neighbors :point, :attribute_indexes, :bin_widths
        end
      end

      context "#recursively_find_neighbors" do

        it "should return its neighbors when there are no more unclustered points" do
          mock(@ranker).unclustered_points { [] }
          @ranker.recursively_find_neighbors(:point, :attribute_indexes, :bin_widths, :neighbors).should == :neighbors
        end

        it "should return its neighbors if it doesn't find any new neighbors" do
          unclustered_point = mock!.neighbor_of_any?(:neighbors, :attribute_indexes, :bin_widths) { false }.subject
          mock(@ranker).unclustered_points { [unclustered_point] }
          point = mock!.in_the_neighborhood_of?(unclustered_point, :attribute_indexes, :bin_widths) { false }.subject

          @ranker.recursively_find_neighbors(point, :attribute_indexes, :bin_widths, :neighbors).should == :neighbors
        end

        it "should call itself if it finds a new neighbor" do
          point = mock!.in_the_neighborhood_of?(:unclustered_point, :attribute_indexes, :bin_widths) { true }.subject
          mock(@ranker).recursively_find_neighbors(point, :attribute_indexes, :bin_widths, anything).times(2)

          @ranker.recursively_find_neighbors point, :attribute_indexes, :bin_widths, []
        end
      end

      context "#unclustered_points" do
      end

      context "#compute_minimums_and_maximums" do
        it "should properly compute minimums and maximums" do
          @ranker.minimums.should == [1.0,  2.0, -1.0]
          @ranker.maximums.should == [4.2, 50.0,  1.0]
        end
      end

      context "#bin_count" do
        it("should be equal to 4 when Q=1") { @ranker.compute_bin_count(1).should == 4 }
        it("should be equal to 2 when Q=2") { @ranker.compute_bin_count(2).should == 2 }
        it("should be equal to 2 when Q=3") { @ranker.compute_bin_count(3).should == 2 }
      end

      context "#compute_bin_widths" do
        it("should be equal to [0.75, 12.0, 0.0] when Q=1") { @ranker.compute_bin_widths(1, 4).should == [0.8, 12.0, 0.5] }
        it("should be equal to [1.6, 24.0, 0.0] when Q=2") { @ranker.compute_bin_widths(2, 2).should == [1.6, 24.0, 1.0] }
      end

      context "#assign_to_bins!" do
        context "with q=2" do
          it "should work properly" do
            points = [(point_0 = Ranker::Point.new(1.0,  3, -1)),
                      (point_1 = Ranker::Point.new(2.0, 50,  1)),
                      (point_2 = Ranker::Point.new(3.0,  5,  1)),
                      (point_3 = Ranker::Point.new(4.2,  2,  1))]

            mock(@ranker).points { points }.times(3)

            @ranker.assign_points_to_bins! [1.6, 24.0, 1.0], 2

            point_0.bins.should == [0, 0, 0]
            point_1.bins.should == [0, 1, 1]
            point_2.bins.should == [1, 0, 1]
            point_3.bins.should == [1, 0, 1]
          end
        end
      end

    end

  end

end
