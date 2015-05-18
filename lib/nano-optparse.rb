require 'nano-optparse/version'
require 'optparse'

class NanoParser
	attr_accessor :banner, :version
	def initialize(**default_opts)
		@default_opts=default_opts
		@options = {}
		@default_values = {}
		@used_short = []
		init_optparse
		yield self if block_given?
	end

	def init_optparse
		@optionparser = OptionParser.new do |p|
			p.banner = @banner unless @banner.nil?
			p.on_tail("-h", "--help", "Show this message") {puts p ; exit}
			p.on_tail("--version", "Print version") {puts @version ; exit}
		end
	end

	def short_from(name)
		name.to_s.chars.each do |c|
			next if @used_short.include?(c) || c == "_"
			return c # returns from short_from method
		end
		return name.to_s.chars.first
	end

	def error(msg)
		warn msg
		exit 1
	end

	def opt(name, desc=nil, **opts)
		opts = @default_opt.clone.merge(opts)
		@options[name]=opts.merge({desc: desc})
		@used_short << short = opts[:no_short] ? nil : opts[:short] || short_from(name)
		@result[name] = opts[:default] || false unless opts[:optional] # set default
		optname = name.to_s.gsub("_", "-")
		klass = opts[:default].class == Fixnum ? Integer : opts[:default].class
		args = [description]
		args << "-" + short if short
		if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
			args << "--[no-]" + optname
		else # argument with parameter, add class for typecheck
			args << "--" + optname + " " + opts[:default].to_s << klass
		end
		@optionparser.on(*args) do |x|
			@result[o[:name]] = x}
			yield(x) if block_given? #add specific optionparser options
		end
	end

	def validate(result) # remove this method if you want fewer lines of code and don't need validations
		result.each_pair do |key, value|
			o = @options[key]
			case o.check
			when Array, Set
				o.check.include?(value) or error "Parameter for #{key} must be in [" << o.check.join(", ") << "]"
			when Regexp
				o.check.match?(value) or error "Parameter for #{key} must match /" << o.check.source << "/"
			when Proc
				o.check.call(value) or error "Parameter for #{key} must satisfy the Proc" 
			end
		end
	end

	def process!(arguments = ARGV, action: :'parse!')
		begin
			@optionparser.send(action,arguments)
		rescue OptionParser::ParseError => e
			error e.message ; exit(1)
		end
		validate(@result)
		@result
	end
end
