configfile: 'localtest.yaml'
SERVER = config['ftp']['server'] 
PORT = config['ftp']['port']
USER = config['ftp']['user']
PASS = config['ftp']['pass']
LOCAL_HOME = config['local_home']
S3_HOME = config['s3_home']
TARGET_DATE = config['target_date']

import os
import sys
import util
from ftplib import FTP

# 대상날짜 디렉토리 확정
target_dir = util.get_yesterday("%Y-%m/%d") if TARGET_DATE == 'yesterday' else TARGET_DATE

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



rule all:
    input:
        'donelog/' + 'multi_load.done'
    shell:
        """
        # 작업 완료 후 임시 저장경로 삭제
        # rm -rf temp
        # rm -rf donelog/
        """

rule extract:
    output:
        'temp' + '{filepath}'
    params:
        user = USER
        passwd = PASS
        server = SERVER
        port = PORT
    shell:
        """
        ncftpget -u {params.user} -p {params.passwd} ftp://{params.server}:{params.port}.{filepath}

        # 현재 경로에 다운로드된 파일을 output경로로 이동  # output에 포함된 경로는 snakemake가 자동생성
        filename=$(basename {filepath})
        mv $filename {output}
        """
rule transform:
    input:
        'temp' + '{filepath}'
    output:
        'temp' + '{filepath}.gz'
    script:
        """
        gzip {input}
        """
rule multi_extract_transform:
    input:
        expand('temp' + '{filepath}.gz', file=target_filepaths)
    output:
        'donelog/' + 'multi_extract_transform.done'
    shell:
        """
        touch {output}
        """

rule load:
    input:
        'donelog/' + 'multi_extract_transform.done'
    output:
        'donelog/' + 'load_{server}.done'
    shell:
        """
        # aws s3 cp {} {} 
        """
rule multi_load:
    input:
        expand('donelog/' + 'load_{server}.done', server=servers)
    output:
        'donelog/' + 'multi_load.done'
    shell:
        """
        touch {output}
        """

