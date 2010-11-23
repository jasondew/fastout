# Takes a data set and determines the outliers using the FASTOUT algorithm from
# Foss et al., "Class Separation through Variance: a new application of outlier detection",
# Knowledge and Information Systems, 2010.
#
# Author:: Jason Dew (mailto:jason.dew@gmail.com)
# Copyright:: Copyright (c) 2010 Jason Dew
# License:: MIT
class Ranker

  class Point

    @@next_id = 0

    def self.next_id= id
      @@next_id = id
    end

    attr_reader :id, :attributes, :bins
    attr_accessor :cluster, :score

    def initialize *attributes
      @attributes = attributes
      @cluster = nil
      @score = 0
      @bins = []

      @id = @@next_id
      @@next_id += 1
    end

    def [] index
      @attributes[index]
    end

    def clustered?
      !! cluster
    end

    def uncluster!
      @cluster = nil
    end

    def in_the_neighborhood_of? point, attribute_indexes, neighborhoods
      attribute_indexes.each do |attribute_index|
        return false if (bins[attribute_index] - point.bins[attribute_index]).abs > 1
      end

      attribute_indexes.each do |attribute_index|
        return false if (attributes[attribute_index] - point.attributes[attribute_index]) > (neighborhoods[attribute_index] / 2.0)
      end

      true
    end

    def neighbor_of_any? points, attribute_indexes, neighborhoods
      points.inject(false) {|found, point| found or in_the_neighborhood_of?(point, attribute_indexes, neighborhoods) }
    end

  end

  attr_reader :data, :points, :minimums, :maximums

  def self.pointify data
    data.map {|attributes| Point.new *attributes }
  end

  # takes a 2-d array, +data+, where the rows are data points and the columns are the attributes,
  # values should all be numerical
  # * +data+ should not be empty or nil will be returned
  # * also generates minimum and maximum values for each attribute for later use
  def initialize data
    raise "data must have more than one attribute and more than one data point" unless data.size > 1 and data.first.size > 1
    @data = data
    @points = self.class.pointify data
    @minimums, @maximums = compute_minimums_and_maximums
    Point.next_id = 0
  end

  # searches the parameter space to find the optimized values of +k+ and +q+
  # using +sample+ samples at each iteration
  def optimized_ranking target, sample, n
    k = 3
    q = 5
    max_q = n / 4
    step_q = 10
    last_theta = n
    theta, s = calculate_theta(sample, k, n, q)

    while (theta > target or theta < last_theta or q < max_q) do
      return s if (theta <= target)

      if (theta >= last_theta)
        # effectiveness declining so try next k
        k += 1
        q -= step_q
        last_theta = n
      else
        # try next q
        q += step_q
        last_theta = theta
      end

      theta, s = calculate_theta(sample, k, n, q)
    end

    s
  end

  # find and rank the points by their outlier score and
  # determine theta (the number of points with an outlier score
  # of +n+)
  def calculate_theta sample, k, n, q
    s = ranked_outliers sample, k, q
    theta = points.inject(0) {|sum, point| point.score == n ? sum + 1 : sum }

    [theta, s]
  end

  # chooses +k+ random attributes with an average of +q+ data points
  # in each bin +sample+ times to determine outliers
  def ranked_outliers sample_size, k, q
    # determine number of bins and their widths
    bin_count =  compute_bin_count(q)
    bin_widths = compute_bin_widths(q, bin_count)

    # assign points to the attribute bins
    assign_points_to_bins! bin_widths, bin_count

    1.upto(sample_size) {
      score_points_from_a_random_set_of_attributes! k, bin_widths }

    points.sort_by(&:score)
  end

  # pick a random set of attributes and compute the outlier score
  # for each of the points
  def score_points_from_a_random_set_of_attributes! number_of_attributes_to_choose, all_bin_widths
    cluster = 0
    attribute_indexes = random_attribute_indexes number_of_attributes_to_choose
    bin_widths = attribute_indexes.map {|index| all_bin_widths[index] }

    points.each do |point|
      next if point.clustered?

      point.cluster = (cluster += 1)
      neighbors = cluster_neighbors point, cluster, attribute_indexes, bin_widths

      point.uncluster!  if neighbors.empty?
    end

    points.each do |point|
      next unless point.clustered?
      point.uncluster!
      point.score += 1
    end
  end

  # randomly choose +number+ of attribute indexes
  def random_attribute_indexes number
    (0...@data.first.size).sort_by { rand }[0..number]
  end

  # find all unclustered points that are neighbors of +point+ on
  # *all* selected attributes or neighbors in the neighborhood
  # of +point+; find recursively until no additions can be made
  def cluster_neighbors point, cluster, attribute_indexes, bin_widths
    recursively_cluster_neighbors point, cluster, attribute_indexes, bin_widths, []
  end

  # recursive step of #cluster_neighbors
  def recursively_cluster_neighbors point, cluster, attribute_indexes, bin_widths, neighbors
    fruitful = false

    unclustered_points.each do |unclustered_point|
      next unless point.in_the_neighborhood_of?(unclustered_point, attribute_indexes, bin_widths) or
                  unclustered_point.neighbor_of_any?(neighbors, attribute_indexes, bin_widths)

      fruitful = true
      unclustered_point.cluster = cluster
      neighbors << unclustered_point
    end

    if fruitful
      recursively_cluster_neighbors point, cluster, attribute_indexes, bin_widths, neighbors
    else
      neighbors
    end
  end

  # find all of the points that don't already belong to a cluster
  def unclustered_points
    points.select {|point| not point.clustered? }
  end

  # assign each of the data points to a bin based on the given +bin_widths+,
  # returns a 2-d array in attribute-major order
  def assign_points_to_bins! bin_widths, bin_count
    bin_widths.each_with_index do |bin_width, attribute_index|
      points.each do |point|
        point.bins[attribute_index] = bin_index(point, attribute_index, bin_width)
      end
    end
  end

  def bin_index point, attribute_index, bin_width
    minimum = @minimums[attribute_index]
    maximum = @maximums[attribute_index]

    value = point[attribute_index]
    index = ((value - minimum) / bin_width).floor

    value == maximum ? index - 1 : index
  end

  def compute_minimums_and_maximums
    minimums = @data.first.dup
    maximums = @data.first.dup

    @data.each do |attributes|
      attributes.each_with_index do |attribute, attribute_index|
        minimums[attribute_index] = attribute if attribute < minimums[attribute_index]
        maximums[attribute_index] = attribute if attribute > maximums[attribute_index]
      end
    end

    [minimums, maximums]
  end

  # determine the widths of the bins based on +q+
  def compute_bin_widths q, bin_count
    (0...@data.first.size).map do |attribute_index|
      (@maximums[attribute_index] - @minimums[attribute_index]) / bin_count.to_f
    end
  end

  # compute the number of bins for a given +q+
  def compute_bin_count q
    count = (@data.size / q.to_f).ceil
    count < 2 ? 2 : count
  end

end
