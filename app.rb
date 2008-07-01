require "rubygems"
require "gchart"
require "activesupport"

$: << "sinatra-0.2.2/lib"
require "sinatra"

get "/hits-per-domain" do
  hits = Hash.new {|h, k| h[k] = Hash.new}
  web_data.each do |data|
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
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(template, options.merge(:layout => false, :locals => {template.to_sym => member}))
      end.join("\n")
    else
      erb(template, options)
    end
  end
end
