class Ranker

  def initialize attributes, data
    @attributes, @data = attributes, data
  end

  def ranking target, sample, n
    k = 3
    q = 5
    max_q = n / 4
    step_q = 10
    last_theta = n
    theta, s = calculate_theta(sample, k, q)

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

      theta, s = calculate_theta(sample, k, q)
    end

    s
  end

  private

  def ranked_outliers sample, k, q
    # compute bin widths (Q)
    # count numbers in bins and assign to bins

    (1..sample).each do |i|
      # choose a random set of k attributes, s
      c = 0

      @data.each do |x|
        next if x.clustered
        c += 1
        x.clustered = c
        # collect vector v of all unclustered points that are neighbors of x or
        # neighbors of members of v for all a in s
        # collect recursively until no additions can be made

        if v.emtpy?
          x.clustered = 0
        else
          v.map {|q| q.clustered = c }
        end
      end

      @data.each do |x|
        next unless x.clustered > 0
        x.clustered = 0
        x.score += 1
      end
    end

    # sort @data by score and return
  end

  def calculate_theta sample, k, n, q
    s = ranked_outliers(sample, k, q)
    theta = # number of points with score equal to n in S
    [theta, s]
  end

end
