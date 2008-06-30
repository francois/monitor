require "elif"

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
