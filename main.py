
# 원격 FTP 서버 검사
# /임의폴더이름/YYYY-MM/DD/ 을 만족하는 모든 filepath를 리스트로 만들기
import os
import boto3

from ftplib import FTP
from datetime import date, timedelta

# FTP 서버 접속 (TODO: 환경변수=>config 파일로 교체 하자. 여러 서버 처리)
FTP_SERVER = os.getenv('FTP_SERVER')
FTP_PORT = int(os.getenv('FTP_PORT'))
FTP_USER = os.getenv('FTP_USER')
FTP_PASS = os.getenv('FTP_PASS')
LOCAL_HOME = '/home/ubuntu/data'


def get_servers():
    # 접속
    ftp = FTP()
    ftp.connect(FTP_SERVER, FTP_PORT)
    ftp.login(FTP_USER, FTP_PASS)

    # 최상위 경로에서 서버 별로 디렉토리가 구분되어있음. 그 목록을 가져옴.
    ftp.cwd("/")
    servers = ftp.nlst()
    ftp.quit()
    return servers


def get_yesterday(format):
    yesterday = date.today() - timedelta(days=1)
    yesterday = yesterday.strftime(format)
    return yesterday


def download_from_ftp(target_dir):
    local_dir = f'{LOCAL_HOME}/{target_dir}'

    # 로컬 경로 생성
    os.system(f'mkdir -p {local_dir}')

    # 다운로드
    try:
        cmd = f'cd {local_dir} && ncftpget -R -u {FTP_USER} -p {FTP_PASS} ftp://{FTP_SERVER}:{FTP_PORT}/{target_dir}/* '  # NOQA
        os.system(cmd)
    except Exception:
        print('Download Exception')
        os.system(f'rm -rf {local_dir}')
        # alert


# def upload_to_s3(targetdate, tmp_path, upload_info):
#     """s3로 업로드.

#     Args:
#         targetdate (datetime): 작업대상날짜
#         tmp_path (str): 저장 경로 (config)
#         upload_info (dict): s3_bucket, s3_path, options (config)

#     """
#     # logger.debug(">>> Uploading files to AWS S3 ...")
#     s3_bucket, s3_path, options = upload_info.values()
#     date_dict = get_date_dict(targetdate)
#     s3_path = s3_path.format(**date_dict)  # 날짜 템플릿과 매치되는 부분에 삽입

#     # aws = get_awscli_path()
#     aws = 'aws' if 'yunantest' in s3_bucket else '/usr/local/bin/aws'

#     # s3로 csv파일 업로드
#     cmd = f'{aws} s3 cp {tmp_path}/ s3://{s3_bucket}/{s3_path} {options}' # NOQA
#     os.system(cmd)

#     # 로컬에 남은 파일 삭제
#     # logger.debug(">>> Removing temporary files in Local Drive...")
#     os.system(f'rm -rf {tmp_path}')


yesterday = get_yesterday("%Y-%m/%d")
servers = get_servers()
for server in servers:
    target_dir = f'{server}/{yesterday}'
    download_from_ftp(target_dir)


# TODO: sleep으로 하면 시간 밀릴 수 있음. 특정시간에 실행해야함. crontab 쓰던지 현재시간 기반으로 해야함.
# 매일 한번씩 실행
# while True:
#     sync_ftp_to_s3()
#     time.sleep(86400)  # 24시간 대기

