module CoreExt
  module Array
    def mean
      self.sum / self.length.to_f
    end

    def sum(identity=0)
      inject(identity) {|total, n| total + n}
    end

    def stddev
      0.0
    end
  end
end

Array.send :include, CoreExt::Array
