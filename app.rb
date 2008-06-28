require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"
require "time"

configure do
  $access_log_path = ENV["ACCESS_LOG_PATH"]
  ACCESS_LOG_LINE_REGEXP = /^([-\w]+)\s(\d+[.]\d+[.]\d+[.]\d+)\s\[(\d+\/\w+\/\d+):(\d\d:\d\d:\d\d)\s\+0000\]\s([^\s]+)\s"(GET|POST|HEAD|PUT|DELETE|OPTIONS|TRACE)\s([^\s]+)\s(\w+\/\d\.\d)"\s(\d+)\s(-|\d+)\s"([^"]*)"\s"([^"]*)"\s(\d+)$/.freeze
end

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)
  get_hits_per_domain(result)
  get_bytes_out(result)
  get_duration(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end

def get_hits_per_domain(result)
  data = result["hits_per_domain"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = 0}}

  top1 = data["top1"]
  top5 = data["top5"]
  top15 = data["top15"]

  elif_iterator($access_log_path, :parse_access_log_line, "timestamp") do |data, data1, data5, data15|
    top1[data["domain"]] += 1 if data1
    top5[data["domain"]] += 1 if data5
    top15[data["domain"]] += 1 if data15
  end
end

def get_bytes_out(result)
  hash = result["bytes_out"] = Hash.new {|h, k| h[k] = 0}

  now = Time.now.utc
  cutoff1 = (now - 60) .. now
  cutoff5 = (now - 5*60) .. now
  cutoff15 = (now - 15*60) .. now

  Elif.foreach($access_log_path) do |line|
    data = parse_access_log_line(line)
    next if data.empty?
    break unless cutoff15.include?(data["timestamp"])

    hash["1min"] += data["size"] if cutoff1.include?(data["timestamp"])
    hash["5min"] += data["size"] if cutoff5.include?(data["timestamp"])
    hash["15min"] += data["size"] if cutoff15.include?(data["timestamp"])
  end
end

def get_duration(result)
  hash = result["duration"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = 0}}

  dur1 = hash["1min"]
  dur5 = hash["5min"]
  dur15 = hash["15min"]

  values = Array.new(3)
  values[0] = Array.new
  values[1] = Array.new
  values[2] = Array.new

  now = Time.now.utc
  cutoff1 = (now - 60) .. now
  cutoff5 = (now - 5*60) .. now
  cutoff15 = (now - 15*60) .. now

  Elif.foreach($access_log_path) do |line|
    data = parse_access_log_line(line)
    next if data.empty?
    break unless cutoff15.include?(data["timestamp"])

    values[0] << data["duration"] if cutoff1.include?(data["timestamp"])
    values[1] << data["duration"] if cutoff5.include?(data["timestamp"])
    values[2] << data["duration"] if cutoff15.include?(data["timestamp"])
  end

  dur1.merge!(math_calc(values[0]))
  dur5.merge!(math_calc(values[1]))
  dur15.merge!(math_calc(values[2]))
end

def math_calc(values)
  return {"count" => 0, "mean" => 0.0, "stddev" => 0.0} if values.empty?
  count = values.length
  mean = values.inject {|memo, n| memo + n} / count.to_f
  stddev = Math.sqrt(values.map {|n| n - mean}.map {|n| n*n}.inject {|memo, n| memo + n} / (count.to_f - 1)) if mean.finite? && count.nonzero?
  {"count" => count, "mean" => mean, "stddev" => stddev}
end

# Returns a Hash that corresponds to each important thing in the access log
def parse_access_log_line(line)
  result = Hash.new
  match = ACCESS_LOG_LINE_REGEXP.match(line)
  if match then
    result["session"] = match[1]
    result["ip"] = match[2]
    result["timestamp"] = Time.parse("%s %s Z" % [match[3], match[4]])
    result["domain"] = match[5]
    result["path"] = match[7]
    result["response"] = match[9].to_i
    result["size"] = match[10].to_i
    result["referrer"] = match[11]
    result["user-agent"] = match[12]
    result["duration"] = match[13].to_i
  else
    #puts "Could not match:\n#{line}"
  end

  result
end
