import os
import sys
import datetime
import argparse
import csv
import subprocess
import re
from re import sub
import requests
from retry import retry

import twstock

__version__ = '0.1.0'

class MissingOption(Exception):
    pass

class ParseError(Exception):
    pass

class CommandLineOption():
    def parse(self):
        parser = argparse.ArgumentParser()

        parser.add_argument('-f', '--file', type=str, help='stock code list file')
        parser.add_argument('-m', '--market', type=str, choices=StockFundamental.Market['english'], help='market (%s)' % ('/'.join(StockFundamental.Market['english'])))
        parser.add_argument('--version', action='version', version='%s Ver.%s' % (os.path.basename(__file__), __version__), help='show version and exit')

        args = parser.parse_args()

        if self.__is_missing_option(args):
            raise MissingOption('missing option')

        return args

    def __is_missing_option(self, option):
        if option.file == None:
            if option.market == None:
                return True

        return False

class ParseCodeList():

    Key = {
        'chinese' : ['代號', '名稱', '市場'],
        'english' : ['code', 'company', 'market'],
    }

    """
    raise   FileNotFoundError/ParseError
    """
    def __init__(self, path:str):
        self.code_list = []

        if not os.path.exists(path):
            raise FileNotFoundError('no such file or directory - %s' % path)

        with open(path, 'r') as file:
            reader = csv.reader(file, delimiter=',')
            list = [row for row in reader]

        if not self.Key['chinese'] == list[0]:
            raise ParseError('not expected key - %s' % str(list[0]))

        key = self.Key['english']

        self.code_list = [dict(zip(key, value)) for value in list[1:]]

