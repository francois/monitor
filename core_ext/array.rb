class Array
  def permutations
    values = (0 ... length).to_a
    indexes = []
    visit_permutation(values, 0, length, indexes)
    indexes.inject([]) do |result, orders|
      row = Array.new
      orders.each do |index|
        row << self[index]
      end
      result << row
    end
  end

  # Inspired by an algorithm found on http://www.bearcave.com/random_hacks/permute.html, written by Ian Kaplan.
  # The code on the page is itself inspired by the University of Exeter algorithm.
  # Rewritten in Ruby by François Beausoleil.
  def visit_permutation(v, start, n, accum)
    if start == n - 1 then
      accum << v.dup
    else
      (start ... n).each do |i|
        tmp = v[i]

        v[i] = v[start]
        v[start] = tmp
        visit_permutation(v, start+1, n, accum)
        v[start] = v[i]
        v[i] = tmp
      end
    end
  end
end
