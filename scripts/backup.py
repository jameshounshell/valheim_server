import datetime
import dateutil
import argparse
import click
import boto3
import json
import os
import shutil

# helpers
def jprint(data):
    print(json.dumps(data, indent=4, default=str))


@click.group("cli")
def cli():
    """Utility for backup/restore of Valheim world data to s3"""


@cli.command("backup")
def backup():
    print("backing up files")


@cli.command("restore")
def restore():
    print("restoring files")

def get_aws_account():
    response = boto3.client("sts").get_caller_identity()
    return response["Account"]


class S3:
    account = get_aws_account()
    default_bucket_name = f"{account}-valheim"

    def __init__(self, bucket=default_bucket_name, local_path="/home/steam/.config/unity3d/IronGate/Valheim/worlds", s3_prefix="latest"):
        self.client = boto3.client("s3")
        self.bucket = bucket
        self.local_path = local_path
        self.s3_prefix = s3_prefix


    def backup(self):
        """Backup Valheim world data"""
        timestamp = datetime.datetime.utcnow().isoformat()
        # make timestamped backup
        self.upload_recursive(s3_prefix=timestamp)

        # update latest to reflect all the progress by players
        self.upload_recursive(s3_prefix=self.s3_prefix)

    def restore(self):
        self.download_recursive()

    def list_path(self, path):
        response = self.client.list_objects_v2(Bucket=self.bucket, Prefix=path)
        self.assert_success(response)
        contents = response["Contents"]
        assert len(contents) != 0
        paths = [i["Key"] for i in contents]
        return paths

    def upload_recursive(self, s3_prefix):
        """Upload to s3 at a given prefix"""
        files = os.listdir(self.local_path)
        newline = "\n"
        print(
            f"Uploading files to s3://{self.bucket}/{s3_prefix}:\n{newline.join(files)}\n"
        )

        for file in files:
            self.client.upload_file(
                Filename=f"{self.local_path}/{file}",
                Bucket=self.bucket,
                Key=f"{s3_prefix}/{file}",
            )

    def download_recursive(self):
        paths = self.list_path(path=self.s3_prefix)
        newline = "\n"
        print(
            f"Downloading files from s3://{self.bucket}/{self.s3_prefix} to {os.path.abspath(self.local_path)}:\n{newline.join(paths)}\n"
        )
        for path in paths:
            file = path.split("/")[-1]
            self.client.download_file(
                Filename=f"{self.local_path}/{file}",
                Bucket=self.bucket,
                Key=f"{path}",
            )
        pass



    @staticmethod
    def assert_success(response):
        assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_s3():
    def teardown_folder(local_path):
        try:
            print(f"Delete {local_path}")
            first_dir = local_path.split("/")[0]
            shutil.rmtree(f"{os.getcwd()}/{first_dir}", ignore_errors=True)
            print("")
        except Exception as e:
            print(e)

    def teardown_bucket(bucket):
        try:
            print(f"Cleaning up {bucket}")
            for path in [c["Key"] for c in boto3.client("s3").list_objects_v2(Bucket=bucket, Prefix="")["Contents"]]:
                print(f"Delete s3://{bucket}/{path}")
                boto3.client("s3").delete_object(Bucket=bucket, Key=path)
            print(f"Delete {bucket}")
            boto3.client("s3").delete_bucket(Bucket=bucket)
            print("")
        except Exception as e:
            print(e)

    def setup_bucket(bucket):
        boto3.client("s3").create_bucket(Bucket=bucket)

    def setup_folder(local_path, with_files=True):
        os.makedirs(local_path, exist_ok=True)
        files = ["World.db", "World.fwl"]
        if with_files:
            for file in files:
                with open(f"{local_path}/{file}", "w") as f:
                    f.write("foo")

    # setup
    account_number = get_aws_account()
    bucket = f"{account_number}-valheim-test"  # MAKE SURE THAT THIS IS A BUCKET YOU DO NOT CARE ABOUT.
    local_path_upload = ".config1/unity3d/IronGate/Valheim/worlds"
    local_path_download = ".config2/unity3d/IronGate/Valheim/worlds"
    teardown_bucket(bucket)
    teardown_folder(local_path_upload)
    teardown_folder(local_path_download)
    setup_bucket(bucket)
    setup_folder(local_path_upload)
    setup_folder(local_path_download, with_files=False)


    # test upload
    s3 = S3(bucket=bucket, local_path=local_path_upload)
    s3.backup()
    assert len(s3.list_path("")) == 4
    s3.backup()
    assert len(s3.list_path("")) == 6

    # test download
    # download twice, second simulates overwriting existing files
    for with_files in [False, True]:
        s3 = S3(bucket=bucket, local_path=local_path_download)
        s3.restore()

    # teardown
    teardown_bucket(bucket)
    teardown_folder(local_path_upload)
    teardown_folder(local_path_download)


if __name__ == "__main__":
    cli()
