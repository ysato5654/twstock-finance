#! /opt/local/bin/ruby
# coding: utf-8

require 'optparse'

module TweetActivityScript
    class CommandLineOption
        def initialize(params:)
            @opt = OptionParser.new

            @option = Hash.new

            params.each do |param|
                @opt.on('-' + param[:short], '--' + param[:long] + ' VAL', param[:arg], param[:description]) { |v| @option[param[:long].to_sym] = v }
            end
        end

        # @raise [SystemExit] with help option
        # @raise [OptionParser::InvalidOption]
        # @raise [OptionParser::MissingArgument]
        # @raise [OptionParser::InvalidArgument]
        # @raise [TweetActivityScript::MissingOption] no mandatory option
        def parse()
            @opt.parse(ARGV)

            # no mandatory option
            raise MissingOption if @option.empty?

            @option
        end
    end

    class Error < StandardError; end

    class SystemExit < Error; end

    class MissingOption < Error
        attr_reader :message

        def initialize
            @message = 'no option:'
        end
    end
end
