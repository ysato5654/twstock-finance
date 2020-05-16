module Twstock
    class Error < StandardError
    end

    class NoSupportedFunction < Error; end

    class ArgumentError < Error; end

    class MergeError < Error
        attr_reader :message

        def initialize
            @message = 'multiple component'
        end
    end

    class TableFormatError < Error; end
end
