#!/usr/bin/env ruby
# Copyright (c) 2005-2006 Mauricio Fernandez <mfp@acm.org> http://eigenclass.org
#
# Use and distribution subject to the terms of the Ruby license.

class XMPFilter
  VERSION = "0.3.0"

  MARKER = "!XMP#{Time.new.to_i}_#{Process.pid}_#{rand(1000000)}!"
  XMP_RE = Regexp.new("^" + Regexp.escape(MARKER) + '\[([0-9]+)\] (=>|~>) (.*)')
  VAR = "_xmp_#{Time.new.to_i}_#{Process.pid}_#{rand(1000000)}"
  WARNING_RE = /.*:([0-9]+): warning: (.*)/

  INITIALIZE_OPTS = {:interpreter => "ruby", :options => [], :libs => [],
                     :include_paths => []}
  def initialize(opts = {})
    options = INITIALIZE_OPTS.merge opts
    @interpreter = options[:interpreter]
    @options = options[:options]
    @libs = options[:libs]
    @include_paths = options[:include_paths]
    @output_stdout = false
  end

  def add_markers(code, min_codeline_size = 50)
    maxlen = code.map{|x| x.size}.max
    maxlen = [min_codeline_size, maxlen + 2].max
    ret = ""
    code.each do |l|
      l = l.chomp.gsub(/ # (=>|!>).*/, "").gsub(/\s*$/, "")
      ret << (l + " " * (maxlen - l.size) + " # =>\n")
    end
    ret
  end

  def annotate(code)
    idx = 0
    newcode = code.gsub(/^(.*) # =>.*/){|l| prepare_line($1, idx += 1) }
    stdout, stderr = execute(newcode)
    output = stderr.readlines
    results, exceptions = extract_data(output)
    idx = 0
    annotated = code.gsub(/^(.*) # =>.*/) do |l|
      expr = $1
      if /^\s*#/ =~ l
        l 
      else
        annotated_line(l, expr, results, exceptions, idx += 1)
      end
    end.gsub(/ # !>.*/, '').gsub(/# (>>|~>)[^\n]*\n/m, "");
    ret = final_decoration(annotated, output)
    if @output_stdout and (s = stdout.read) != ""
      ret << s.inject(""){|s,line| s + "# >> #{line}".chomp + "\n" }
    end
    ret
  end

  def annotated_line(line, expression, results, exceptions, idx)
    "#{expression} # => " + (results[idx].map{|x| x[1]} || []).join(", ")
  end
  
  def prepare_line_annotation(expr, idx)
    v = "#{VAR}"
    %!((#{v} = (#{expr}); $stderr.puts("#{MARKER}[#{idx}] => " + #{v}.class.to_s + " " + #{v}.inspect) || #{v}))!
  end
  alias_method :prepare_line, :prepare_line_annotation

  def execute_tmpfile(code)
    require 'tempfile'
    stdin, stdout, stderr = (1..3).map{ Tempfile.new("xmp_filter") }
    stdin.puts code
    [stdin, stdout, stderr].each{|x| x.close}
    exe_line = <<-EOF.map{|l| l.strip}.join(";")
      $stdout.reopen('#{stdout.path}', 'w')
      $stderr.reopen('#{stderr.path}', 'w')
      $0.replace '#{stdin.path}'
      ARGV.replace(#{@options.inspect})
      load #{stdin.path.inspect}
    EOF
    system(*(interpreter_command << "-e" << exe_line))
    stdout.open
    stderr.open
    [stdout, stderr]
  end

  def execute_popen(code)
    require 'open3'
    stdin, stdout, stderr = Open3::popen3(*interpreter_command)
    stdin.puts code
    stdin.close
    [stdout, stderr]
  end

  if /win|mingw/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM
    alias_method :execute, :execute_tmpfile
  else
    alias_method :execute, :execute_popen
  end

  def interpreter_command
    r = [@interpreter, "-w"]
    r << "-I#{@include_paths.join(":")}" unless @include_paths.empty?
    @libs.each{|x| r << "-r#{x}" } unless @libs.empty?
    r
  end

  def extract_data(output)
    results = Hash.new{|h,k| h[k] = []}
    exceptions = Hash.new{|h,k| h[k] = []}
    output.grep(XMP_RE).each do |line|
      result_id, op, result = XMP_RE.match(line).captures
      case op
      when "=>"
        klass, value = /(\S+)\s+(.*)/.match(result).captures
        results[result_id.to_i] << [klass, value]
      when "~>"
        exceptions[result_id.to_i] << result
      end
    end
    [results, exceptions]
  end

  def final_decoration(code, output)
    warnings = {}
    output.join.grep(WARNING_RE).map do |x|
      md = WARNING_RE.match(x)
      warnings[md[1].to_i] = md[2]
    end
    idx = 0
    ret = code.map do |line|
      w = warnings[idx+=1]
      w ? (line.chomp + " # !> #{w}") : line
    end
    output = output.reject{|x| /^-:[0-9]+: warning/.match(x)}
    if exception = /^-:[0-9]+:.*/m.match(output.join)
      ret << exception[0].map{|line| "# ~> " + line }
    end
    ret
  end
end # clas XMPFilter


class XMPTestUnitFilter < XMPFilter
  def initialize(opts = {})
    super
    @output_stdout = false
  end

  private
  def annotated_line(line, expression, results, exceptions, idx)
    indent =  /^\s*/.match(line)[0]
    assertions(expression.strip, results, exceptions, idx).map{|x| indent + x}.join("\n")
  end

  def prepare_line(expr, idx)
    basic_eval = prepare_line_annotation(expr, idx)
    %|begin; #{basic_eval}; rescue Exception; $stderr.puts("#{MARKER}[#{idx}] ~> " + $!.class.to_s); end|
  end

  def assertions(expression, results, exceptions, index)
    if !(wanted = results[index]).empty? || !exceptions[index]
      case (wanted[0][1] rescue 1)
      when "nil"
        nil_assertion(expression)
      else
        case wanted.size
        when 1
          value_assertions(wanted[0], expression)
        else
          # discard values from multiple runs
          ["#xmpfilter: WARNING!! extra values ignored"] +
            value_assertions(wanted[0], expression)
        end
      end
    else
      raise_assertion(expression, exceptions, index)
    end
  end

  def nil_assertion(expression)
    ["assert_nil(#{expression})"]
  end

  def raise_assertion(expression, exceptions, index)
    ["assert_raise(#{exceptions[index][0]}){#{expression}}"]
  end

  OTHER = Class.new
  def value_assertions(klass_value_txt_pair, expression)
    klass_txt, value_txt = klass_value_txt_pair
    value = eval(value_txt) || OTHER.new
    # special cases
    value = nil if value_txt.strip == "nil"
    value = false if value_txt.strip == "false"
    case value
    when Float
      ["assert_in_delta(#{value.inspect}, #{expression}, 0.0001)"]
    when Numeric, String, Hash, Array, Regexp, TrueClass, FalseClass, Symbol, NilClass
      ["assert_equal(#{value_txt}, #{expression})"]
    else
      [ "assert_kind_of(#{klass_txt}, #{expression})",
        "assert_equal(#{value_txt.inspect}, #{expression}.inspect)" ]
    end
  rescue
    return [ "assert_kind_of(#{klass_txt}, #{expression})",
             "assert_equal(#{value_txt.inspect}, #{expression}.inspect)" ]
  end
end

class XMPRSpecFilter < XMPTestUnitFilter
  private
  def execute(code)
    require 'tempfile'
    codefile = Tempfile.new("xmp_filter")
    File.open("#{codefile.path}.rb", "w"){|f| f.puts code}
    at_exit{ File.unlink "#{codefile.path}.rb" }
    require 'open3'
    args = *(interpreter_command << codefile.path)
    stdin, stdout, stderr = Open3::popen3(*args)
    stdin.close
    [stdout, stderr]
  end

  def interpreter_command
    [@interpreter] + @libs.map{|x| "-r#{x}"}
  end

  def nil_assertion(expression)
    ["(#{expression}).should_be_nil"]
  end

  def raise_assertion(expression, exceptions, index)
    ["lambda{(#{expression})}.should_raise #{exceptions[index][0]}"]
  end

  def value_assertions(klass_value_txt_pair, expression)
    klass_txt, value_txt = klass_value_txt_pair
    value = eval(value_txt) || OTHER.new
    # special cases
    value = nil if value_txt.strip == "nil"
    value = false if value_txt.strip == "false"
    case value
    when Float
      ["(#{expression}).should_be_close(#{value.inspect}, 0.0001)"]
    when Numeric, String, Hash, Array, Regexp, TrueClass, FalseClass, Symbol, NilClass
      ["(#{expression}).should_equal #{value_txt}"]
    else
      [ "(#{expression}).should_be_a_kind_of #{klass_txt}",
        "(#{expression}.inspect).should_equal #{value_txt.inspect}" ]
    end
  rescue
    return [ "(#{expression}).should_be_a_kind_of #{klass_txt}",
        "(#{expression}.inspect).should_equal #{value_txt.inspect}" ]
  end
end

#{{{ Main code
if __FILE__ == $0
  require 'optparse'
  require 'ostruct'

  options = OpenStruct.new
  options.interpreter = "ruby"
  options.options = ""
  options.mode = :annotation
  options.min_codeline_size = 50
  options.add_delimiters = false
  options.libs = []
  options.include_paths = []
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: xmpfilter.rb [options] [inputfile] [-- cmdline args]"

    opts.separator ""
    opts.separator "Modes:"
    opts.on("-a", "--annotations", "Annotate code (default)") do
      options.mode = :annotation
    end
    opts.on("-u", "--unittest", "Complete Test::Unit assertions.") do 
      options.mode = :unittest
    end
    opts.on("-s", "--spec", "Complete RSpec expectations.") do
      options.mode = :rspec
      options.interpreter = "spec"
    end
    opts.on("-m", "--markers", "Add # => markers.") do
      options.mode = :marker
    end

    opts.separator ""
    opts.separator "Interpreter options:"
    opts.on("-I PATH", "Add PATH to $LOAD_PATH") do |path|
      options.include_paths << path
    end
    opts.on("-r LIB", "Require LIB before execution.") do |lib|
      options.libs << lib
    end

    opts.separator ""
    opts.on("-S FILE", "--interpreter FILE", "Use interpreter FILE.") do |interpreter|
      options.interpreter = interpreter
    end
    opts.on("-l N", "--min-line-length N", Integer, "Align markers to N spaces.") do |interpreter|
      options.min_codeline_size = min_codeline_size
    end
    opts.on("--[no]-delimiters", "Put delimiters around code.",
            "(default: disabled)"){|v| options.add_delimiters = v }
    opts.separator ""
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
    opts.on("-v", "--version", "Show version information") do
      puts "xmpfilter.rb #{XMPFilter::VERSION}"
      exit
    end
  end

  if idx = ARGV.index("--")
    extra_opts = ARGV[idx+1..-1]
    ARGV.replace ARGV[0...idx]
  else
    extra_opts = []
  end
  opts.parse!(ARGV)

  klass = case options.mode
  when :annotation; XMPFilter
  when :unittest;   XMPTestUnitFilter
  when :rspec;      XMPRSpecFilter
  else XMPFilter
  end

  xmp = klass.new(:interpreter => options.interpreter, :options => extra_opts,
                  :include_paths => options.include_paths, :libs => options.libs)

  case options.mode
  when :marker     : puts xmp.add_markers(ARGF.read, options.min_codeline_size)
  when :annotation, :unittest, :rspec
    puts xmp.annotate(ARGF.read)
  else
    puts opts
    exit
  end
end
