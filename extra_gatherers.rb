require "time"

configure do
  $access_log_path = ENV["ACCESS_LOG_PATH"]
  ACCESS_LOG_LINE_REGEXP = /^([-\w]+)\s(\d+[.]\d+[.]\d+[.]\d+)\s\[(\d+\/\w+\/\d+):(\d\d:\d\d:\d\d)\s\+0000\]\s([^\s]+)\s"(GET|POST|HEAD|PUT|DELETE|OPTIONS|TRACE)\s([^\s]+)\s(\w+\/\d\.\d)"\s(\d+)\s(-|\d+)\s"([^"]*)"\s"([^"]*)"\s(\d+)$/.freeze
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

  elif_iterator($access_log_path, :parse_access_log_line, "timestamp") do |data, data1, data5, data15|
    hash["1min"] += data["size"] if data1
    hash["5min"] += data["size"] if data5
    hash["15min"] += data["size"] if data15
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

  elif_iterator($access_log_path, :parse_access_log_line, "timestamp") do |data, data1, data5, data15|
    values[0] << data["duration"] if data1
    values[1] << data["duration"] if data5
    values[2] << data["duration"] if data15
  end

  dur1.merge!(math_calc(values[0]))
  dur5.merge!(math_calc(values[1]))
  dur15.merge!(math_calc(values[2]))
end

def math_calc(values)
  if values.empty? then
    {"count" => 0, "mean" => 0.0, "stddev" => 0.0}
  else
    {"count" => values.length, "mean" => values.mean, "stddev" => values.stddev}
  end
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
