def mysql(*args)
  cmd = %w(mysql)
  cmd << "--batch"
  cmd << "--user=#{$db_username}" if $db_username
  cmd << "--password=#{$db_password}" if $db_password
  cmd << "--database=#{$db_database}" if $db_database
  cmd << "--host=#{$db_host}" if $db_host
  sh(cmd, args)
end

def sh(*args)
  cmd = args.flatten.join(" ")
  data = `#{cmd}`
  data
end
