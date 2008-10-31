%w[open3 daemons socket singleton open-uri cgi pathname hpricot yaml net/https yaml].map{|s| require s}

=begin rdoc
In-channel commands:
<tt>>> CODE</tt>:: evaluate code in IRB.
<tt>reset_irb</tt>:: get a clean IRB session.
<tt>http://</tt>:: gets logged to a delicious account
=end

class Irbie

  attr_reader :config
  attr_accessor :oscar, :next_oscar, :pre_oscar

  #   next_oscar oscar

  # Make a new Irbie. Will not connect to the server until you call connect().
  def initialize(opts = {})

    # Defaults
    path = File.expand_path(".").to_s
    nick = opts[:nick] || config[:nick] || "irbie-dev"

    @config ||= {
      :svns => "#{path}/#{nick}.svns",
      :atoms => "#{path}/#{nick}.atoms",
      :pidfile => "#{path}/#{nick}.pid",
      :nick => nick,
      :channel => 'irbie-dev',
      :server => "irc.freenode.org",
      :delicious_user => nil,
      :delicious_pass => nil,
      :silent => false,
      :log => false,
      :logfile => "#{path}/#{nick}.log",
      :time_format => '%Y/%m/%d %H:%M:%S',
      :debug => false,
      :nick_pwd => false
    }

    # Nicely merge current options
    opts.each do |key, value|
      config[key] = value if value
    end

    # Initialise quote array
    self.oscar =  YAML::load(File.open('oscar.yaml'))

    # Initialise the next time a quote should be said
#    self.next_oscar = Time.now + 120
    self.next_oscar = Time.now.change(:hour => 5)
    self.next_oscar = self.next_oscar.tomorrow if self.next_oscar < Time.now

    #Initialize a list of pre-oscar quote sayings
    self.pre_oscar = [ "*yawn*. Need botcoffee. And an Oscar Wilde quote:", "*blink*. Herewith today's Oscar Wilde Quote:", "ohi. Need an Oscar Wilde Quote?:", "I am not a morning bot. But I can quote Oscar Wilde:", "*#{config[:nick]}* heads off to Starbots. But before he goes, he tosses out these words by Oscar Wilde:", "*#{config[:nick]}* got woken by the dulcet words of Oscar Wilde:", "Oscar Wilde la Vista baby:", "The daily search for botnirvana commences. First though, an Oscar Wilde quotation:" ]
  end

  # Connect and reconnect to the server
  def restart
    log "Restarting"
    puts config.inspect if config[:debug]

    @svns = (YAML.load_file config[:svns] rescue {})
    @atoms  = (YAML.load_file config[:atoms] rescue {})

    @socket.close if @socket
    connect
    listen
  end

  # Connect to the IRC server.
  def connect
    log "Connecting"
    @socket = TCPSocket.new(config[:server], 6667)
    write "USER #{config[:nick]} #{config[:nick]} #{config[:nick]} :#{config[:nick]}"
    write "NICK #{config[:nick]}"
    write "JOIN ##{config[:channel]}"
  end

  # The event loop. Waits for socket traffic, and then responds to it. The server sends <tt>PING</tt> every 3 minutes, which means we don't need a separate thread to check for svn updates. All we do is wake on ping (or channel talking).
  def listen
    @socket.each do |line|
      puts "GOT: #{line.inspect}" if config[:debug]
      #       poll if !config[:silent]

      case line.strip
      when /does not appear to be registered on this network|will change your nick/
        identify
      when /^PING/
        write line.sub("PING", "PONG")[0..-3]
      when /^ERROR/, /KICK ##{config[:channel]} #{config[:nick]} /
#           restart unless line =~ /PRIVMSG/
      when /:(.+?)!.* PRIVMSG ##{config[:channel]} \:\001ACTION (.+)\001/
          log "* #{$1} #{$2}"
      when /:(.+?)!.* PRIVMSG #{config[:nick]} \:(.+)/
          say_privately($1, $2)
      when /:(.+?)!(.+?) PRIVMSG ##{config[:channel]} \:(.+)/
          nick, email, msg = $1, $2, $3
        log "<#{nick}> #{msg}"
        if !config[:silent]
          case msg
          when /^>>\s*(.+)/ then try $1
          when /^#{config[:nick]}:\s*(.+)/
            to_try = $1
            if /oscar/i.match(to_try)
              quote_oscar(to_try.sub!(/oscar/i, ""))
            else
              try to_try unless /Spinach/.match(nick)
            end
           when /^reset_irb|^irb_reset/ then reset_irb
           when /(https?:\/\/.*?|\swww\..+?|:www\..+?)(\s|\r|\n|$)/ then post($1,nick,email) if config[:delicious_pass]
         end
      end
    end

      if self.next_oscar < Time.now
