CREATE DATABASE IF NOT EXISTS lenddesk_users
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE lenddesk;

CREATE TABLE organizations (
  id         CHAR(36)     NOT NULL DEFAULT (UUID()),
  name       VARCHAR(150) NOT NULL,
  slug       VARCHAR(80)  NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_organizations_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE roles (
  id              CHAR(36)    NOT NULL DEFAULT (UUID()),
  organization_id CHAR(36)    NOT NULL,
  name            VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_org_name (organization_id, name),
  CONSTRAINT fk_roles_organization
    FOREIGN KEY (organization_id) REFERENCES organizations (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE permissions (
  id          CHAR(36)     NOT NULL DEFAULT (UUID()),
  name        VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_name (name)
) ENGINE=InnoDB;

CREATE TABLE users (
  id              CHAR(36)     NOT NULL DEFAULT (UUID()),
  organization_id CHAR(36)     NOT NULL,
  role_id         CHAR(36)     NULL,
  first_name      VARCHAR(100) NOT NULL,
  last_name       VARCHAR(100) NOT NULL,
  email           VARCHAR(150) NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  failed_logins   INT          NOT NULL DEFAULT 0,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at      DATETIME     NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_org_email (organization_id, email),
  CONSTRAINT chk_users_failed_logins CHECK (failed_logins >= 0),
  CONSTRAINT fk_users_organization
    FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
  role_id       CHAR(36) NOT NULL,
  permission_id CHAR(36) NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role
    FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_permission
    FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_activity_logs (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  user_id     CHAR(36)     NOT NULL,
  action      VARCHAR(100) NOT NULL,
  status_code INT          NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_logs_user
    FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB;
