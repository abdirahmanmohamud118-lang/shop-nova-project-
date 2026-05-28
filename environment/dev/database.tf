
###########################################
# database
###########################################

module "master_db" {
  source               = "terraform-aws-modules/rds/aws"
  version              = "7.2.0"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.database_config.instance_class
  allocated_storage    = var.database_config.allocated_storage
  storage_encrypted    = true
  family               = "mysql8.0"
  major_engine_version = "8.0"
  identifier           = "${var.project_name}-${var.environment}-db"
  db_name              = var.database_config.db_name
  username             = var.database_config.db_username
  port                 = 3306

  multi_az               = var.database_config.multi_az
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  backup_retention_period = var.database_config.backup_retention_period
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"
  db_subnet_group_name    = module.vpc.database_subnet_group_name
  password_wo             = random_password.db_password.result
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

}

module "replica_db" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "7.2.0"
  identifier             = "${var.project_name}-${var.environment}-db-replica"
  replicate_source_db    = module.master_db.db_instance_identifier
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  skip_final_snapshot    = true
  major_engine_version   = var.database_config.major_engine_version
  family                 = var.database_config.family
  engine                 = var.database_config.engine_name
  instance_class         = var.database_config.instance_class
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}



###########################################
# database password and secrets
###########################################

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "${var.project_name}-rds-credentials"
  description = "RDS credentials fetched privately by EC2 via VPC Endpoint"

  tags = {
    Environment = var.environment
    project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "rds_secret_val" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username   = "db_admin"
    password   = random_password.db_password.result
    write_host = module.master_db.db_instance_address
    read_host  = module.replica_db.db_instance_address
    database   = "shopnova_db"
  })
}