CREATE SCHEMA "igor";




CREATE TABLE  IF NOT EXISTS igor.measurment_params (
    id integer NOT NULL,,
    measurment_type_id integer NOT NULL,
    measurment_batch_id integer NOT NULL,
    height numeric(8,2),
    temperature numeric(8,2),
    pressure numeric(8,2),
    wind_speed numeric(8,2),
    wind_direction numeric(8,2),
    bullet_speed numeric(8,2)
);
CREATE TABLE IF NOT EXISTS igor.measurment_batch (
    id integer NOT NULL,,
    start_period timestamp without time zone DEFAULT now(),
    position_x numeric(3,2),
    position_y numeric(3,2),
    users_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS igor.measurment_type (
    id integer NOT NULL,
    equip_type character varying(100)
);

CREATE TABLE IF NOT EXISTS igor.users (
    id integer NOT NULL,,
    username character varying(50),
	military_position character varying(50)
);

CREATE SEQUENCE igor.params_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE igor.params_seq OWNED BY igor.measurment_params.id;

CREATE SEQUENCE igor.batch_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE igor.batch_seq OWNED BY igor.measurment_batch.id;

CREATE SEQUENCE igor.type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE igor.type_seq OWNED BY igor.measurment_type.id;

CREATE SEQUENCE igor.users_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE igor.users_seq OWNED BY igor.users.id;

insert into igor.measurment_type(equip_type) values ('DMK');
insert into igor.measurment_type(equip_type) values ('BP');

insert into igor.measurment_params(measurment_type_id,measurment_batch_id,height,temperature,pressure,wind_speed,wind_direction)
values (1,1,100,12,34,45,0.2);
insert into igor.measurment_params(measurment_type_id,measurment_batch_id,height,temperature,pressure,bullet_speed,wind_direction)
values (1,1,100,12,34,45,0.2);

insert into igor.users(username,military_position) values ('igor','general');
insert into igor.measurment_batch(start_period,position_x,position_y,users_id) values (now(),0.5,0.5,1);



-- select * from igor.measurment_type;
-- select * from igor.measurment_params;
-- select * from igor.measurment_batch;
select * from igor.users inner join igor.measurment_batch on igor.measurment_batch.users_id = igor.users.id;

-- drop table igor.measurment_type;
-- drop table igor.measurment_params;
-- drop table  igor.measurment_batch;
-- drop table igor.users;

alter table igor.measurment_batch
add constraint users_id_contraint
foreign key (users_id)
references igor.users(id);


alter table igor.measurment_params
add constraint measurment_type_id_contraint
foreign key (measurment_type_id)
references igor.measurment_type(id);


alter table igor.measurment_params
add constraint measurment_batch_id_contraint
foreign key (measurment_batch_id)
references igor.measurment_batch(id);




select * from igor.users inner join igor.measurment_batch on igor.measurment_batch.users_id = igor.users.id;


select * from igor.measurment_params inner join igor.measurment_batch on igor.measurment_batch.id = igor.measurment_params.measurment_batch_id;

CREATE TABLE IF NOT EXISTS igor.temperature
(
    t integer NOT NULL,
    deltat numeric(8,2) NOT NULL
)


