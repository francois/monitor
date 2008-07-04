require "rubygems"
require "gchart"
require "activesupport"
require "controller_hit"
require "core_ext/array"

$: << "sinatra-0.2.2/lib"
require "sinatra"

get "/" do
  get_hits_data
  get_disk_data
  get_loadavg_data
  get_futures_data
  get_app_data

  @last_update = Time.now.utc

  erb :dashboard
end

get "/stylesheet.css" do
  header "Content-Type" => "text/css; charset=UTF-8"
  erb :stylesheet
end

get "/next-futures" do
  get_futures_data
  erb :next_futures
end

get "/current-futures" do
  get_futures_data
  erb :current_futures
end

get "/hits-per-domain" do
  get_hits_data
  erb :hits_per_domain
end

get "/disk-free" do
  get_disk_data
  erb :disk_free
end

get "/loadavg" do
  get_loadavg_data
  erb :loadaverage
end

get "/hits-per-controller" do
  get_app_data
  erb :hits_per_controller
end

def get_hits_data
  hits = Hash.new {|h, k| h[k] = Hash.new}
  web_data.each do |data|
    hits["1min"].merge!(data["hits_per_domain"]["hit1"])
    hits["5min"].merge!(data["hits_per_domain"]["hit5"])
    hits["15min"].merge!(data["hits_per_domain"]["hit15"])
  end

  hits.each_pair do |scale, values|
    instance_variable_set("@top10_#{scale}", values.sort_by(&:last).reverse[0, 10])
  end
end

def get_disk_data
  @disk = Hash.new {|h, k| h[k] = Array.new}
  all_data.each do |data|
    name = data["name"]
    disk = data["disk"]
    disk.each_pair do |device, data|
      mountpoint = data["mountpoint"]
      used, free = data["used"], data["free"]
      @disk[mountpoint] << [name, used, free]
    end
  end

  @disk
end

def get_loadavg_data
  @loadavg = Hash.new {|h, k| h[k] = Hash.new}
  all_data.each do |data|
    name = data["name"]
    data["loadavg"].each_pair do |key, value|
      @loadavg[key][name] = value
    end
  end

  @loadavg.each do |key, value|
    @loadavg[key] = value.sort
  end
end

def get_futures_data
  db = db_data.first
  @future_queue_length = db["future_queue_length"]
  @next_10_futures = db["next10"]

  @current_futures = Hash.new {|h, k| h[k] = Hash.new}
  future_data.each do |future|
    name = future["name"]
    future["current_futures"].each do |id, data|
      @current_futures[name][id] = data
    end
  end

  @current_futures = @current_futures.sort
end

def get_app_data
  @hits_per_controller = Hash.new {|h, k| h[k] = ControllerHit.new(k)}
  app_data.each do |app|
    app["hits_per_controller"]["5min"].each do |controller_name, actions|
      actions.each do |action_name, info|
        key = "%s/%s" % [controller_name, action_name]
        @hits_per_controller[key].hit(
          :count => info["total"].length,
          :render_time => info["rendering_mean"], :db_time => info["db_mean"], :total_time => info["total_mean"],
          :render_stddev => info["rendering_stddev"], :db_stddev => info["rendering_stddev"], :total_stddev => info["rendering_stddev"]
        )
      end
    end
  end

  @hits_per_controller = @hits_per_controller.values
  @top10_controllers = @hits_per_controller.sort_by(&:hits).reverse[0, 10]
  @top10_controllers_max = (@top10_controllers.first.hits / 8.0).round * 8.0

  @top10_controllers_labels = []
  (0..@top10_controllers_max).step((@top10_controllers_max / 4.0).round) do |value|
    @top10_controllers_labels << value
  end
end

