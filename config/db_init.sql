CREATE TABLE component (
    hw_type text NOT NULL,
    device text NOT NULL,
    index text NOT NULL,
    last_updated bigint NOT NULL,
    description text DEFAULT ''::text,
    worker text NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE component_event (
    event_id integer NOT NULL,
    component_id integer NOT NULL,
    subtype text NOT NULL,
    "time" bigint NOT NULL,
    data jsonb NOT NULL,
    processed boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE component_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE component_event_id_seq OWNED BY component_event.event_id;

CREATE SEQUENCE component_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE component_id_seq OWNED BY component.component_id;

CREATE TABLE cpu (
    util integer NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE device (
    device text NOT NULL,
    ip inet NOT NULL,
    last_poll integer,
    next_poll integer DEFAULT 0,
    last_poll_duration smallint,
    last_poll_result smallint,
    last_poll_text text,
    currently_polling smallint DEFAULT 0,
    worker text,
    pps_out bigint DEFAULT 0,
    bps_out bigint DEFAULT 0,
    discards_out bigint DEFAULT 0,
    sys_descr text,
    vendor text,
    sw_descr text,
    sw_version text,
    hw_model text,
    uptime integer,
    yellow_alarm smallint,
    red_alarm smallint,
    errors_out bigint DEFAULT 0,
    poller_uuid text
);

CREATE TABLE device_event (
    id integer NOT NULL,
    device text NOT NULL,
    subtype text NOT NULL,
    "time" bigint NOT NULL,
    data jsonb NOT NULL
);

CREATE SEQUENCE device_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE device_event_id_seq OWNED BY device_event.id;

CREATE TABLE fan (
    status smallint NOT NULL,
    vendor_status smallint,
    status_text text NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE global_config (
    table_name text NOT NULL,
    setting text NOT NULL,
    value text NOT NULL,
    description text NOT NULL,
    type text NOT NULL,
    last_updated bigint NOT NULL
);

CREATE TABLE instance (
    hostname text NOT NULL,
    ip inet NOT NULL,
    last_updated bigint NOT NULL,
    core boolean NOT NULL,
    master boolean NOT NULL,
    poller boolean NOT NULL,
    config_hash text NOT NULL
);

CREATE TABLE interface (
    name text NOT NULL,
    hc_in_octets numeric NOT NULL,
    hc_out_octets numeric NOT NULL,
    hc_in_ucast_pkts numeric NOT NULL,
    hc_out_ucast_pkts numeric NOT NULL,
    speed bigint NOT NULL,
    mtu integer NOT NULL,
    admin_status integer NOT NULL,
    admin_status_time bigint NOT NULL,
    oper_status integer NOT NULL,
    oper_status_time bigint NOT NULL,
    in_discards numeric NOT NULL,
    in_errors numeric NOT NULL,
    out_discards numeric NOT NULL,
    out_errors numeric NOT NULL,
    bps_in bigint,
    bps_out bigint,
    discards_in bigint,
    errors_in bigint,
    discards_out bigint,
    errors_out bigint,
    pps_in bigint,
    pps_out bigint,
    bps_util_in real,
    bps_util_out real,
    type text NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE memory (
    used bigint,
    free bigint,
    total bigint,
    util real NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE meta (
    id integer DEFAULT 1 NOT NULL,
    db_version integer,
    CONSTRAINT meta_id_check CHECK ((id = 1))
);

CREATE TABLE psu (
    status smallint NOT NULL,
    vendor_status smallint,
    status_text text NOT NULL,
    component_id integer NOT NULL
);

CREATE TABLE temperature (
    temperature smallint NOT NULL,
    threshold smallint,
    status smallint NOT NULL,
    vendor_status smallint,
    status_text text NOT NULL,
    component_id integer NOT NULL
);

ALTER TABLE ONLY component ALTER COLUMN component_id SET DEFAULT nextval('component_id_seq'::regclass);

ALTER TABLE ONLY component_event ALTER COLUMN event_id SET DEFAULT nextval('component_event_id_seq'::regclass);

ALTER TABLE ONLY device_event ALTER COLUMN id SET DEFAULT nextval('device_event_id_seq'::regclass);

ALTER TABLE ONLY component_event
    ADD CONSTRAINT component_event_pkey PRIMARY KEY (event_id);

ALTER TABLE ONLY component
    ADD CONSTRAINT component_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY cpu
    ADD CONSTRAINT cpu_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY device_event
    ADD CONSTRAINT device_event_pkey PRIMARY KEY (id);

ALTER TABLE ONLY device
    ADD CONSTRAINT devices_pkey PRIMARY KEY (device);

ALTER TABLE ONLY fan
    ADD CONSTRAINT fan_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY global_config
    ADD CONSTRAINT global_config_pkey PRIMARY KEY (setting);

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (hostname);

ALTER TABLE ONLY interface
    ADD CONSTRAINT interface_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY memory
    ADD CONSTRAINT memory_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY meta
    ADD CONSTRAINT meta_pkey PRIMARY KEY (id);

ALTER TABLE ONLY psu
    ADD CONSTRAINT psu_pkey PRIMARY KEY (component_id);

ALTER TABLE ONLY temperature
    ADD CONSTRAINT temperature_pkey PRIMARY KEY (component_id);

CREATE UNIQUE INDEX component_hw_type_device_index_idx ON component USING btree (hw_type, device, index);

ALTER TABLE ONLY component
    ADD CONSTRAINT component_device_fkey FOREIGN KEY (device) REFERENCES device(device) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY component_event
    ADD CONSTRAINT component_event_component_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cpu
    ADD CONSTRAINT cpu_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY device_event
    ADD CONSTRAINT device_event_device_fkey FOREIGN KEY (device) REFERENCES device(device) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY fan
    ADD CONSTRAINT fan_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY interface
    ADD CONSTRAINT interface_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY memory
    ADD CONSTRAINT memory_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY psu
    ADD CONSTRAINT psu_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY temperature
    ADD CONSTRAINT temperature_id_fkey FOREIGN KEY (component_id) REFERENCES component(component_id) ON UPDATE CASCADE ON DELETE CASCADE;

INSERT INTO meta (db_version) VALUES (1)
