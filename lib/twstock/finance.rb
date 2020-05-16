require File.expand_path(File.dirname(__FILE__)) + '/finance/version'
require File.expand_path(File.dirname(__FILE__)) + '/finance/histock_filter'

module Twstock
    class Finance
        include HistockFilter

        def initialize
        end
    end
end
