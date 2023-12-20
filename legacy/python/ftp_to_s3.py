
import os
import sys
import yaml
from ftplib import FTP
from datetime import date, timedelta

DONE = 0


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


def get_yesterday(format):
    yesterday = date.today() - timedelta(days=1)
    yesterday = yesterday.strftime(format)
    return yesterday


def ftp_to_local(target_dir, local_dir, ftp):  # NOQA
    user = ftp['user']
    passwd = ftp['pass']
    server = ftp['server']
    port = ftp['port']

    # 로컬 경로 생성
    os.system(f'mkdir -p {local_dir}')

    # 다운로드
    cmd = f'cd {local_dir} && ncftpget -R -u {user} -p {passwd} ftp://{server}:{port}/{target_dir}/* '  # NOQA
    cmd = os.system(cmd)
    if cmd != DONE:
        # ftp서버 대상경로에 업로드 된 내용이 없거나, 다운로드 실패시 로컬경로 삭제
        os.system(f'rm -rf {local_dir}')


def local_to_s3(local_dir, s3_path):
    # s3로 업로드
    cmd = f'aws s3 cp {local_dir} {s3_path} --recursive' # NOQA
    cmd = os.system(cmd)
    if cmd is DONE:
        os.system(f'rm -rf {local_dir}')


def main(argv):
    config = get_config(argv)
    ftp = config['ftp']
    local_home = config['local_home']
    s3_home = config['s3_home']

    # 최상위경로(서버목록) 체크
    ftp_session = FTP()
    ftp_session.connect(ftp['server'], ftp['port'])
    ftp_session.login(ftp['user'], ftp['pass'])
    ftp_session.cwd("/")
    servers = ftp_session.nlst()
    ftp_session.quit()
    yesterday = get_yesterday("%Y-%m/%d")

    # 서버 별 전일자 다운로드
    for server in servers:
        target_dir = f'{server}/{yesterday}'
        local_dir = f'{local_home}/{target_dir}'
        s3_path = f'{s3_home}/{target_dir}'
        ftp_to_local(target_dir, local_dir, ftp)
        local_to_s3(local_dir, s3_path)


if __name__ == '__main__':
    # 설정 파일 절대경로 입력(or 환경변수로 처리)
    argv = sys.argv[1]
    main(argv)


# TODO: sleep으로 하면 시간 밀릴 수 있음. 특정시간에 실행해야함. crontab 쓰던지 현재시간 기반으로 해야함.
# 매일 한번씩 실행
# while True:
#     sync_ftp_to_s3()
#     time.sleep(86400)  # 24시간 대기
