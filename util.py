from ftplib import error_perm  # , FTP
from datetime import date, timedelta


def get_yesterday(format):
    yesterday = date.today() - timedelta(days=1)
    yesterday = yesterday.strftime(format)
    return yesterday


def get_ftp_directory_items(ftp, path):
    """FTP서버 특정경로의 항목이름을 반환

    Args:
        ftp: ftplib.FTP 세션
        path (str): 경로

    Returns:
        dir_items (list): 디렉토리 및 파일 목록
    """
    dir_items = []
    try:
        dir_items = ftp.nlst(path)
    except error_perm as res:
        if "550" in str(res):
            # 해당 경로가 없으면 그냥 넘어감 (550에러)
            print("No files in this directory")
        else:
            # 다른 에러면 그대로 에러 뱉고 중지
            raise
    return dir_items


def get_ftp_all_filepaths(ftp, path):
    """FTP 서버의 특정 경로 아래의 모든 파일목록 반환 (서브디렉토리 아래의 모든 파일 포함)

    Args:
        ftp: ftplib.FTP 세션
        path (str): 경로

    Returns:
        dirs (list): 모든 파일 목록
    """
    filepaths = []

    # 현재 디렉토리의 파일과 서브디렉토리를 가져옴
    items = ftp.nlst(path)

    for item in items:
        # 파일이면 file_paths에 추가
        if not is_directory(ftp, item):
            filepaths.append(item)
        # 서브디렉토리면 재귀적으로 탐색
        else:
            filepaths += get_ftp_all_filepaths(ftp, item)

    return filepaths


def is_directory(ftp, name):
    """디렉토리인지 판단"""
    try:
        ftp.cwd(name)  # 디렉토리로 이동 시도
        ftp.cwd('..')  # 성공하면 원래 위치로 돌아감
        return True
    except Exception:
        return False
