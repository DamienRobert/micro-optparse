require 'nano-optparse/version'
require 'delegate'
require 'optparse'

class NanoParser < DelegateClass(OptionParser)
	def initialize(**default_settings)
		@default_settings=default_settings
		@options = {}
		@used_short = []
		@optionparser = OptionParser.new
		yield self if block_given?
		super(@optionparser)
	end

	def init_result
		@result={}
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

	def error(msg, exit_code: 1)
		warn msg
		exit exit_code
	end

	def opt(name, desc=nil, on: :on, **settings)
		name=name.to_sym
		settings = @default_settings.clone.merge(settings).merge({desc: desc})
		settings[:optname] ||= name.to_s.gsub("_", "-")
		settings[:short]||=short_from(name) if settings[:auto_short]
		settings[:class] ||= settings[:default].class == Fixnum ? Integer : settings[:default].class if settings[:auto_class]
		@options[name]=settings
		@used_short << settings[:short]
		args = [desc]
		args << "-" + settings[:short] if settings[:short]
		if [TrueClass, FalseClass, NilClass].include?(settings[:class]) # boolean switch
			args << "--[no-]" + optname
		else
			args << "--" + optname + " " + settings[:default].to_s
			args << settings[:class] if settings[:class]
		end
		args+=settings[:extra]||[]
		args=settings[:custom] if settings[:custom]
		@optionparser.send(on,*args) do |x|
			@result[name] = x
			yield(x) if block_given? #add specific optionparser options
		end
	end

	def validate(result)
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

	def process(arguments = ARGV, action: :'parse!')
		arguments=arguments.clone
		begin
			init_result
			@optionparser.send(action,arguments)
		rescue OptionParser::ParseError => e
			error e.message
		end
		validate(@result)
		@result, arguments
	end
end
