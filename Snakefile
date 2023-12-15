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
from datetime import datetime, date, timedelta

# 대상날짜 디렉토리 확정
if TARGET_DATE == 'yesterday':
    yesterday = date.today() - timedelta(days=1)
    TARGET_DATE = yesterday.strftime("%Y%m%d")   # yyyymmdd string
    target_dir = yesterday.strftime("%Y-%m/%d")  # yyyy-mm/dd string
else:  # 특정날짜대상 작업시, config['target_date']에 yyyymmdd꼴 string을 입력 후 시작
    TARGET_DATE = TARGET_DATE  
    target_dir = datetime.strptime(TARGET_DATE, "%Y%m%d").strftime("%Y-%m/%d")  

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
    output:
        'donelog/' + f'allclear_{날짜}'
    shell:
        """
        # 작업 완료 후 임시 저장경로 삭제
        # rm -rf temp
        # rm -rf donelog/
        # touch {output}
        # aws s3 cp {output} {s3_home}/{output}
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

# 여기서부터 input, output을 DONELOG로 처리한다.
  # 네트워크 대역폭 부족 방지(모든파일 추출작업을 100% 완료 후, S3업로드 시작)
  # 스토리지 부족 방지 (업로드 직후 완료파일들은 로컬에서 즉시삭제 필요. input, output을 실제 데이터로 쓴다면, 파일삭제시 snakemake DAG에서 오류 가능성)

rule load:
    input:
        'donelog/' + 'multi_extract_transform.done'
    output:
        'donelog/' + 'load_{server}.done'
    params:
        local_dir = f'temp/{target_dir}'
        s3_path = f'{s3_home}/{server}/{target_dir}'
    shell:
        """
        aws s3 cp {params.local_dir} {params.s3_path} --recursive 
        rm -rf temp/{server}
        touch {output}
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

