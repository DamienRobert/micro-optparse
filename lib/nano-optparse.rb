require 'nano-optparse/version'
require 'delegate'
require 'optparse'

class NanoParser < DelegateClass(OptionParser)
	attr_accessor :banner, :version
	def initialize(**default_settings)
		@default_settings=default_settings
		@options = {}
		@used_short = []
		init_optparse
		yield self if block_given?
		super(@optionparser)
	end

	def init_optparse
		@optionparser = OptionParser.new do |p|
			p.banner = @banner unless @banner.nil?
			p.on_tail("-h", "--help", "Show this message") {puts p ; exit}
			p.on_tail("--version", "Print version") {puts @version ; exit}
		end
	end

	def default_result
		@options.each do |k,v|
			@result[k]=v[:default] if v.key?(:default)
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

	def opt(name, desc=nil, **settings)
		name=name.to_sym
		settings = @default_settings.clone.merge(settings).merge({desc: desc})
		settings[:optname] ||= name.to_s.gsub("_", "-")
		@used_short << (settings[:short]||=short_from(name)) unless settings[:no_short]
		@options[name]=settings
		@result[name] = settings[:default] || false unless settings[:optional] # set default
		klass = settings[:class] || (settings[:default].class == Fixnum ? Integer : settings[:default].class)
		args = [description]
		args << "-" + settings[:short] if settings[:short]
		if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
			args << "--[no-]" + optname
		else # argument with parameter, add class for typecheck
			args << "--" + optname + " " + settings[:default].to_s
			args << klass if klass
		end
		@optionparser.on(*args) do |x|
			@result[name] = x
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
			default_result
			@optionparser.send(action,arguments)
		rescue OptionParser::ParseError => e
			error e.message ; exit(1)
		end
		validate(@result)
		@result, arguments
	end
end
