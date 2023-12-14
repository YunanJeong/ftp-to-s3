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
all_files = util.get_ftp_all_filepaths(ftp, '/')
log_files = []
for file in all_files:
    if (target_dir in file) and ('.log' in file):
        log_files.append(file)

# FTP 세션 종료
ftp.quit()



print (log_files)


rule start:
    input: 
    output:
        '/home/ubuntu/private/ftp-to-s3/temp.done'
    script:
        """ls"""

rule end:
    input:
        '/home/ubuntu/private/ftp-to-s3/temp.done'

# rule all:
#     input:
        # 마지막 DONE

# rule download_file_by_file:
#     input:
#     output:
#     shell:
#         # 다운로드

# rule download_server_by_server:
#     input:
#     output:

# rule download:
#     input:
#     output:

# rule compress:
#     input:
#         expand(TMP_DIR + f'/{TARGET_DATE}/decomp/' + '{file}.done', file=log_files)
#     output:
        
#     script:
#         f"""
#         gzip {file}
#         """

# rule multi_compress:
#     input:
#     output:

# rule upload_to_s3:
#     input:
#     output: