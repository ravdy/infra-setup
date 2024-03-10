# Preliminary Steps

## Have your tools installed

* aws.identity from https://gitlab.com/edbence/Core/aws-role-management
* jq
* terraform
* ansible
* aws CLI v2


## Create the Hosted Zone

In Route53 for the AWS Account you are building out in.

    <ENV>.env.edbence.com

Contact XRoot to add your name servers from the Hosted Zone to edbence.com in the domains AWS acccount.


## Create Secrets
Setup replication if necessary.
The `<ENVIRONMENT>/infra/core` secret is all things that can be acquired by Terraform
without using Secrets Manager, but may be difficult for Ansible.

    <ENVIRONMENT>/infra/core
        aws_account_id: <ACCOUNT_ID>
        public_domain_name: <ENVIRONMENT>.env.edbence.com
        public_route53_zone_id: <HZ_ID>

Create a Datadog API key and APP key, named "aws-<ENVIRONMENT>".

* https://app.datadoghq.com/organization-settings/application-keys
* https://app.datadoghq.com/organization-settings/api-keys

The AWS Integration ID can be set up by the Terraform. You can add that after
running the terraform-env directory, and look it up in Datadog.

    <ENVIRONMENT>/infra/datadog
        app_key: <DD_APP_KEY>
        api_key: <DD_API_KEY>
        aws_integration_external_id: <DD_INTEGRATION_ID>

  <ENVIRONMENT>/roach/connection_info
        dbuser: <DB_USER>
        dbpassword:	<DB_PASSWORD>
        dbhost_port: <MOST_OF_HOST_URL>:<PORT>
        dbcluster: <SUB_DOMAIN_OF_HOST_URL>
        db_name: <DB_NAME>

Regarding the host URL: it will take the form of

    edbence-iam-prod-8380.7tt.cockroachlabs.cloud:26257

Which results in:

    dbhost_port: 7tt.cockroachlabs.cloud:26257
    dbcluster: edbence-iam-prod-8380


    <ENVIRONMENT>/roach/ssl_cert
        This is the CA for Cockroach; it is provided with the cluster, and is
        the same for all clusters.

And in the appropriate region for each segment:

    <ENVIRONMENT>/<SEGMENT>/core
        vpc_cidr_prefix: <CIDR1>  # 10.22 or similar
        vpn_cidr_prefix: <CIDR2>  # 10.56 or similar

CIDR prefixes can be found in the README: https://gitlab.com/edbence/Core/edbence-infrastructure

Create JFrog credentials in edbence.jfrog.io and add those to AWS secret manager
Add secret
    - `edbence-artifactory-docker-auth-file`
Generate ~/.docker/config.json on any Unix system by using docker credentials.
Content `~/.docker/config.json` looks like below 
   ```sh 
   {
        "auths": {
                "edbence.jfrog.io": {
                        "auth": "cmVxxxxxxxxxxxxxxxxxxjY1BeJUA=",
                        "email": "xroot+jfrog-reader-temp@edbence.com"
                }
        }
   }
   ```
   Create Secret manager as a plain text with above content.

## Update Ansible for the new Segment, if there is one

This file should exist:

`ansible/inventory/inventory-<ENVIRONMENT>-<SEGMENT>.yaml`

Add the following, updating the <WORD> elements:

    ---
    controllers:
      hosts:
        controller01:
          ansible_host: controller-<SEGMENT>.<ENVIRONMENT>-<SEGMENT>.internal

`ansible/init-for-terraform.yaml`

Add the segment to the list of segments.

## Setup for Terraform

    export ENVIRONMENT=xample-dev
    export SEGMENT=east; export AWS_REGION=us-east-1
    export ADMIN_ROLE=infrastructure
    aws.identity --profile main assume ${ENVIRONMENT} --role ${ADMIN_ROLE}

    ./run-playbook.sh ansible/init-for-terraform.yaml

## Set up SSH Keys for EC2 Access when SSM isn't usable

WARNING: This will regenerate the EC2 key pairs. Every time. It is not
idempotent, and machines that were built with the old EC2 key pairs will not be
updated. Basically, if you run this, you will probably need to rebuild the
bastion host!

This isn't the end of the world, but be aware before you lock people out.

    export ENVIRONMENT=xample-dev
    export SEGMENT=east; export AWS_REGION=us-east-1
    export ADMIN_ROLE=infrastructure
    aws.identity --profile main assume ${ENVIRONMENT} --role ${ADMIN_ROLE}

    ./run-playbook.sh ansible/rotate-ec2-ssh-keys.yaml


# Actual Terraform Process

