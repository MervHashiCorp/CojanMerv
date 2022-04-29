# Enable K/V v2 secrets engine at 'kv-v2'
resource "vault_mount" "kv-v2" {
  path = "kv-v2"
  type = "kv-v2"
}

# Enable Transit secrets engine at 'transit'
resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"
}

# Enable Database secrets engine at 'database'
resource "vault_mount" "database" {
  path = "database"
  type = "database"
}

# Creating an encryption key named 'payment'
resource "vault_transit_secret_backend_key" "key" {
  depends_on = [vault_mount.transit]
  backend    = "transit"
  name       = "payment"
  deletion_allowed = true
}


resource "vault_database_secret_backend_connection" "mssql" {
  backend       = vault_mount.database.path
  name          = "mssql"
  allowed_roles = ["mssql_dev"]

  sqlserver {
    connection_url = "sqlserver://{{username}}:{{password}}@{{hostname}}:1433"
  }
}

resource "vault_database_secret_backend_connection" "mysql" {
  backend       = vault_mount.database.path
  name          = "mysql"
  allowed_roles = ["mysql_dev"]

  mysql {
    connection_url = "{{username}}:{{password}}@tcp({{hostnamer}}:3306)/"
  }
}

resource "vault_database_secret_backend_role" "role" {
  backend             = vault_mount.database.path
  name                = "mssql_dev"
  db_name             = vault_database_secret_backend_connection.mysql.name
  creation_statements = ["CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}';CREATE USER [{{name}}] FOR LOGIN [{{name}}];GRANT SELECT ON SCHEMA::dbo TO [{{name}}];"]
}

resource "vault_database_secret_backend_role" "role" {
  backend             = vault_mount.database.path
  name                = "mysql_dev"
  db_name             = vault_database_secret_backend_connection.mysql.name
  creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"]
}

