#!/bin/sh

# MYSQL SETUP 
#
# ###########


create_data_dir() {
  echo "Creating /var/lib/mysql"
  mkdir -p /var/lib/mysql
  chmod -R 0700 /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
}

create_run_dir() {
  echo "Creating /run/mysqld"
  mkdir -p /run/mysqld
  chmod -R 0755 /run/mysqld
  chown -R mysql:root /run/mysqld
}

create_log_dir() {
  echo "Creating /var/log/mysql"
  mkdir -p /var/log/mysql
  chmod -R 0755 /var/log/mysql
  chown -R mysql:mysql /var/log/mysql
}

mysql_default_install() {
  if [ ! -d "/var/lib/mysql/mysql" ]; then
      echo "Creating the default database"
      /usr/bin/mysql_install_db --datadir=/var/lib/mysql

  else
      echo "MySQL database already initialiazed"
  fi
}

create_database() {

  if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then

     # start mysql server.
      echo "Starting Mysql server"
      /usr/bin/mysqld_safe >/dev/null 2>&1 &

     # wait for mysql server to start (max 30 seconds).
      timeout=30
      echo -n "Waiting for database server to accept connections"
      while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
      do
        timeout=$(($timeout - 1))
        if [ $timeout -eq 0 ]; then
          echo -e "\nCould not connect to database server. Aborting..."
          exit 1
        fi
        echo -n "."
        sleep 1
      done
      echo
      
      # create database and assign user permissions.
      if [ -n "${DB_NAME}" -a -n "${DB_USER}" -a -n "${DB_PASS}" ]; then
         echo "Creating database \"${DB_NAME}\" and granting access to \"${DB_USER}\" database."
          mysql -uroot  -e  "CREATE DATABASE ${DB_NAME};"
          mysql -uroot  -e  "GRANT USAGE ON *.* TO ${DB_USER}@localhost IDENTIFIED BY '${DB_PASS}';"
          mysql -uroot  -e  "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO ${DB_USER}@localhost;"

      else
        echo "How have not provided all the required ENV variabvles to configure the database"

      fi
  else 
      echo "Database \"${DB_NAME}\" already exists"

  fi
  
}

set_mysql_root_pw() {
    # Check if root password has already been set.
    r=`/usr/bin/mysqladmin -uroot  status`
    if [ ! $? -ne 0 ] ; then
      echo "Setting Mysql root password"
      /usr/bin/mysqladmin -u root password "${ROOT_PWD}"

      # shutdown mysql reeady for supervisor to start mysql.
      timeout=10
      echo "Shutting down Mysql ready for supervisor"
      /usr/bin/mysqladmin -u root --password=${ROOT_PWD} shutdown
      
      else 
       echo "Mysql root password already set"
    fi
    
}


# WWW & LOGS 
#
# ################

create_www_dir() {
  # Create LOG directoties for NGINX & PHP-FPM
  echo "Creating www directories"
  mkdir -p /DATA/www
  mkdir -p /DATA/logs

}

apply_www_permissions(){
  echo "Applying www permissions"
  chown -R nginx:nginx /DATA/www /DATA/logs
  chown -R nginx:nginx /var/lib/nginx/logs/

}



# Vanilla INSTALL  
#
# ################
vanilla_install(){
wget https://us.v-cdn.net/5018160/uploads/addons/61ASGDJWTXJC.zip && unzip 61ASGDJWTXJC.zip  -d /DATA/www && rm 61ASGDJWTXJC.zip
cd vanilla* && mv * .. && cd.. && rm -rf vanilla*
chown nginx:nginx -R *
}


# Running all our scripts
create_data_dir
create_run_dir
create_log_dir
mysql_default_install
create_database
set_mysql_root_pw
create_www_dir
apply_www_permissions
vanilla_install




# Start Supervisor 
echo "Starting Supervisor"
/usr/bin/supervisord -n -c /etc/supervisord.conf
