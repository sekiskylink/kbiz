-- user_roles
-- users
-- user_role_permissions
-- audit_log

-- carmake
    -- (id, name, descr)
        --(1, 'Toyota','japanese')

-- carmodel
    -- (id, name, descr, alias)
        -- (1, 'RAV4','', '')
        -- (2, 'Corona','', 'kibina')
        -- (3, 'Corolla AE100','', 'kikumi')

-- cars
    -- (id, carmake_id, carmodel_id,year)
        -- (1, 1, 1, 2000)
        --XXX consider adding image

-- sparecategory
    -- (id, name,descr)
        -- (1, 'headlights','')
        -- (2, 'rearlights','')
        -- (3, 'side mirror','')
-- sparepartmake
    -- (id, name, descr)
        --(1, 'Japan', 'parts made in Japan')
        --(2, 'Taiwan', 'parts made in Taiwan')

-- spareparts
    -- (id, cars_id, sparecategory_id, sparepartmake_id, part_num, side, is_used, quantity, price,descr)
        -- (1, 1, 2, '432KY', 'R', 't', 10, '')
        -- (1, 1, 2, '432KY', 'L', 't', 5, '')
        --XXX consider adding image
-- compartments
    -- (id, slug, descr)
        --(1, 'B1')
-- sparepart_location
    -- (id, sparepart_id, compartment_id)

-- sales stuff follows
    --(invoices, receipts, statements/ sales journal)

-- receipts
    -- (id, num, date, issued_by, descr)

-- receipt_items
    -- (id, receipt_id, sparepart_id, qty, unit_price)

-- invoices
    --(id, num, date, issued_by, vat, descr) -- add customer_id if we keep customers

-- invoice_items
    -- (id, invoice_id, sparepart_id, qty, unit_price)

-- sales_journal -- records each sale separately irrespective of invoice or receipt
    -- (id, sparepart_id, qty, unit_price, date, sold_by, vat, descr)

-- Track guys who take stuff before paying
-- kadeyi -- you can use dealers
    -- (id, name, phone)
-- tracking
    -- (id, kadeyi_id, sparepart_id, qty, date, descr, is_returned, is_paid) -- put security left in descr
-- add language
-- The SQL

CREATE TABLE user_roles (
    id SERIAL NOT NULL PRIMARY KEY,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_role TEXT NOT NULL UNIQUE,
    descr TEXT DEFAULT ''
);

CREATE TABLE user_role_permissions (
    id serial NOT NULL PRIMARY KEY,
    user_role BIGINT NOT NULL REFERENCES user_roles ON DELETE CASCADE ON UPDATE CASCADE,
    sys_module TEXT NOT NULL, -- the name of the module - defined above this level
    sys_perms VARCHAR(16) NOT NULL,
    unique(sys_module,user_role)
);

CREATE TABLE users (
    id serial NOT NULL PRIMARY KEY,
    cdate timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    firstname TEXT NOT NULL,
    lastname TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL, -- blowfish hash of password
    email TEXT,
    user_role  BIGINT NOT NULL REFERENCES user_roles ON DELETE RESTRICT ON UPDATE CASCADE,
    allowed_ips TEXT NOT NULL DEFAULT '127.0.0.1;::1', -- semi-colon separated list of allowed ip masks
    denied_ips TEXT NOT NULL DEFAULT '', -- semi-colon separated list of denied ip masks
    failed_attempts TEXT DEFAULT '0/'||to_char(NOW(),'yyyymmdd'),
    transaction_limit TEXT DEFAULT '0/'||to_char(NOW(),'yyyymmdd'),
    is_active BOOLEAN NOT NULL DEFAULT 't',
    is_system_user BOOLEAN NOT NULL DEFAULT 'f',
    last_passwd_update TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

);

CREATE TABLE audit_log (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actor_type TEXT NOT NULL,
    actor_id BIGINT,
    action text NOT NULL,
    remote_ip INET,
    detail TEXT NOT NULL
);

