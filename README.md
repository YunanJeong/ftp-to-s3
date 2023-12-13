# ftp-to-s3

- ftp 서버에서 어제날짜에 해당하는 파일들을 가져와 S3로 업로드하는 스크립트

## Requirement

```sh
# version 3.2.5
sudo apt ncftp

sudo apt awscli
```

## 메모

- awscli가 boto3보다 빨라서 사용
- ncftpget에 recursive 다운로드 기능이 있어서 사용함
  - 파이썬 모듈 ftplib에선 직접 구현 필요
- snakemake or airflow로 파일별 DAG처리
- alert
- logging 등이 추가로 있으면 괜찮을 듯
