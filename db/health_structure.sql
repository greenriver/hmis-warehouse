SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cps (
    id integer NOT NULL,
    pid character varying,
    sl character varying,
    mmis_enrollment_name character varying,
    short_name character varying,
    pt_part_1 character varying,
    pt_part_2 character varying,
    address_1 character varying,
    city character varying,
    state character varying,
    zip character varying,
    key_contact_first_name character varying,
    key_contact_last_name character varying,
    key_contact_email character varying,
    key_contact_phone character varying,
    sender boolean DEFAULT false NOT NULL,
    receiver_name character varying,
    receiver_id character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    npi character varying,
    ein character varying,
    trace_id character varying(10),
    cp_name_official character varying,
    cp_assignment_plan character varying
);


--
-- Name: cps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cps_id_seq OWNED BY public.cps.id;


--
-- Name: import_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_configs (
    id bigint NOT NULL,
    name character varying,
    host character varying,
    path character varying,
    username character varying,
    encrypted_password character varying,
    encrypted_password_iv character varying,
    destination character varying,
    data_source_name character varying,
    protocol character varying,
    kind character varying,
    encryption_key_name character varying,
    encrypted_passphrase character varying,
    encrypted_passphrase_iv character varying,
    encrypted_secret_key character varying,
    encrypted_secret_key_iv character varying,
    type character varying,
    active boolean DEFAULT false
);


--
-- Name: import_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.import_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.import_configs_id_seq OWNED BY public.import_configs.id;


