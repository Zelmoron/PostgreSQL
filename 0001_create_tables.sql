CREATE TABLE  IF NOT EXISTS igor.measurment_params (
    id serial primary key NOT NULL,
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
    id serial primary key NOT NULL,
    start_period timestamp without time zone DEFAULT now(),
    position_x numeric(3,2),
    position_y numeric(3,2),
    users_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS igor.measurment_type (
    id serial primary key NOT NULL,
    equip_type character varying(100)
);

CREATE TABLE IF NOT EXISTS igor.users (
    id serial primary key NOT NULL,
    username character varying(50),
	military_position character varying(50)
);
insert into igor.measurment_type(equip_type) values ('DMK');
insert into igor.measurment_type(equip_type) values ('BP');

insert into igor.measurment_params(measurment_type_id,measurment_batch_id,height,temperature,pressure,wind_speed,wind_direction)
values (1,1,100,12,34,45,0.2);
insert into igor.measurment_params(measurment_type_id,measurment_batch_id,height,temperature,pressure,bullet_speed,wind_direction)
values (1,1,100,12,34,45,0.2);

insert into igor.measurment_batch(start_period,position_x,position_y,users_id) values (now(),0.5,0.5,1);

insert into igor.users(username,military_position) values ('igor','general');

-- select * from igor.measurment_type;
-- select * from igor.measurment_params;
-- select * from igor.measurment_batch;
select * from igor.users inner join igor.measurment_batch on igor.measurment_batch.users_id = igor.users.id;

-- drop table igor.measurment_type;
-- drop table igor.measurment_params;
-- drop table  igor.measurment_batch;
-- drop table igor.users;