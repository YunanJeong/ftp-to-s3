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
# 가장 자주 쓰는 실행 커맨드 (-j는 멀티코어 사용, -F는 재실행시 처음부터 빌드)
snakemake -j -F
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
- snakemake or airflow로 파일별 DAG처리
- alert
- logging 등이 추가로 있으면 괜찮을 듯
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
# 가장 자주 쓰는 실행 커맨드 (-j는 멀티코어 사용, -F는 재실행시 처음부터 빌드)
snakemake -j -F
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
- snakemake or airflow로 파일별 DAG처리
- alert
- logging 등이 추가로 있으면 괜찮을 듯
