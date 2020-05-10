require 'open-uri'
require 'nokogiri'

module Twstock
    class OpviewSimplefilter
        attr_reader :codes

        BASE_URL = 'https://www.opview.com.tw'

        ID = [
            'p1',  # '化學工業'
            'p2',  # '文化創意業'
            'p3',  # '半導體業'
            'p4',  # '生技醫療業'
            'p5',  # '光電業'
            'p6',  # '汽車工業'
            'p7',  # '其他電子業'
            'p8',  # '金融業'
            'p9',  # '建材營造'
            'p10', # '航運業'
            'p11', # '通信網路業'
            'p12', # '貿易百貨'
            'p13', # '塑膠工業'
            'p14', # '電子零組件業'
            'p15', # '電腦及週邊設備業'
            'p16', # '電機機械'
            'p17', # '鋼鐵工業'
            'p18'  # '觀光事業'
        ]

        def initialize
            @codes = parse(:html => get('/listed-and-otc-companies'))
        end

        private

        def get(path)
            request(path)
        end

        def request(path)
            connection(path)
        end

        def connection(path)
            @url = BASE_URL + path

            @charset = nil
            html = open(@url) do |f|
                @charset = f.charset
                f.read
            end

            @charset = html.scan(/charset="?([^\s"]*)/i).first.join if @charset.nil?

            html
        end

        def parse html:
            array = Array.new

            doc = Nokogiri::HTML.parse(html, nil, @charset)
            # => Nokogiri::HTML::Document

            ID.each do |id|
                nodes = doc.xpath("//div[@id='body']/section[@id='#{id}']/div[@class='cv-wrap-wrapper']/div/div[@class='wrap has-clearfix is-false no-sidebar']/div[@class='content-section-detail']/div[@class='cv-user-font']/div[@class='cv-content-row has-clearfix']/table[@width='520']")
                # => Nokogiri::XML::NodeSet

                raise TableFormatError if nodes.empty?
                raise TableFormatError unless nodes.length.is_one?

                node = nodes.first
                # => Nokogiri::XML::Element

                array.push parse_table(:element => node)
            end

            array
        end

        def parse_table element:
            parse_tr(:element => get_tbody(:element => element))
        end

        def get_tbody element:
            tbody = element.children.select { |e| e.element? }

            raise TableFormatError unless tbody.length.is_one?

            tbody.first
        end

        # column
        def parse_tr element:
            array = Array.new

            element.children.each do |e|
                next unless e.element?

                case e.name
                when 'tr'
                    value = parse_th_td(:element => e)

                    array.push value unless value.empty?
                else
                    raise TableFormatError
                end
            end

            array
        end

        # row
        def parse_th_td element:
            array = Array.new

            element.children.each do |e|
                next unless e.element?

                case e.name
                when 'th' then array.push e.children.text.gsub(/\<br\>/, '')
                when 'td' then array.push e.children.text
                #else raise TableFormatError
                end
            end

            array
        end
    end
end

class Integer
    def is_one?
        self == 1
    end
end
