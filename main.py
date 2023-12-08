import os
import boto3
from ftplib import FTP

# FTP 서버 접속
ftp = FTP('ftp_server.com')        # env
ftp.login('username', 'password')  # env

# S3 클라이언트 생성
s3 = boto3.client('s3', aws_access_key_id='access_key', aws_secret_access_key='secret_key')  # env


# 원격 FTP 서버 검사
# /임의폴더이름/YYYY-MM/DD/ 을 만족하는 모든 filepath를 리스트로 만들기

def upload_to_s3(file):
    # S3 버킷에 파일 업로드
    with open(file, 'rb') as data:
        s3.upload_fileobj(data, 'bucket_name', file)  # env


def download_from_ftp(path):
    # FTP 서버에서 파일 다운로드
    filename = os.path.basename(path)  # filepath 문자열에서 파일이름만 추출
    with open(filename, 'wb') as f:
        ftp.retrbinary('RETR ' + path, f.write)
    return filename


def sync_ftp_to_s3():
    # FTP 서버의 모든 파일을 S3로 복사
    files = ftp.nlst()   # nlst(): 특정 디렉토리에 있는 요소들의 이름을 리스트로 반환
    for file in files:
        local_file = download_from_ftp(file)
        upload_to_s3(local_file)
        os.remove(local_file)  # 로컬에 저장된 파일 삭제


# 매일 한번씩 실행
while True:
    sync_ftp_to_s3()
    time.sleep(86400)  # 24시간 대기