#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 13 11:13:10 2023
"""

import argparse
from collections import namedtuple
import csv

import boto3


def main():
    args = arguments()
    sec_names, key_val_pairs = read_data("/users/edbence/downloads/secrets.csv", args.environment)
    for name, pair in zip(sec_names, key_val_pairs):
        if pair[0]['Key']!='':
            create_all_secrets_key_val(name, pair)
        else:
            create_all_secrets_val(name, pair)


def arguments():
    """
    Gets command-line arguments for use with the script.
    """
    parser = argparse.ArgumentParser(
        description="secret management"
        )
    parser.add_argument(
        "environment",
        help="Name of the environement"
        )
    return parser.parse_args()


def create_all_secrets_key_val(sec_name, sec_pair ):
    """
    Function to create secrets having both keys and values
    """
    client = boto3.client('secretsmanager')
    response = client.create_secret(
        Name = sec_name,
        Tags = sec_pair,
        AddReplicaRegions=[{ 'Region': 'us-west-2' }]
    )


def create_all_secrets_val(sec_name, sec_pair ):
    """
    Function to create secrets having only values
    """
    client = boto3.client('secretsmanager')
    response = client.create_secret(
        Name = sec_name,
        SecretString = sec_pair[0]['Value'],
        AddReplicaRegions=[{ 'Region': 'us-west-2' }]
    )


def read_data(file_path, env):
    """
    file has been read in nested dict
    """
    secrets = {}  # creating a placeholder for nested dict
    with open(file_path , 'r',  encoding='utf-8-sig') as data_file:
        data = csv.DictReader(data_file, delimiter=",")
        for row in data:
            name = row["Name"]
            key = row["Key"]
            value = row["Value"]
            secrets[name] = secrets.get(name, dict())
            secrets[name][key] = value


    #2 new lists are created.
    #One will store secret names and other will key-value pairs belonging to that secret.
    account_id = get_account()
    zone = get_domain_name(env)
    key_val_pairs = []
    sec_names = []
    for name in secrets:
        sec_names.append(f"{env}/{name}")
        secrets_list = []
        #parsing dict to generate key-value pair
        for key in secrets[name]:
            secret_record = {}
            secret_record['Key'] = key
            if key == 'aws_account_id':
                secret_record['Value'] = account_id
            elif key == 'public_domain_name':
                secret_record['Value'] = f"{env}.env.edbence.com"
            elif key == 'public_route53_zone_id':
                secret_record['Value'] = zone.id
            else:
                secret_record['Value'] = secrets[name][key]

            secrets_list.append(secret_record)

        key_val_pairs.append(secrets_list)

    return sec_names, key_val_pairs


def get_account():
    sts = boto3.client("sts")
    identity = sts.get_caller_identity()
    account_id  = identity['Account']
    return account_id


def get_domain_name(env):
    domain = f"{env}.env.edbence.com"
    client = boto3.client("route53")
    response = client.list_hosted_zones()["HostedZones"]

    HostedZone = namedtuple("HostedZone", "name id")
    for record in response:
        zone = HostedZone(
            record["Name"][:-1],
            record["Id"].rsplit("/", 1)[1],
            )
        if zone.name == domain:
            return zone


if __name__ == "__main__":
    main()