## Terraform: Basic Environment

    export ENVIRONMENT=xample-dev
    export SEGMENT=east; export AWS_REGION=us-east-1
    export ADMIN_ROLE=infrastructure
    aws.identity --profile main assume ${ENVIRONMENT} --role ${ADMIN_ROLE}

    ./run-terraform.sh -L -e ${ENVIRONMENT} -s ${SEGMENT} -m env init|plan|apply

NOTE: The revised Terraform creates and manages ACM Certificate validation, so
if you have an _existing_ certificate, you may need to import the certificate
and the DNS records.


## Terraform: Segment

    export ENVIRONMENT=xample-dev
    export SEGMENT=east; export AWS_REGION=us-east-1
    export ADMIN_ROLE=infrastructure
    aws.identity --profile main assume ${ENVIRONMENT} --role ${ADMIN_ROLE}

    ./run-terraform.sh -L -e ${ENVIRONMENT} -s ${SEGMENT} -m ${SEGMENT}-base init|plan|apply
    ./run-terraform.sh -L -e ${ENVIRONMENT} -s ${SEGMENT} -m ${SEGMENT}-ext init|plan|apply

For west

    export SEGMENT=west; export AWS_REGION=us-west-2

    ./run-terraform.sh -L -e ${ENVIRONMENT} -s ${SEGMENT} -m ${SEGMENT}-base init|plan|apply
    ./run-terraform.sh -L -e ${ENVIRONMENT} -s ${SEGMENT} -m ${SEGMENT}-ext init|plan|apply


# Grant Yourself SSH Access to the EC2 Instances

We're going to configure your SSH to allow you (and therefore Ansible) to SSH to
the relevant hosts.

(Note: Without Ansible, this is not a requirement.)

First, move the SSH keys you generated above to this directory:

~/.ssh/edbence/

You only need the general private key there, so you can do this:

```bash
$ mkdir -p ~/.ssh/edbence
$ chmod 0700 ~/.ssh/edbence
$ cp \
  edbence-commons-infrastructure/.config/id_ssh_rsa_edbence-xample-dev \
  ~/.ssh/edbence/xample-dev
$ chmod 0600 ~/.ssh/edbence/xample-dev
```

And then edit your SSH config file (~/.ssh/config) to include:

```text
Host bastion-east.xample-dev.env.edbence.com bastion-west.xample-dev.env.edbence.com
    User ubuntu
    IdentityFile ~/.ssh/edbence/xample-dev
    ServerAliveInterval 60
    ServerAliveCountMax 10      

Host *.xample-dev-east.internal
    User ubuntu
    IdentityFile ~/.ssh/edbence/xample-dev
    ServerAliveInterval 60
    ServerAliveCountMax 10
    ProxyJump bastion-east.xample-dev.env.edbence.com

Host *.xample-dev-west.internal
    User ubuntu
    IdentityFile ~/.ssh/edbence/xample-dev
    ServerAliveInterval 60
    ServerAliveCountMax 10
    ProxyJump bastion-west.xample-dev.env.edbence.com
```

Now you should be able to do any of these SSH commands:

```bash
$ ssh bastion-east.xample-dev.env.edbence.com
$ ssh controller-east.xample-dev-east.internal
```

In the edbence/Core/edbence-infrastructure repository, you can now run the
ansible script to set up a controller (although this also makes it a GitLab
Runner, which we may not want long-term):

You will want to make sure you have a GitLab Access Token (read-only is fine)
and the GitLab Group's registration token for runners in your environment:

```bash
$ ./scripts/run-playbook.sh ansible/controls/setup-controller-v2.yaml \
  --skip-tags "ansible" \
  --extra-vars "gitlab_access_token=$GITLAB_ACCESS_TOKEN" \
  --extra-vars "gitlab_registration_token=$GITLAB_REGISTRATION_TOKEN"
```

Then you will need to ssh into the controller machines individually and perform
the following operation which does not work in the above ansible script:

```bash
ssh controller-east.xample-dev-east.internal

    sudo su
    apt-get install --assume-yes ansible-core
    sudo su gitlab-runner
    pip3 install -Iv 'resolvelib<0.6.0'
    ansible-galaxy collection install --force amazon.aws community.general community.aws

ssh controller-west.xample-dev-west.internal

    sudo su
    apt-get install --assume-yes ansible-core
    sudo su gitlab-runner
    pip3 install -Iv 'resolvelib<0.6.0'
    ansible-galaxy collection install --force amazon.aws community.general community.aws
```


# setup k8s config

    aws eks update-kubeconfig --name $ENVIRONMENT-$SEGMENT
