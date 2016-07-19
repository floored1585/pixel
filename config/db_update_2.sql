UPDATE meta SET db_version=2;

ALTER TABLE device ADD COLUMN enable_polling BOOLEAN DEFAULT TRUE;
