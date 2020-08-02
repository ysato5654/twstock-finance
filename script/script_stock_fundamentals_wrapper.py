import os
import sys
import subprocess
import re
from re import sub
import requests
from retry import retry

import twstock

class ParseError(Exception):
    pass

class RubyScript():

    FILE_NAME = 'script_show_stock_fundamentals.rb'

    """
    raise   FileNotFoundError
    """
    def __init__(self, market:str, sector:str):
        self.output = []

        path = self.FILE_NAME

        if not os.path.exists(path):
            raise FileNotFoundError('no such file or directory - %s' % path)

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
    def fetch(self, market:str, sector:str) -> bool:
        print('execute ruby')

        try:
            script = RubyScript(market=market, sector=sector)
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
