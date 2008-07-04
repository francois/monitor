require "stringio"

configure do
  $future_log_dir = ENV["FUTURE_LOG_DIR"]
  raise ArgumentError, "FUTURE_LOG_DIR unset or does not point to a directory: #{$future_log_dir.inspect}" unless File.directory?($future_log_dir)

  $future_log_file = ENV["FUTURE_LOG_FILE"]
  $future_log_file = File.join($future_log_dir, $future_log_file) unless File.file?($future_log_file)
  raise ArgumentError, "FUTURE_LOG_FILE does not point to a log file, or it is not a file: #{$future_log_file.inspect}" unless File.file?($future_log_file)

  LOG_LINE_REGEXP = /^(\d+):(\d+)\s-\s(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s-\s(\w+)(?:\s(\d+):(\w+)(?:\s(.*))?)?$/
end

def get_current_futures(result)
  hash = result["current_futures"] = Hash.new {|h, k| h[k] = Hash.new}
  Dir[File.join($future_log_dir, "future-state-*.log")].each do |file|
    instance_id = File.basename(file)[/\d+/].to_i
    line = File.read(file)
    fields = line.split(/\s+/, 5)
    hash[instance_id]["state"] = fields[1]
    hash[instance_id]["type"] = fields[2].nil? || fields[2].empty? ? nil : fields[2]
    hash[instance_id]["args"] = fields[3].nil? || fields[3].empty? ? nil : YAML.load(fields[3])
  end
end

def get_last_futures(result)
  futures1 = result["history1"] = Array.new
  futures5 = result["history5"] = Array.new
  futures15 = result["history15"] = Array.new
  elif_iterator($future_log_file, :parse_log_line, "timestamp") do |data, data1, data5, data15|
    futures1 << data if data1
    futures5 << data if data5
    futures15 << data if data15
  end
end

def parse_log_line(line)
  data = Hash.new
  match = LOG_LINE_REGEXP.match(line)
  return data unless match

  data["instance_id"] = match[2].to_i
  data["timestamp"] = Time.parse(match[3] + "+0000")
  data["state"] = match[4]
  data["type"] = match[6]
  data
end
