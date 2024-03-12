# env-global

This module creates core infrastructure for an environment in AWS, 
then segments can be created in the environment 

# module requirements
As of 1.0.5 it will be required to pass 2 named providers to the module to run
 aws.target and aws.replication
 each is an aws zone. Example : us-west-2
 Target is the initial save region
 Replication is the replicated to region

 example of provider config for running terraform against this repo

 module "env-global" {
  source = "git@gitlab.com:Xpansiv/Core/tf-modules/env-global.git?ref=1.0.5"
 ...
   providers = {
    aws.target = aws.s3_bk_up_target
    aws.replication = aws.s3_bk_up_replication
   }
 ...

 Where the aws.s3_bk_up_target and replication providers are defined in your configs


# backup s3 rotation
DB backup files stored in "xpansiv-${var.environment}-${var.region}-backup/30days" will be removed after 30 days. 

# Backup Replication
backups are saved to "target" and replicated to "replication". 
names ending in - backup are the target
names ending in - replication are the auto replication target

# Retention period
1, 3, 7, 21, 30, 60 day retention based on similar names.
/1day
/3day
/7day 
etc

Example:
xpansiv-xportfolio-us-east-1-backup/30days/fulls/file.extension
Anything under /30days has the same retention even if it has /fulls/ after it. 

# adding additional life cycle rules
to do this you would just need to add to your bom the data resource associated to the right s3 bucket and create a new lifecycle policy and assosite it to that resource. 

