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
