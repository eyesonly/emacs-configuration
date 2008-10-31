#!/usr/bin/env ruby
require 'open3'

MARKER = "!XMP#{Time.new.to_i}_#{rand(1000000)}!"
XMPRE = Regexp.new("^" + Regexp.escape(MARKER) + '\[([0-9]+)\] => (.*)')
VAR = "_xmp_#{Time.new.to_i}_#{rand(1000000)}"
WARNING_RE = /-:([0-9]+): warning: (.*)/
interpreter = ARGV.shift || "ruby"
code = ARGF.read

idx = 0
newcode = code.gsub(/^(.*) # =>.*/) do |l|
  expr = $1
  (/^\s*#/ =~ l) ? l :
  %!((#{VAR} = (#{expr}); $stderr.puts("#{MARKER}[#{idx+=1}] => " + #{VAR}.inspect) || #{VAR}))!
end
stdin, stdout, stderr = Open3::popen3(interpreter, "-w")
stdin.puts newcode
stdin.close
output = stderr.readlines

results = Hash.new{|h,k| h[k] = []}
output.grep(XMPRE).each do |line|
  result_id, result = XMPRE.match(line).captures
  results[result_id.to_i] << result
end

idx = 0
annotated = code.gsub(/^(.*) # =>.*/) do |l|
  expr = $1
  (/^\s*#/ =~ l) ? l : "#{expr} # => " + (results[idx+=1] || []).join(", ")
end.gsub(/ # !>.*/, '').gsub(/# (>>|~>)[^\n]*\n/m, "");

warnings = {}
output.join.grep(WARNING_RE).map do |x|
  md = WARNING_RE.match(x)
  warnings[md[1].to_i] = md[2]
end
idx = 0
annotated = annotated.map do |line|
  w = warnings[idx+=1]
  w ? (line.chomp + " # !> #{w}") : line
end
puts annotated
output.reject!{|x| /^-:[0-9]+: warning/.match(x)}
if exception = /^-:[0-9]+:.*/m.match(output.join)
  puts exception[0].map{|line| "# ~> " + line }
end
if (s = stdout.read) != ""
  puts "# >> #{s.inspect}" 
end
