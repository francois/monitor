configure do
  $rails_log_path = ENV["RAILS_LOG_PATH"]

  RAILS_TIMESTAMP_REGEXP = /^Processing\s(\w+)#(\w+)\s\(for\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\sat\s(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\)\s\[(\w+)\]$/
  RAILS_DATA_REGEXP = /^Completed\sin\s(\d+\.\d+)\s\(\d+\sreqs\/sec\)\s\|\sRendering:\s(\d+\.\d+)\s\(\d+%\)\s\|\sDB:\s(\d+\.\d+)\s\(\d+%\)\s\|\s(\d+)\s(\w+)\s\[(.+)\]$/
end

def get_request_statistics(result)
  result["hits_per_controller"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Hash.new}}
  contr1 = result["hits_per_controller"]["1min"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Array.new}}}
  contr5 = result["hits_per_controller"]["5min"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Array.new}}}
  contr15 = result["hits_per_controller"]["15min"] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = Array.new}}}

  elif_iterator($rails_log_path, :rails_log_parser, "timestamp") do |data, data1, data5, data15|
    # If a request never completed, we will only have the timestamp line.
    next if data.keys.length == 1

    if data1 then
      contr1[data["controller"]][data["action"]]["total"] << data["total"]
      contr1[data["controller"]][data["action"]]["rendering"] << data["rendering"]
      contr1[data["controller"]][data["action"]]["db"] << data["db"]
    end

    if data5 then
      contr5[data["controller"]][data["action"]]["total"] << data["total"]
      contr5[data["controller"]][data["action"]]["rendering"] << data["rendering"]
      contr5[data["controller"]][data["action"]]["db"] << data["db"]
    end

    if data15 then
      contr15[data["controller"]][data["action"]]["total"] << data["total"]
      contr15[data["controller"]][data["action"]]["rendering"] << data["rendering"]
      contr15[data["controller"]][data["action"]]["db"] << data["db"]
    end
  end

  math_calc(contr1)
  math_calc(contr5)
  math_calc(contr15)
end

def math_calc(hash)
  hash.each_pair do |controller_name, actions|
    actions.each_pair do |action_name, times|
      times.each_pair do |name, values|
        next if name["_"]
        data = values.compact
        times[name + "_mean"] = data.mean
        times[name + "_stddev"] = data.stddev
        times[name + "_min"] = data.min
        times[name + "_max"] = data.max
      end
    end
  end
end

def rails_log_parser(line)
  @data ||= Hash.new
  if match = RAILS_DATA_REGEXP.match(line) then
    @data["total"] = match[1].to_f
    @data["rendering"] = match[2].to_f
    @data["db"] = match[3].to_f
    @data["url"] = match[6]
  elsif match = RAILS_TIMESTAMP_REGEXP.match(line) then
    @data["timestamp"] = Time.parse(match[4] + "+0000")
    @data["controller"] = match[1]
    @data["action"] = match[2]
    data, @data = @data, Hash.new
    return data
  end

  Hash.new
end