--
-- Name: mhx_external_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_external_ids (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    identifier character varying NOT NULL,
    invalidated_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mhx_external_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_external_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_external_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_external_ids_id_seq OWNED BY public.mhx_external_ids.id;


--
-- Name: mhx_medicaid_id_inquiries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_medicaid_id_inquiries (
    id bigint NOT NULL,
    service_date date NOT NULL,
    inquiry character varying,
    result character varying,
    isa_control_number integer NOT NULL,
    group_control_number integer NOT NULL,
    transaction_control_number integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mhx_medicaid_id_inquiries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_medicaid_id_inquiries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_medicaid_id_inquiries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_medicaid_id_inquiries_id_seq OWNED BY public.mhx_medicaid_id_inquiries.id;


--
-- Name: mhx_medicaid_id_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_medicaid_id_responses (
    id bigint NOT NULL,
    medicaid_id_inquiry_id bigint,
    response character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mhx_medicaid_id_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_medicaid_id_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_medicaid_id_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_medicaid_id_responses_id_seq OWNED BY public.mhx_medicaid_id_responses.id;


--
-- Name: mhx_response_external_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_response_external_ids (
    id bigint NOT NULL,
    response_id bigint,
    external_id_id bigint
);


--
-- Name: mhx_response_external_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_response_external_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_response_external_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_response_external_ids_id_seq OWNED BY public.mhx_response_external_ids.id;


--
-- Name: mhx_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_responses (
    id bigint NOT NULL,
    submission_id bigint,
    error_report character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mhx_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_responses_id_seq OWNED BY public.mhx_responses.id;


--
-- Name: mhx_submission_external_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_submission_external_ids (
    id bigint NOT NULL,
    submission_id bigint,
    external_id_id bigint
);


--
-- Name: mhx_submission_external_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_submission_external_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_submission_external_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_submission_external_ids_id_seq OWNED BY public.mhx_submission_external_ids.id;


--
-- Name: mhx_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mhx_submissions (
    id bigint NOT NULL,
    total_records integer,
    zip_file bytea,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "timestamp" character varying
);


--
-- Name: mhx_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mhx_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mhx_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mhx_submissions_id_seq OWNED BY public.mhx_submissions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: soap_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.soap_configs (
    id integer NOT NULL,
    name character varying,
    "user" character varying,
    encrypted_pass character varying,
    encrypted_pass_iv character varying,
    sender character varying,
    receiver character varying,
    test_url character varying,
    production_url character varying
);


--
-- Name: soap_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.soap_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: soap_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.soap_configs_id_seq OWNED BY public.soap_configs.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    user_id integer,
    session_id character varying,
    request_id character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: cps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cps ALTER COLUMN id SET DEFAULT nextval('public.cps_id_seq'::regclass);


--
-- Name: import_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_configs ALTER COLUMN id SET DEFAULT nextval('public.import_configs_id_seq'::regclass);


--
-- Name: mhx_external_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_external_ids ALTER COLUMN id SET DEFAULT nextval('public.mhx_external_ids_id_seq'::regclass);


--
-- Name: mhx_medicaid_id_inquiries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_medicaid_id_inquiries ALTER COLUMN id SET DEFAULT nextval('public.mhx_medicaid_id_inquiries_id_seq'::regclass);


--
-- Name: mhx_medicaid_id_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_medicaid_id_responses ALTER COLUMN id SET DEFAULT nextval('public.mhx_medicaid_id_responses_id_seq'::regclass);


--
-- Name: mhx_response_external_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_response_external_ids ALTER COLUMN id SET DEFAULT nextval('public.mhx_response_external_ids_id_seq'::regclass);


--
-- Name: mhx_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_responses ALTER COLUMN id SET DEFAULT nextval('public.mhx_responses_id_seq'::regclass);


--
-- Name: mhx_submission_external_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_submission_external_ids ALTER COLUMN id SET DEFAULT nextval('public.mhx_submission_external_ids_id_seq'::regclass);


--
-- Name: mhx_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_submissions ALTER COLUMN id SET DEFAULT nextval('public.mhx_submissions_id_seq'::regclass);


--
-- Name: soap_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soap_configs ALTER COLUMN id SET DEFAULT nextval('public.soap_configs_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: cps cps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cps
    ADD CONSTRAINT cps_pkey PRIMARY KEY (id);


--
-- Name: import_configs import_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_configs
    ADD CONSTRAINT import_configs_pkey PRIMARY KEY (id);


--
-- Name: mhx_external_ids mhx_external_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_external_ids
    ADD CONSTRAINT mhx_external_ids_pkey PRIMARY KEY (id);


--
-- Name: mhx_medicaid_id_inquiries mhx_medicaid_id_inquiries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_medicaid_id_inquiries
    ADD CONSTRAINT mhx_medicaid_id_inquiries_pkey PRIMARY KEY (id);


--
-- Name: mhx_medicaid_id_responses mhx_medicaid_id_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_medicaid_id_responses
    ADD CONSTRAINT mhx_medicaid_id_responses_pkey PRIMARY KEY (id);


--
-- Name: mhx_response_external_ids mhx_response_external_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_response_external_ids
    ADD CONSTRAINT mhx_response_external_ids_pkey PRIMARY KEY (id);


--
-- Name: mhx_responses mhx_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_responses
    ADD CONSTRAINT mhx_responses_pkey PRIMARY KEY (id);


--
-- Name: mhx_submission_external_ids mhx_submission_external_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_submission_external_ids
    ADD CONSTRAINT mhx_submission_external_ids_pkey PRIMARY KEY (id);


--
-- Name: mhx_submissions mhx_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mhx_submissions
    ADD CONSTRAINT mhx_submissions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: soap_configs soap_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soap_configs
    ADD CONSTRAINT soap_configs_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_mhx_external_ids_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_external_ids_on_client_id ON public.mhx_external_ids USING btree (client_id);


--
-- Name: index_mhx_external_ids_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_external_ids_on_identifier ON public.mhx_external_ids USING btree (identifier);


--
-- Name: index_mhx_medicaid_id_responses_on_medicaid_id_inquiry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_medicaid_id_responses_on_medicaid_id_inquiry_id ON public.mhx_medicaid_id_responses USING btree (medicaid_id_inquiry_id);


--
-- Name: index_mhx_response_external_ids_on_external_id_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_response_external_ids_on_external_id_id ON public.mhx_response_external_ids USING btree (external_id_id);


--
-- Name: index_mhx_response_external_ids_on_response_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_response_external_ids_on_response_id ON public.mhx_response_external_ids USING btree (response_id);


--
-- Name: index_mhx_responses_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_responses_on_submission_id ON public.mhx_responses USING btree (submission_id);


--
-- Name: index_mhx_submission_external_ids_on_external_id_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_submission_external_ids_on_external_id_id ON public.mhx_submission_external_ids USING btree (external_id_id);


--
-- Name: index_mhx_submission_external_ids_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mhx_submission_external_ids_on_submission_id ON public.mhx_submission_external_ids USING btree (submission_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260805160000'),
('20260803180723'),
('20260108154000'),
('20260107184500'),
('20240807185011'),
('20240807183449'),
('20240807182354'),
('20240726193601'),
('20240726191502'),
('20240710141900'),
('20240515205603'),
('20240402142808'),
('20240327144840'),
('20240318191704'),
('20240126184731'),
('20230816173812'),
('20230814153918'),
('20230807201621'),
('20230726171015'),
('20230712155403'),
('20230707132626'),
('20230706134746'),
('20230614194646'),
('20230614191047'),
('20230613201311'),
('20230613185511'),
('20230612200614'),
('20230612180417'),
('20230609153005'),
('20230609132021'),
('20230608152551'),
('20230607195153'),
('20230607183613'),
('20230606204254'),
('20230606204139'),
('20230601151608'),
('20230530192424'),
('20230526201807'),
('20230525153410'),
('20230516171223'),
('20230516171211'),
('20230512151350'),
('20230508135940'),
('20230504203640'),
('20230504194752'),
('20230504143929'),
('20230322172802'),
('20230322163322'),
('20230317185655'),
('20230123201023'),
('20221108190522'),
('20221006205522'),
('20221005201553'),
('20221005201423'),
('20221005145830'),
('20221005142152'),
('20220812184231'),
('20220721165009'),
('20220721163813'),
('20220623172328'),
('20220621181125'),
('20220616195501'),
('20220616173636'),
('20220428192510'),
('20220428191717'),
('20220428183105'),
('20220407204625'),
('20220317205450'),
('20220316184128'),
('20220315200521'),
('20220315200203'),
('20220315172910'),
('20220131200130'),
('20220112142649'),
('20211209205303'),
('20211130194653'),
('20211129192820'),
('20211123203704'),
('20211122200024'),
('20211115191038'),
('20211029203304'),
('20211029203229'),
('20211006204046'),
('20211006154441'),
('20211006153817'),
('20211006152946'),
('20211006152632'),
('20211005200728'),
('20210928134057'),
('20210806150431'),
('20210726193142'),
('20210607182656'),
('20210511143037'),
('20210510185734'),
('20210422161421'),
('20210419174757'),
('20210330181230'),
('20210330155241'),
('20210327131355'),
('20210326150547'),
('20210326143558'),
('20210325190312'),
('20210318212736'),
('20210309150436'),
('20210212151557'),
('20210204052544'),
('20210204042020'),
('20210203164826'),
('20210202194001'),
('20210128183759'),
('20210122155335'),
('20210121151237'),
('20210118145142'),
('20210114205149'),
('20210111195511'),
('20201223182315'),
('20201211162854'),
('20201210200633'),
('20201209193543'),
('20201208220623'),
('20201203212706'),
('20201203212643'),
('20201201224035'),
('20201201192211'),
('20201118181257'),
('20201106141253'),
('20201104191034'),
('20201104164745'),
('20201103202932'),
('20201022181343'),
('20201020155907'),
('20201020125617'),
('20201019193122'),
('20201015195157'),
('20201013203358'),
('20200930152001'),
('20200807203051'),
('20200807140152'),
('20200629205716'),
('20200618132804'),
('20200617134354'),
('20200617132415'),
('20200617131057'),
('20200616201412'),
('20200520192050'),
('20200512143130'),
('20200508135957'),
('20200430201554'),
('20200422143107'),
('20200422135848'),
('20200421141725'),
('20200417132126'),
('20200415205728'),
('20200404144432'),
('20200403203318'),
('20200403184005'),
('20200403180901'),
('20200403004129'),
('20200402165627'),
('20200402012546'),
('20200313143927'),
('20200224162701'),
('20200218160012'),
('20200217200518'),
('20200217200315'),
('20200205144804'),
('20200204175352'),
('20200203203607'),
('20200203185425'),
('20200127151840'),
('20200124194225'),
('20200113160822'),
('20200113153534'),
('20200110170125'),
('20200110164537'),
('20191230194535'),
('20191230193236'),
('20191212151341'),
('20191206194129'),
('20191119200007'),
('20191113130108'),
('20191112154844'),
('20191107165424'),
('20191107164902'),
('20191107163343'),
('20190905170546'),
('20190809152023'),
('20190730122842'),
('20190607144129'),
('20190529182702'),
('20190513173709'),
('20190509155939'),
('20190422201024'),
('20190419150901'),
('20190419122444'),
('20190418152152'),
('20190418144540'),
('20190417171605'),
('20190416182618'),
('20190416180547'),
('20190404153621'),
('20190402142851'),
('20190328192902'),
('20190206194409'),
('20190117150120'),
('20190114174045'),
('20181026155224'),
('20180907122443'),
('20180831190828'),
('20180828173902'),
('20180827181354'),
('20180827173717'),
('20180810153634'),
('20180809175415'),
('20180808190244'),
('20180808174627'),
('20180807182636'),
('20180807161932'),
('20180807130101'),
('20180803195603'),
('20180717174942'),
('20180716202012'),
('20180716151309'),
('20180716125419'),
('20180714180735'),
('20180714180117'),
('20180713183124'),
('20180713162722'),
('20180713142425'),
('20180711174711'),
('20180711170320'),
('20180710163416'),
('20180710000126'),
('20180709184426'),
('20180707134347'),
('20180703200409'),
('20180701013424'),
('20180630225902'),
('20180630171549'),
('20180629203110'),
('20180629181555'),
('20180628175013'),
('20180627182220'),
('20180621211650'),
('20180621204422'),
('20180619184604'),
('20180614213248'),
('20180614133715'),
('20180613134407'),
('20180612200528'),
('20180612181410'),
('20180612171146'),
('20180611204954'),
('20180611203248'),
('20180611145227'),
('20180611145132'),
('20180611144138'),
('20180607180418'),
('20180607151108'),
('20180607140425'),
('20180607134202'),
('20180601185402'),
('20180601154501'),
('20180601152640'),
('20180601124144'),
('20180601010922'),
('20180530202908'),
('20180528144412'),
('20180528140032'),
('20180528002944'),
('20180527173419'),
('20180527115601'),
('20180526183114'),
('20180525195857'),
('20180525155355'),
('20180524175356'),
('20180524145220'),
('20180524132457'),
('20180524124135'),
('20180524121555'),
('20180524021249'),
('20180523203004'),
('20180523125514'),
('20180523121947'),
('20180522233624'),
('20180522203840'),
('20180521133817'),
('20180521132959'),
('20180518185643'),
('20180518133256'),
('20180517171655'),
('20180517170436'),
('20180517151558'),
('20180517151557'),
('20180517150308'),
('20180516223016'),
('20180516192022'),
('20180516184628'),
('20180516151527'),
('20180516032040'),
('20180516020528'),
('20180515184556'),
('20180515174347'),
('20180509194250'),
('20180508205550'),
('20180415191849'),
('20180413220534'),
('20180413045706'),
('20180412214425'),
('20180412201311'),
('20180411184612'),
('20180405154902'),
('20180301200541'),
('20180220193729'),
('20171107000152'),
('20171106180121'),
('20171028010225'),
('20170901195912'),
('20170831233204'),
('20170713184156'),
('20170613150635'),
('20170606143003'),
('20170602013551'),
('20170601172245'),
('20170529203247'),
('20170529182835'),
('20170529174730'),
('20170523181235'),
('20170523175542'),
('20170517125108'),
('20170516195310'),
('20170516190400'),
('20170516185409'),
('20170512172333'),
('20170512172327'),
('20170512172320'),
('20170512172314'),
('20170512154839');

