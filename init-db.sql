-- Kuapa - Initialize all service databases
CREATE DATABASE kuapa_auth;
CREATE DATABASE kuapa_users;
CREATE DATABASE kuapa_products;
CREATE DATABASE kuapa_orders;
CREATE DATABASE kuapa_logistics;
CREATE DATABASE kuapa_notifications;
CREATE DATABASE kuapa_chat;
CREATE DATABASE kuapa_reviews;
CREATE DATABASE kuapa_payments;

-- Grant privileges to kuapa user
GRANT ALL PRIVILEGES ON DATABASE kuapa_auth TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_users TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_products TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_orders TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_logistics TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_notifications TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_chat TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_reviews TO kuapa;
GRANT ALL PRIVILEGES ON DATABASE kuapa_payments TO kuapa;
