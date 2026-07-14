ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_role;

ALTER TABLE users
    ADD CONSTRAINT chk_users_role CHECK (role IN ('CUSTOMER', 'MERCHANT', 'AGENT', 'ADMIN'));

CREATE TABLE agents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    business_name VARCHAR(120) NOT NULL,
    agent_number VARCHAR(32) NOT NULL,
    location VARCHAR(160),
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_agents_user_id UNIQUE (user_id),
    CONSTRAINT uk_agents_agent_number UNIQUE (agent_number),
    CONSTRAINT fk_agents_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_agents_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED'))
);

CREATE INDEX idx_agents_status ON agents (status);
