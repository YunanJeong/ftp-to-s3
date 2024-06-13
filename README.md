# ftp-to-s3

- ftp 서버에서 어제 날짜에 해당하는 파일들을 가져와 S3로 업로드하는 워크플로우

## Requirement

```sh
sudo apt install snakemake
# version 3.2.5
sudo apt install ncftp

sudo apt install awscli
```

## 실행

- j는 멀티코어 사용
- F는 재실행시 처음부터 빌드. DAG input,output 데이터가 남아있어도 처음부터 실행. 오류로 재작업시 중단된 부분부터 처리해야하므로 F옵션은 빼야 함. 

```sh
# 가장 자주 쓰는 실행 커맨드
snakemake -j -F

# --configfile => 별도 confie 파일 지정시 사용 (file 단위가 아니라 yaml key 단위로 오버라이딩 하는 것임)
snakemake -j -F --configfile=localtest.yaml
```

## 스케쥴링

- 서버 시간 주의
- `sudo crontab` 사용시, `sudo aws configure` 처럼 sudo 권한으로 필요한 프로파일 사전설정
- snakemake는 Snakefile이 있는 절대 경로로 이동 후 실행해야 함

```sh
# 조회
crontab -l

# 등록
crontab -e

# 매일 서버 시간 기준 새벽 01:00에 수행 예 (Snakefile 경로로 이동 후 실행)
0 1 * * *  cd /home/ubuntu/private/ftp-to-s3/ && snakemake -j -F
```

## 메모

- awscli가 파이썬 boto3보다 빨라서 사용
- ncftpget가 파이썬 fiplib보다 기능이 유연해서 간단히 사용하기 편함
- alert, logging 등이 추가로 있으면 괜찮을 듯
