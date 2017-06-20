require 'httparty'
require 'ipaddress'
require 'resolv'

USAGE = <<ENDUSAGE
Usage:
   directory_enum.rb [options] file_location
ENDUSAGE

HELP = <<ENDHELP
   -h, --help       Show this help.
   -v, --version    Show the version number.
   -l, --logfile    Specify the filename to log to. 
   -V. --verbose    Output in verbose mode. (NOT YET IMPLEMENTED)
   -t, --tld        Top level domain.
   -d, --domain     Check for subdomains.
   -D, --directory  Check for subdirectories.
   -T, --threads    Number of threads.
ENDHELP

VERSION = <<ENDVERSION
Version: ip_list_builder 1.0
ENDVERSION

ARGS = {:help=>false, :version=>false, :verbose=>false, :tld=>false, :domain=>false, :dir=>false}
$domain_response = {:usable=>"", :unusable=>""}
$directory_response = {:one=>"", :two=>"", :three=>"", :four=>"", :five=>"", :unusable=>""}

UNFLAGGED_ARGS = [ :directory ]              # Bare arguments (no flag)
next_arg = UNFLAGGED_ARGS.first
files = Array.new

ARGV.each do |arg|
  case arg
    when '-h','--help'        then ARGS[:help]      = true
    when '-v','--version'     then ARGS[:version]   = true
    when '-V','--verbose'     then ARGS[:verbose]   = true
    when '-d','--domain'      then ARGS[:domain]    = true
    when '-D','--directory'   then ARGS[:dir] = true
    when '-l','--logfile'     then next_arg = :logfile
    when '-t','--tld'         then next_arg = :tld
    when '-T','--threads'     then next_arg = :threads
    else
    	if File.exist?(arg)
			files.push(arg)
		end
	      if next_arg
	    	ARGS[next_arg] = arg
	      	UNFLAGGED_ARGS.delete( next_arg )
        end
        next_arg = UNFLAGGED_ARGS.first
    end
end

if !ARGS[:tld]
  puts USAGE + "\n"
  puts VERSION + "\n"
  puts HELP + "\n"
  exit
end

def running_thread_count
    num_of_threads = Thread.list.select {|thread| thread.status == "run"}.count
    return num_of_threads
end

def domain_response_checker(url)
  begin
    response = HTTParty.get(url, { timeout: 10 })
    if response.code > 1
      $domain_response[:usable] << "#{url}\n"
    else
      $domain_response[:unusable] << "#{url}\n"
    end
  rescue
  end
end

def directory_response_checker(url)
  puts "this has begun"
  begin
    response = HTTParty.get(url, { timeout: 10 })
    if response.code > 99 and response.code < 199
      $directory_response[:one] << "#{url}\n"
    elsif response.code > 199 and response.code < 299
      $directory_response[:two] << "#{url}\n"
    elsif response.code > 299 and response.code < 399
      $directory_response[:three] << "#{url}\n"
    elsif response.code > 399 and response.code < 499
       $directory_response[:four] << "#{url}\n"
    elsif response.code > 499 and response.code < 599
      $directory_response[:five] << "#{url}\n"
    else
      $directory_response[:unusable] << "#{url}\n"
    end
  rescue
  end
end

def enum_domains(file_list)
  thread_builder = []
  docs = file_list
  docs.each do |file|
    doc = File.open(file)
      doc.each do |element|
        element.chomp!
        thread_builder.push(element)
      end
      while !thread_builder.empty?
        if running_thread_count < ARGS[:threads].to_i
          i = thread_builder.pop
          var = Thread.new{domain_response_checker("http://#{i}.#{ARGS[:tld]}")}
        end
        var.join
      end
  end
end

def enum_directories(file_list)
  thread_builder = []
  docs = file_list
  docs.each do |file|
    doc = File.open(file)
      doc.each do |element|
        element.chomp!
        thread_builder.push(element)
      end
      while !thread_builder.empty?
        if running_thread_count < ARGS[:threads].to_i
          i = thread_builder.pop
          var = Thread.new{directory_response_checker("http://#{ARGS[:tld]}/#{i}")}
        end
        var.join
      end
  end
end

if ARGS[:help] or !ARGS[:directory] and !ARGS[:version]
    puts HELP if ARGS[:help]
    exit
end

if ARGS[:version]
	  puts VERSION
end

if ARGS[:logfile]
    $stdout.reopen( ARGS[:logfile], "w" )
    $stdout.sync = true
    $stderr.reopen( $stdout )
end

if ARGS[:dir]
  puts ARGS[:dir]
  enum_directories(files)
end

if ARGS[:domain]
  enum_domains(files)
end

if $domain_response[:usable].length > 1
  puts "-------------DOMAIN USABLE-------------\n"
  puts $domain_response[:usable]
end

if $domain_response[:unusable].length > 1
  puts "------------DOMAIN UNUSABLE------------\n"
  puts $domain_response[:unusable]
end
puts "\n\n"
if $directory_response[:one].length > 1
  puts "-------------RESPONSE 100-------------\n"
  puts $directory_response[:one]
end

if $directory_response[:two].length > 1
  puts "-------------RESPONSE 200-------------\n"
  puts $directory_response[:two]
end

if $directory_response[:three].length > 1
  puts "-------------RESPONSE 300-------------\n"
  puts $directory_response[:three]
end

if $directory_response[:four].length > 1
  puts "-------------RESPONSE 400-------------\n"
  puts $directory_response[:four]
end

if $directory_response[:five].length > 1
  puts "-------------RESPONSE 500-------------\n"
  puts $directory_response[:five]
end

if $directory_response[:unusable].length > 1
  puts "-------------RESPONSE UNKNOWN-------------\n"
  puts $directory_response[:unusable]
end