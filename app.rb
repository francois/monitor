require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"
require "time"

configure do
  $access_log_path = File.dirname(__FILE__) + "/access.log"
  ACCESS_LOG_LINE_REGEXP = /^([-\w]+)\s(\d+[.]\d+[.]\d+[.]\d+)\s\[(\d+\/\w+\/\d+):(\d\d:\d\d:\d\d)\s\+0000\]\s([^\s]+)\s"(GET|POST|HEAD|PUT|DELETE|OPTIONS|TRACE)\s([^\s]+)\s(\w+\/\d\.\d)"\s(\d+)\s(-|\d+)\s"([^"]*)"\s"([^"]*)"\s(\d+)$/.freeze
end

configure :production do
  $access_log_path = "/var/www/xlsuite/shared/log/access.log"
end

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)
  get_hits_per_domain(result)
  get_bytes_out(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end

def get_hits_per_domain(result)
  data = result["hits_per_domain"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = 0}}

  now = Time.now.utc
  cutoff1 = (now - 60) .. now
  cutoff5 = (now - 5*60) .. now
  cutoff15 = (now - 15*60) .. now

  top1 = data["1min"]
  top5 = data["5min"]
  top15 = data["15min"]

  Elif.foreach($access_log_path) do |line|
    data = parse_access_log_line(line)
    next if data.empty?
    break unless cutoff15.include?(data["timestamp"])

    top1[data["domain"]] += 1 if cutoff1.include?(data["timestamp"])
    top5[data["domain"]] += 1 if cutoff5.include?(data["timestamp"])
    top15[data["domain"]] += 1 if cutoff15.include?(data["timestamp"])
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
