require "rubygems"
require "gchart"
require "activesupport"
require "controller_hit"

$: << "sinatra-0.2.2/lib"
require "sinatra"

get "/" do
  get_hits_data
  get_disk_data
  get_loadavg_data
  get_futures_data
  get_app_data

  erb :dashboard
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
  @disk = []
  all_data.each do |data|
    name = data["name"]
    disk = data["disk"]
    disk.each_pair do |disk, data|
      @disk << ["#{name}@#{data["mountpoint"]}", data["free"]]
    end
  end

  @disk.sort!
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

  def partial(template, *args)
    options = args.extract_options!
    puts "partial(#{template.inspect}, #{args.inspect}, #{options.inspect})"
    if collection = options.delete(:collection) then
      puts "Rendering collection partial"
      collection.inject([]) do |buffer, member|
        puts options.merge(:layout => false, :locals => {template.to_sym => member}).inspect
        buffer << erb(template, options.merge(:layout => false, :locals => {template.to_sym => member}))
      end.join("\n")
    else
      erb(template, options)
    end
  end
end
