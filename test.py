import os
import sys
import yaml

import util

from ftplib import FTP
from datetime import datetime, date, timedelta

def get_config(filepath):
    """설정 파일 가져오기.

    Args:
        filepath (str): 설정 파일 절대 경로

    Returns:
        config (dict): 설정 파일 내 key-value를 딕셔너리 형태로 반환
    """
    try:
        with open(f'{filepath}') as file:
            config = yaml.load(file, Loader=yaml.FullLoader)
    except FileNotFoundError as e:
        print(f'error: {e} does not exist.')
        sys.exit(1)
    return config

# configfile: 'localtest.yaml'
config = get_config('/home/ubuntu/private/ftp-to-s3/localtest.yaml')
SERVER = config['ftp']['server'] 
PORT = config['ftp']['port']
USER = config['ftp']['user']
PASS = config['ftp']['pass']
LOCAL_HOME = config['local_home']
S3_HOME = config['s3_home']
TARGET_DATE = config['target_date']

TARGET_DATE = '2023-12/11'
# 대상날짜 디렉토리 확정
target_dir = util.get_yesterday("%Y-%m/%d") if TARGET_DATE == 'yesterday' else TARGET_DATE  # NOQA

# FTP 세션 연결
ftp = FTP()
ftp.connect(SERVER, PORT)
ftp.login(USER, PASS)
ftp.cwd("/")

# 최상위경로(서버목록) 체크
servers = ftp.nlst()

# 대상 파일경로 전체 목록
all_filepaths = util.get_ftp_all_filepaths(ftp, '/')
target_filepaths = []
for file in all_filepaths:
    if (target_dir in file) and ('.log' in file):
        target_filepaths.append(file)

# FTP 세션 종료
ftp.quit()


# print(all_filepaths)
# print(target_filepaths)

TARGET_DATE = 'yesterday'
# 대상날짜 디렉토리 확정
target_dir = ''
if TARGET_DATE == 'yesterday':
    TARGET_DATE = util.get_yesterday("%Y%m%d")   # yyyymmdd string
    target_dir = util.get_yesterday("%Y-%m/%d")  # yyyy-mm/dd string
else:  # 특정날짜대상 작업시, config['target_date']에 yyyymmdd꼴 string을 입력 후 시작
    TARGET_DATE = TARGET_DATE  
    target_dir = datetime.strptime(TARGET_DATE, "%Y%m%d").strftime("%Y-%m/%d")  
print(TARGET_DATE)
print(target_dir)
