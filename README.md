# ftp-to-s3

- ftp 서버에서 어제날짜에 해당하는 파일들을 가져와 S3로 업로드하는 스크립트

## Requirement

```sh
sudo apt install snakemake
# version 3.2.5
sudo apt install ncftp

sudo apt install awscli
```

## 실행

```sh
# 가장 자주 쓰는 실행 커맨드
# -j는 멀티코어 사용
# -F는 재실행시 처음부터 빌드. DAG input,output 데이터가 남아있어도 처음부터 실행
# --configfile={my-annother-config.yaml} => cli에서 오버라이딩하여 다른 configfile 선택가능
snakemake -j -F --configfile=localtest.yaml
```

## 스케쥴링

```sh
# 조회
sudo crontab -l

# 등록
sudo crontab -e

# 매일 서버 시간 기준 새벽 01:00에 수행 예 (Snakefile 경로로 이동 후 실행)
0 1 * * *  cd /home/ubuntu/private/ftp-to-s3/ && snakemake -j -F
```

## 메모

- awscli가 boto3보다 빨라서 사용
- ncftpget에 recursive 다운로드 기능이 있어서 사용함
  - 파이썬 모듈 ftplib에선 직접 구현 필요
  - snakemake에선 개별 다운로드로 멀티프로세싱하기 위해 recursive 기능안씀
- alert,- logging 등이 추가로 있으면 괜찮을 듯