#        say ( self.pre_oscar[ rand(self.pre_oscar.size)] )
        quote_oscar("")
        self.next_oscar = self.next_oscar.tomorrow
      end

    end
  end

  # Send a raw string to the server.
  def write s
    raise RuntimeError, "No socket" unless @socket
    @socket.puts s += "\r\n"
    puts "WROTE: #{s.inspect}" if config[:debug]
  end

  # Write a string to the log, if the logfile is open.
  def log s
    # Open log, if necessary
    if config[:log]
      puts "LOG: #{s}" if config[:debug]
      File.open(config[:logfile], 'a') do |f|
        f.puts "#{Time.now.strftime(config[:time_format])} #{s}"
      end
    end
  end

  # Eval a piece of code in the <tt>irb</tt> environment.
  def try s
    reset_irb unless @session
    reset_irb if /^reset_irb|^irb_reset/.match(s)
    try_eval(s).select{|e| e !~ /^\s+from .+\:\d+(\:|$)/}.each {|e| say e} rescue say "session error"
  end

  # Say something in the channel.
  def say s
    write "PRIVMSG ##{config[:channel]} :#{s[0..450]}"
    log "<#{config[:nick]}> #{s}"
    sleep 1
  end

  # Say something privately
  def say_privately(nicko, msg)
    unless /VERSION/.match(msg)
      s2 = "PRIVMSG #{nicko} : #{config[:nick]} is a social creature, please speak to me in channel"
      write s2
      log "WROTE: #{s2}"
      sleep 1
    end
   end

  #identify myself to the nickserv and join the channel (seems to apply to atrum and not freenode)
  def identify
     write "NICKSERV :identify #{config[:nick_pwd]}"
     write "MODE #{config[:nick]} +B"
     write "JOIN ##{config[:channel]}"
  end

  # Get a new <tt>irb</tt> session.
  def reset_irb
    say "Began new irb session"
    @session = try_eval("!INIT!IRB!")
  end

  # Inner loop of the try method.
  def try_eval s
    reset_irb and return [] if s.strip == "exit"
    result = open("http://tryruby.hobix.com/irb?cmd=#{CGI.escape(s)}",
            {'Cookie' => "_session_id=#{@session}"}).read
    result[/^Your session has been closed/] ? (reset_irb and try_eval s) : result.split("\n").slice(0,20)
  end

  # Post a url to the del.icio.us account.
  def post (url, nick, email)
    return if /Spinach/.match(nick)
    puts "POST: #{url}" if config[:debug]
    email = email.sub(/\@.*?\./, "^")
    email = "" if /IP$/.match(email)
    url = url.sub(/\)$|'$|"$/, "")
    query = {:url => url,
      :description => (((Hpricot(open(url))/:title).first.innerHTML or url) rescue url),
      :tags => ( nick + " " + email),
      :replace => 'yes' }
    begin
      http = Net::HTTP.new('api.del.icio.us', 443)
      http.use_ssl = true
      response = http.start do |http|
        req = Net::HTTP::Get.new('/v1/posts/add?' + query.map{|k,v| "#{k}=#{CGI.escape(v)}"}.join('&'))
        req.basic_auth config[:delicious_user], config[:delicious_pass]
        http.request(req)
      end.body
      puts "POST: #{response.inspect}" if config[:debug]
    end
  end

  def quote_oscar(st)
      st.lstrip!
      st = $1 if (/\/(.+?)\/(.*?)/).match(st)
      re = Regexp.new(st, Regexp::IGNORECASE)
      found = self.oscar.find_all{ |e| e =~ re  }
      say ( '"' + found[rand(found.size)] + '" - Oscar Wilde')  if ! found.empty?
      say "Sorry, no Oscar Wilde quote found for #{st}" if found.empty?
  end

end