helpers do
  def all_data
    return @all_data if @all_data
    @all_data = Array.new
    Dir["data/*.yml"].each do |file|
      @all_data << YAML.load_file(file)
    end
    @all_data
  end

  def web_data
    return @web_data if @web_data
    @web_data = Array.new
    Dir["data/web*.yml"].each do |file|
      @web_data << YAML.load_file(file)
    end
    @web_data
  end

  def app_data
    return @app_data if @app_data
    @app_data = Array.new
    Dir["data/app*.yml"].each do |file|
      @app_data << YAML.load_file(file)
    end
    @app_data
  end

  def db_data
    return @db_data if @db_data
    @db_data = Array.new
    Dir["data/db*.yml"].each do |file|
      @db_data << YAML.load_file(file)
    end
    @db_data
  end

  def future_data
    return @future_data if @future_data
    @future_data = Array.new
    Dir["data/future*.yml"].each do |file|
      @future_data << YAML.load_file(file)
    end
    @future_data
  end

  # Copied from ActionPack 2.1.0.
  def number_with_precision(number, precision=3)
    "%01.#{precision}f" % ((Float(number) * (10 ** precision)).round.to_f / 10 ** precision)
  rescue
    number
  end

  # Copied from ActionPack 2.1.0.
  def number_to_percentage(number, options = {})
    options   = options.stringify_keys
    precision = options["precision"] || 3
    separator = options["separator"] || "."

    begin
      number = number_with_precision(number, precision)
      parts = number.split('.')
      if parts.at(1).nil?
        parts[0] + "%"
      else
        parts[0] + separator + parts[1].to_s + "%"
      end
    rescue
      number
    end
  end

  # Copied from ActionPack 2.1.0.
  def number_to_human_size(size, precision=1)
    size = Kernel.Float(size)
    case
      when size.to_i == 1;    "1 Byte"
      when size < 1.kilobyte; "%d Bytes" % size
      when size < 1.megabyte; "%.#{precision}f KB"  % (size / 1.0.kilobyte)
      when size < 1.gigabyte; "%.#{precision}f MB"  % (size / 1.0.megabyte)
      when size < 1.terabyte; "%.#{precision}f GB"  % (size / 1.0.gigabyte)
      else                    "%.#{precision}f TB"  % (size / 1.0.terabyte)
    end.sub(/([0-9]\.\d*?)0+ /, '\1 ' ).sub(/\. /,' ')
  rescue
    nil
  end

  # Copied from ActionPack 2.1.0.
  def number_with_delimiter(number, delimiter=",", separator=".")
    begin
      parts = number.to_s.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      parts.join separator
    rescue
      number
    end
  end

  # Copied from ActionPack 2.1.0.
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
      when 0..1
        return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
        case distance_in_seconds
          when 0..4   then 'less than 5 seconds'
          when 5..9   then 'less than 10 seconds'
          when 10..19 then 'less than 20 seconds'
          when 20..39 then 'half a minute'
          when 40..59 then 'less than a minute'
          else             '1 minute'
        end

      when 2..44           then "#{distance_in_minutes} minutes"
      when 45..89          then 'about 1 hour'
      when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
      when 43200..86399    then 'about 1 month'
      when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
      when 525600..1051199 then 'about 1 year'
      else                      "over #{(distance_in_minutes / 525600).round} years"
    end
  end

  # Copied from ActionPack 2.1.0.
  def time_ago_in_words(from_time, include_seconds = false)
    distance_of_time_in_words(from_time, Time.now, include_seconds)
  end

  alias_method :distance_of_time_in_words_to_now, :time_ago_in_words

  def partial(template, *args)
    options = args.extract_options!
    if collection = options.delete(:collection) then
      locals = options.delete(:locals) || {}
      collection.inject([]) do |buffer, member|
        mylocals = {template.to_sym => member}.merge(locals)
        buffer << erb(template, options.merge(:layout => false, :locals => mylocals))
      end.join("\n")
    else
      erb(template, options)
    end
  end

  def bar_colors(quantity=8)
    nibbles = ["7A", "A4", "FB"].permutations
    nibbles[0, quantity].map {|set| set.join("")}
  end

  def next_runtime(next_future)
    scheduled_at = next_future[:scheduled_at]
    if scheduled_at < Time.now.utc then
      "ASAP"
    else
      "In #{distance_of_time_in_words_to_now(next_future[:scheduled_at], true)}"
    end
  end
end
