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

# boto3 Required  # S3 모듈을 쓰면, input, output에서 done_log를 찍을 때 코드가 간결해짐
# from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
# S3 = S3RemoteProvider(keep_local=True)

# 대상날짜 디렉토리 확정
TARGET_DIR = ''
if TARGET_DATE == 'yesterday':
    TARGET_DATE = util.get_yesterday("%Y%m%d")   # yyyymmdd string
    TARGET_DIR = util.get_yesterday("%Y-%m/%d")  # yyyy-mm/dd string
else:  # 특정날짜대상 작업시, config['target_date']에 yyyymmdd꼴 string을 입력 후 시작
    TARGET_DIR = datetime.strptime(TARGET_DATE, "%Y%m%d").strftime("%Y-%m/%d")  

# Done Log 경로 확정  # S3.Remote 사용시 S3 버킷 명도 주소에 포함 필요
DONE_LOG_PATH = f'done_log/{SERVICE}/{TARGET_DATE}/'

target_filepaths = []
try:
    # FTP 세션 연결
    ftp = FTP()
    ftp.connect(SERVER, PORT)
    ftp.login(USER, PASS)
    ftp.cwd("/")

    # 최상위경로(서버목록) 체크
    servers = ftp.nlst()

    # 대상 파일경로 전체 목록
    all_filepaths = util.get_ftp_all_filepaths(ftp, '/')
    for file in all_filepaths:
        if (TARGET_DIR in file) and ('.log' in file):
            file = file[:-4]  # 확장자 .log를 문자열에서 제거
            target_filepaths.append(file)

except Exception as e:
    print(e)
    # 실패시에만 로그를 S3에 업로드하도록 설정
    shell( f"cp $(ls -t .snakemake/log/*.snakemake.log | head -n 1) {DONE_LOG_PATH}{TARGET_DATE}.log" )
    shell( f"echo {e} >> {DONE_LOG_PATH}{TARGET_DATE}.log"  )  # 마지막 로그에 에러메시지 추가
    shell( f"aws s3 cp {DONE_LOG_PATH}{TARGET_DATE}.log {S3_BUCKET}/{DONE_LOG_PATH}{TARGET_DATE}.log" )
    
    sys.exit(1)

finally:
    # FTP 세션 종료
    ftp.quit()

onsuccess:
    print('snakemake success')
    shell( f"aws s3 cp  {DONE_LOG_PATH}daily.done   {S3_BUCKET}/{DONE_LOG_PATH}{TARGET_DATE}.success" )

onerror:
    print("snakemake failed")
    # 실패시에만 로그를 S3에 업로드하도록 설정
    # '.snakemake/log' 경로에 전체 로그가 자동저장되고 있으며 최신 로그파일을 추출하여 S3로 업로드
    shell( f"aws s3 cp $(ls -t .snakemake/log/*.snakemake.log | head -n 1) {S3_BUCKET}/{DONE_LOG_PATH}" )

rule all:
    input:
        DONE_LOG_PATH + 'multi_process.done'  # S3.remote(DONE_LOG_PATH + 'multi_process.done')
    output:
        DONE_LOG_PATH + 'daily.done'          # S3.remote(DONE_LOG_PATH + 'daily.done')
    params:
        s3_bucket = S3_BUCKET
    shell:
        """
        rm -rf {input}
        touch {output}
        # aws s3 cp {output} {params.s3_bucket}/{output}
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
        DONE_LOG_PATH + '{filepath}.done'  # S3.remote('temp' + '{filepath}.log.gz')
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
        expand(DONE_LOG_PATH + '{filepath}.done', filepath=target_filepaths)  # S3.remote(expand(DONE_LOG_PATH + '{filepath}.done', filepath=target_filepaths))
    output:
        DONE_LOG_PATH + 'multi_process.done'                                  # S3.remote(DONE_LOG_PATH + 'multi_process.done')
    shell:
        """
        # 개별 파일 별 donelog가 너무 많으므로, 전체 작업 성공후 삭제 해준다.
        # 재작업이 잦다면 개별 파일 별 donelog도 보존해주는 것이 좋다.
        rm -rf {input}
        touch {output}
        """