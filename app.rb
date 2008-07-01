require "rubygems"
require "sinatra"
require "gchart"
require "activesupport"

get "/hits-per-domain" do
  hits = Hash.new {|h, k| h[k] = Hash.new}
  web_data.each do |data|
    puts data.inspect
    hits["1min"].merge!(data["hits_per_domain"]["hit1"])
    hits["5min"].merge!(data["hits_per_domain"]["hit5"])
    hits["15min"].merge!(data["hits_per_domain"]["hit15"])
  end

  hits.each_pair do |scale, values|
    instance_variable_set("@top10_#{scale}", values.sort_by(&:last).reverse[0, 10])
  end

  erb :hits_per_domain
end

get "/disk-free" do
  @disk = []
  all_data.each do |data|
    name = data["name"]
    disk = data["disk"]
    disk.each_pair do |disk, data|
      @disk << ["#{name}@#{data["mountpoint"]}", data["free"]]
    end
  end

  @disk.sort!
  erb :disk_free
end

helpers do
  def all_data
    return @result if @result
    @result = Array.new
    Dir["data/*.yml"].each do |file|
      @result << YAML.load_file(file)
    end
    @result
  end

  def web_data
    return @result if @result
    @result = Array.new
    Dir["data/web*.yml"].each do |file|
      @result << YAML.load_file(file)
    end
    @result
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
end
