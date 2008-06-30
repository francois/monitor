module CoreExt
  module Array
    def mean
      return 0.0 if self.empty?
      raise ArgumentError, "Can't calculate the mean of an Array with nil values in it" unless self.length == self.compact.length
      return self.first.to_f if self.length == 1
      self.sum(0.0) / self.length.to_f
    end

    def sum(identity=0)
      raise ArgumentError, "Can't calculate the mean of an Array with nil values in it" unless self.length == self.compact.length
      inject(identity) {|total, n| total + n}
    end

    def stddev
      count = self.length
      mean = self.mean
      return 0.0 if self.length == 1
      Math.sqrt(self.map {|n| n - mean}.map {|n| n*n}.inject {|memo, n| memo + n} / (count.to_f - 1)) if mean.finite? && count.nonzero?
    end
  end
end

Array.send :include, CoreExt::Array
