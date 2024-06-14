configfile: 'localtest.yaml'
SERVICE = config['service']
SERVER = config['ftp']['server'] 
PORT = config['ftp']['port']
USER = config['ftp']['user']
PASS = config['ftp']['pass']
S3_BUCKET = config['s3_bucket']
TARGET_DATE = str(config['target_date'])

import os
import sys
import util
from ftplib import FTP
from datetime import datetime, date, timedelta


# 대상날짜 디렉토리 확정
TARGET_DIR = ''
if TARGET_DATE == 'yesterday':
    TARGET_DATE = util.get_yesterday("%Y%m%d")   # yyyymmdd string
    TARGET_DIR = util.get_yesterday("%Y-%m/%d")  # yyyy-mm/dd string
else:  # 특정날짜대상 작업시, config['target_date']에 yyyymmdd꼴 string을 입력 후 시작
    TARGET_DIR = datetime.strptime(TARGET_DATE, "%Y%m%d").strftime("%Y-%m/%d")  

# Done Log 경로 확정
DONE_LOG_PATH = f'done_log/{SERVICE}/{TARGET_DATE}/'

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
    if (TARGET_DIR in file) and ('.log' in file):
        file = file[:-4]  # 확장자 .log를 문자열에서 제거
        target_filepaths.append(file)

# FTP 세션 종료
ftp.quit()


rule all:
    input:
        DONE_LOG_PATH + 'multi_process.done'
    output:
        DONE_LOG_PATH + 'daily.done'
    params:
        s3_bucket = S3_BUCKET
    shell:
        """
        rm -rf {input}
        touch {output}
        aws s3 cp {output} {params.s3_bucket}/{output}
        """

rule extract:
    output:
        'temp' + '{filepath}.log'  # *.gz가 포함되지 않도록해야 함
    params:
        user = USER, passwd = PASS, server = SERVER, port = PORT,
        target = '{filepath}.log'  # shell에 wildcard 사용시, {wildcards.filepath}로 쓰거나 OR 이와같이 params로 표현가능
    shell:
        """
        ncftpget -u {params.user} -p {params.passwd} ftp://{params.server}:{params.port}.{params.target}

        # 현재 경로에 다운로드된 파일을 output경로로 이동  # output에 포함된 경로는 snakemake가 자동생성
        filename=$(basename {params.target})
        mv $filename {output}
        """

rule transform:
    input:
        'temp' + '{filepath}.log'
    output:
        'temp' + '{filepath}.log.gz'
    shell:
        """
        gzip {input}
        """

rule load:
    input:
        'temp' + '{filepath}.log.gz'
    output:
        # S3.remote('temp' + '{filepath}.log.gz')
        DONE_LOG_PATH + '{filepath}.done'
    params:
        s3_path    = S3_BUCKET + '/raw' + '{filepath}.log.gz'
    shell:
        """
        aws s3 cp {input} {params.s3_path}
        rm -rf {input}
        touch {output} 
        """

rule multi_process:
    input:
        expand(DONE_LOG_PATH + '{filepath}.done', filepath=target_filepaths)
    output:
        DONE_LOG_PATH + 'multi_process.done'
    shell:
        """
        rm -rf {input}
        touch {output}
        """