CREATE INDEX au_idx1 ON audit_log(cdate);
CREATE INDEX au_idx2 ON audit_log(actor_type);
CREATE INDEX au_idx3 ON audit_log(actor_id);
CREATE INDEX au_idx4 ON audit_log(action);

CREATE TABLE carmodel(
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    descr TEXT DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX carmodel_idx1 ON carmodel(name);

CREATE TABLE carmake(
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    alias TEXT DEFAULT '', -- can even be used to search .. kibina
    descr TEXT DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX carmake_idx1 ON carmake(name);
CREATE INDEX carmake_idx2 ON carmake(alias);

CREATE TABLE cars(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    carmake_id INTEGER NOT NULL REFERENCES carmake ON DELETE CASCADE ON UPDATE CASCADE,
    carmodel_id INTEGER NOT NULL REFERENCES carmodel ON DELETE CASCADE ON UPDATE CASCADE,
    year INTEGER NOT NULL,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(carmake_id, carmodel_id, year)
);

CREATE INDEX cars_idx1 ON cars(year);

CREATE TABLE sparecategory(
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    descr TEXT DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX sparecategory_idx1 ON sparecategory(name);

CREATE TABLE sparepartmake(
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    descr TEXT DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX sparepartmake_idx1 ON sparepartmake(name);

CREATE TABLE spareparts(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    car_id INTEGER NOT NULL REFERENCES cars ON DELETE CASCADE ON UPDATE CASCADE,
    sparecategory_id INTEGER NOT NULL REFERENCES sparecategory ON DELETE CASCADE ON UPDATE CASCADE,
    sparepartmake_id INTEGER NOT NULL REFERENCES sparepartmake ON DELETE CASCADE ON UPDATE CASCADE,
    part_num TEXT NOT NULL DEFAULT '',
    side CHAR(1) CHECK (side IN ('L','R')),
    is_used BOOLEAN DEFAULT 't',
    quantity NUMERIC NOT NULL DEFAULT 0,
    price NUMERIC NOT NULL DEFAULT 0,
    descr TEXT DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compartments(
    id SERIAL NOT NULL PRIMARY KEY,
    label TEXT NOT NULL DEFAULT '',
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

);

CREATE TABLE sparepart_location(
    id SERIAL NOT NULL PRIMARY KEY,
    sparepart_id INTEGER NOT NULL REFERENCES spareparts ON DELETE CASCADE ON UPDATE CASCADE,
    compartment_id INTEGER NOT NULL REFERENCES compartments ON DELETE CASCADE ON UPDATE CASCADE,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE receipts(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    num TEXT NOT NULL DEFAULT '',
    descr TEXT DEFAULT '',
    issued_by INTEGER REFERENCES users,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX receipts_idx1 ON receipts(num);

CREATE TABLE receipt_items(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    receipt_id INTEGER NOT NULL REFERENCES receipts,
    sparepart_id INTEGER NOT NULL REFERENCES spareparts,
    quantity NUMERIC NOT NULL DEFAULT 0,
    price NUMERIC NOT NULL DEFAULT 0
);
CREATE INDEX receipt_items_idx1 ON receipt_items(receipt_id);
CREATE INDEX receipt_items_idx2 ON receipt_items(sparepart_id);

CREATE TABLE invoices(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    num TEXT NOT NULL DEFAULT '',
    descr TEXT DEFAULT '',
    issued_by INTEGER REFERENCES users,
    cdate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX invoices_idx  ON invoices(num);

CREATE TABLE invoice_items(
    id BIGSERIAL NOT NULL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES invoices,
    sparepart_id INTEGER NOT NULL REFERENCES spareparts,
    quantity NUMERIC NOT NULL DEFAULT 0,
    price NUMERIC NOT NULL DEFAULT 0
);

CREATE INDEX invoices_items_idx1 ON invoice_items(invoice_id);
CREATE INDEX invoices_items_idx2 ON invoice_items(sparepart_id);
