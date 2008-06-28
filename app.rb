require "rubygems"
require "sinatra"

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end

def get_identity(result)
  result["name"] = ENV["FORGET_NAME"]
end

def get_loadavg(result)
  hash = result["loadavg"] = Hash.new
  uptime = `/usr/bin/uptime`
  if uptime =~ /(?:\s(\d+[.,]\d+)){3}$/ then
    loadaverages = $&.strip.split(/\s+/).map {|avg| avg.sub(",", ".")}.map {|avg| avg.to_f}
    hash["1min"] = loadaverages[0]
    hash["5min"] = loadaverages[1]
    hash["15min"] = loadaverages[2]
  end
end

def get_disk_free_space(result)
  disk = result["disk"] = Hash.new {|h, k| h[k] = Hash.new}
  data = `/bin/df -P -k`
  data.split("\n")[1..-1].each do |line|
    next unless line[0] == ?/
    cols = line.split(/\s+/)
    disk[cols[0]]["free"] = cols[3].to_i
    disk[cols[0]]["used"] = cols[2].to_i
    disk[cols[0]]["mountpoint"] = cols[5]
  end
end

def get_process_info(result)
  processes = result["processes"] = Hash.new {|h, k| h[k] = Hash.new}
  processes["count"] = `/bin/ps aux | /usr/bin/wc -l`.to_i - 1
end

# Reads the specified file backwards, and processes each line until
# the 15 minute cutoff is reached.
#
# +parser_method+ is the method that parses a single line of the log
# file.  This method must return an object that responds_to #[](key).
#
# +timestamp_key+ is the key that holds the timestamp of the line.
# The timestamp must already be parsed and be comparable with Time.
#
# This method expects a block and will yield the parsed line as
# well as three booleans for 1, 5 and 15 minute inclusion.
def elif_iterator(filename, parser_method, timestamp_key, now=Time.now.utc)
  cutoff1 = (now - 60) .. now
  cutoff5 = (now - 5*60) .. now
  cutoff15 = (now - 15*60) .. now

  Elif.foreach(filename) do |line|
    parsed_line = send(parser_method, line)
    next if parsed_line.empty?

    timestamp = parsed_line[timestamp_key]
    break unless cutoff15.include?(timestamp)

    yield parsed_line, cutoff1.include?(timestamp), cutoff5.include?(timestamp), true
  end
end
