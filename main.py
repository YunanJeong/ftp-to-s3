
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


yesterday = get_yesterday("%Y-%m/%d")
servers = get_servers()
for server in servers:
    target_dir = f'{server}/{yesterday}'
    download_from_ftp(target_dir)


# # S3 클라이언트 생성
# s3 = boto3.client('s3', aws_access_key_id='access_key', aws_secret_access_key='secret_key')  # env
# def upload_to_s3(file):
#     # S3 버킷에 파일 업로드
#     with open(file, 'rb') as data:
#         s3.upload_fileobj(data, 'bucket_name', file)  # env



# def sync_ftp_to_s3():
#     # FTP 서버의 모든 파일을 S3로 복사
#     files = ftp.nlst()   # nlst(): 특정 디렉토리에 있는 요소들의 이름을 리스트로 반환
#     for file in files:
#         local_file = download_from_ftp(file)
#         upload_to_s3(local_file)
#         os.remove(local_file)  # 로컬에 저장된 파일 삭제

# 매일 한번씩 실행
# while True:
#     sync_ftp_to_s3()
#     time.sleep(86400)  # 24시간 대기
