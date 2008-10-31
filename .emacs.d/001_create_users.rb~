class CreateUsers < ActiveRecord::Migration
  def self.up
    create= <<END_OF_STRING
      CREATE TABLE users (
        id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        login VARCHAR(80) NOT NULL,
        salted_password VARCHAR(40) NOT NULL,
        firstname VARCHAR(40),
        lastname VARCHAR(40),
        salt CHAR(40) NOT NULL,
        verified INT default 0,
        role VARCHAR(40) default NULL,
        security_token CHAR(40) default NULL,
        token_expiry DATETIME default NULL,
        created_at DATETIME default NULL,
        updated_at DATETIME default NULL,
        logged_in_at DATETIME default NULL,
        deleted INT default 0,
        delete_after DATETIME default NULL
      ) TYPE=InnoDB DEFAULT CHARSET=utf8;
END_OF_STRING
      execute create
  end
  def self.down
    drop_table :users
  end
end
