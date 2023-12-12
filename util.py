import os
import sys
import yaml


# TODO: filepath를 arg로 지정해야겠다.
def get_config(filename):
    """설정 파일 가져오기.

    Args:
        filename (str): 설정 파일 명

    Returns:
        config (dict): 설정 파일 내 key-value를 딕셔너리 형태로 반환
    """
    # if filename is None:
    # config_home = f'{EDIT_HOME}/config'
    config_home = ''
    
    try:
        filename = filename + '.yml' if '.yml' not in filename else filename
        with open(f'{config_home}/{filename}') as file:
            config = yaml.load(file, Loader=yaml.FullLoader)
    except FileNotFoundError as e:
        configlist = os.listdir(f'{config_home}/')
        print(f'error: {e} does not exist.'
              + f'Please check files in config directory.\n {configlist}')
        sys.exit(1)
    return config
