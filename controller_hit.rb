class ControllerHit
  attr_reader :controller_name, :action_name, :hits

  def initialize(key)
    @controller_name, @action_name = *key.split("/")
    @hits = @counts = 0
    @total_render_time = @total_db_time = @total_total_time = 0.0
    @total_stddev_render_time = @total_stddev_db_time = @total_stddev_total_time = 0.0
  end

  def hit(*args)
    options = args.extract_options!

    @hits += options[:count]
    @counts += 1

    @total_render_time  += options[:render_time] if options[:render_time]
    @total_db_time      += options[:db_time] if options[:db_time]
    @total_total_time   += options[:total_time] if options[:total_time]

    @total_stddev_render_time  += options[:render_stddev] if options[:render_stddev]
    @total_stddev_db_time      += options[:db_stddev] if options[:db_stddev]
    @total_stddev_total_time   += options[:total_stddev] if options[:total_stddev]
  end

  def mean_render_time
    @total_render_time / @counts
  end

  def mean_db_time
    @total_db_time / @counts
  end

  def mean_total_time
    @total_total_time / @counts
  end

  def stddev_render_time
    @total_stddev_render_time / @counts
  end

  def stddev_db_time
    @total_stddev_db_time / @counts
  end

  def stddev_total_time
    @total_stddev_total_time / @counts
  end

  def to_s
    "%s/%s" % [@controller_name, @action_name]
  end
end
