# ftp-to-s3

awscli가 boto3보다 빠르다. 용량이 클땐 awscli가 유리하다.
ncftpget은 recursive 다운로드가 되지만, ftplib은 직접 구현해야 한다.

## Requirement

```sh
# version 3.2.5
sudo apt ncftp

sudo apt awscli
```

pip install ...