class RubyScript():

    FILE_NAME = 'script_show_stock_fundamentals.rb'

    """
    raise   FileNotFoundError
    """
    def __init__(self, code:str='', market:str='', sector:str=''):
        self.output = []

        path = self.FILE_NAME

        if not os.path.exists(path):
            raise FileNotFoundError('no such file or directory - %s' % path)

        if not code == '':
            self.cmd = ['ruby', path, '--code=' + code]
        else:
            self.cmd = ['ruby', path, '--market=' + market, '--sector=' + sector]

    """
    return      True        finish process with return code 0
                False       finish process with return code NOT 0
    """
    def exec(self) -> bool:
        proc = subprocess.Popen(self.cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        while proc.poll() is None:
            line = proc.stdout.readline()
            print(line.rstrip())
            self.output.append(line)

        stderr = proc.stderr.read()

        if not stderr == '':
            print('----')
            print(stderr)
            print('----')

        return True if proc.returncode == 0 else False

    """
    raise   ParseError
    """
    def parse(self) -> list:
        company_profiles = []

        key = self.__fetch_header()
        if key == []:
            raise ParseError('not found header pattern')

        pattern = '^([0-9]{4})'

        for line in self.output:
            if not re.match(pattern, line):
                continue

            value = line.rstrip('\n').split('\t')

            if not len(key) == len(value):
                #warn_message(msg='unexpected list size', detail=str(value))
                print(value)
                continue

            company_profiles.append(dict(zip(key, value)))

        return company_profiles

    def __fetch_header(self) -> list:
        pattern = '^code'

        list = []
        for line in self.output:
            if not re.match(pattern, line):
                continue

            list = line.rstrip('\n').split('\t')
            break

        return list

class StockFundamental():

    Market = {
        'chinese' : ['上市', '上櫃'],
        'english' : ['twse', 'tpex'],
    }

    def __init__(self):
        self.list = []
        # => self.list = [
           #    {
           #        'code': '1338', 
           #        'company': '廣華控股有限公司', 
           #        'issued_shares': '83,840,000', 
           #        'PER': '16.79', 
           #        'PBR': '0.78', 
           #        'ROE': '4.31', 
           #        'ROA': '2.97', 
           #        'price': '57.6000', 
           #        'market_capitalization': '4829184000.0'
           #    },
           #    {}
           # ]

    """
    brief       fetch stock fundamental by executing ruby script
    argument    market      market filter
                sector      sector filter
    return      True        fetch success
                False       fetch fail (not found ruby script / execute script error / parse error)
    """
    def fetch(self, code:str='', market:str='', sector:str='') -> bool:
        print('execute ruby')

        try:
            script = RubyScript(code=code) if not code == '' else RubyScript(market=market, sector=sector)
        except FileNotFoundError as e:
            print('%s:%s: %s (%s)' % (__file__, 'error', e, e.__class__.__name__))
            return False

        if not script.exec():
            print('%s:%s: %s - %s' % (__file__, 'error', 'finish ruby with error', script.FILE_NAME))
            return False

        try:
            self.list = script.parse()
        except ParseError as e:
            print('%s:%s: %s (%s)' % (__file__, 'error', e, e.__class__.__name__))
            return False

        return True

    """
    brief       load stock fundamental from file
    argument    path        file path
    return      True        load success
                False       load fail (not found file path)
    """
    def load(self, path:str) -> bool:
        if not os.path.exists(path):
            print('%s:%s: %s - %s (%s)' % (__file__, 'error', 'no such file or directory', path, 'FileNotFoundError'))
            return False

        self.list = []

        pattern = '^code'

        with open(path, 'r') as f:
            for index, line in enumerate(f.readlines()):
                if index == 0:
                    key = line.rstrip('\n').split(' ')
                else:
                    value = line.rstrip('\n').split(' ')
                    self.list.append(dict(zip(key, value)))

        return True

    """
    brief       insert stock price in stock fundamental
    argument    None
    return      None
    """
    def insert_price(self) -> None:
        extended_list = []

        for fundamental in self.list:
            extended_fundamental = fundamental.copy()

            #info = twstock.realtime.get(extended_fundamental['code'])
            try:
                info = self.__get_realtime_info(code=extended_fundamental['code'])
            except requests.ConnectionError as e:
                print('%s:%s: %s - code=%s (%s)' % (__file__, 'warn', e, extended_fundamental['code'], e.__class__.__name__))
                extended_fundamental['price'] = str(0)
            else:
                try:
                    extended_fundamental['price'] = info['realtime']['latest_trade_price']
                except KeyError as e:
                    print('%s:%s: %s - code=%s (%s)' % (__file__, 'warn', e, info, e.__class__.__name__))
                    extended_fundamental['price'] = str(0)

            try:
                price = float(extended_fundamental['price'])
            except ValueError as e:
                print('%s:%s: %s - code=%s (%s)' % (__file__, 'warn', e, extended_fundamental['code'], e.__class__.__name__))
                price = 0

            issued_shares = extended_fundamental['issued_shares'].replace(',', '')
            market_capitalization = price * float(issued_shares)

            extended_fundamental['market_capitalization'] = str(market_capitalization)

            extended_list.append(extended_fundamental)

        self.list = extended_list.copy()

        return None

    @retry(requests.ConnectionError, tries=5, delay=1, backoff=2)
    def __get_realtime_info(self, code:str):
        return twstock.realtime.get(code)

if __name__ == '__main__':

    try:
        option = CommandLineOption().parse()
    except MissingOption as e:
        print('%s: %s: %s' % (__file__, 'error', e))
        sys.exit()

    try:
        code_list = ParseCodeList(path=option.file).code_list
    except FileNotFoundError as e:
        print('%s: %s: %s (%s)' % (__file__, 'error', e, e.__class__.__name__))
        sys.exit()
    except ParseError as e:
        print('%s: %s: %s (%s)' % (__file__, 'error', e, e.__class__.__name__))
        sys.exit()

    path  = os.path.dirname(os.path.abspath(__file__))
    path += '/' + '_'.join(['stock_fundamentals', 'market', option.market, datetime.datetime.now().strftime('%Y%m%d_%H%M%S')]) + '.log'

    stock_fundamentals = StockFundamental()

    for idx, code in enumerate(code_list):
        if not code['market'] == stock_fundamentals.Market['chinese'][stock_fundamentals.Market['english'].index(option.market)]:
            continue

        if not stock_fundamentals.fetch(code=code['code']):
            sys.exit()

        stock_fundamentals.insert_price()

        if idx == 0:
            with open(path, 'a') as f:
                f.write(' '.join(list(stock_fundamentals.list[0].keys())))
                f.write('\n')

        for fundamental in stock_fundamentals.list:
            with open(path, 'a') as f:
                f.write(' '.join(list(fundamental.values())))
                f.write('\n')

    print('finish fetch with no error')
