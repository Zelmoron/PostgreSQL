CREATE SCHEMA IF NOT EXISTS igorr;
do $$
begin

raise notice 'Запускаем создание новой структуры базы данных meteo'; 
begin

    -- Связи
    alter table if exists igorr.measurment_input_params
    drop constraint if exists measurment_type_id_fk;

    alter table if exists igorr.employees
    drop constraint if exists military_rank_id_fk;

    alter table if exists igorr.measurment_baths
    drop constraint if exists measurment_input_param_id_fk;

    alter table if exists igorr.measurment_baths
    drop constraint if exists emploee_id_fk;

    -- Таблицы
    drop table if exists igorr.measurment_input_params;
    drop table if exists igorr.measurment_baths;
    drop table if exists igorr.employees;
    drop table if exists igorr.measurment_types;
    drop table if exists igorr.military_ranks;
    drop table if exists igorr.temperature;
    drop table if exists igorr.calc_temperatures_correction;
    

    -- Нумераторы
    drop sequence if exists igorr.measurment_input_params_seq;
    drop sequence if exists igorr.measurment_baths_seq;
    drop sequence if exists igorr.employees_seq;
    drop sequence if exists igorr.military_ranks_seq;
    drop sequence if exists igorr.measurment_types_seq;
end;

raise notice 'Удаление старых данных выполнено успешно';

-- Справочник должностей
create table igorr.military_ranks
(
    id integer primary key not null,
    description character varying(255)
);

insert into igorr.military_ranks(id, description)
values(1,'Рядовой'),(2,'Лейтенант');

create sequence igorr.military_ranks_seq start 3;

alter table igorr.military_ranks alter column id set default nextval('igorr.military_ranks_seq');

-- Пользователя
create table igorr.employees
(
    id integer primary key not null,
    name text,
    birthday timestamp ,
    military_rank_id integer
);

insert into igorr.employees(id, name, birthday,military_rank_id )  
values(1, 'Воловиков Александр Сергеевич','1978-06-24', 2);

create sequence igorr.employees_seq start 2;

alter table igorr.employees alter column id set default nextval('igorr.employees_seq');

-- Устройства для измерения
create table igorr.measurment_types
(
   id integer primary key not null,
   short_name  character varying(50),
   description text 
);

insert into igorr.measurment_types(id, short_name, description)
values(1, 'ДМК', 'Десантный метео комплекс'),
(2,'ВР','Ветровое ружье');

create sequence igorr.measurment_types_seq start 3;

alter table igorr.measurment_types alter column id set default nextval('igorr.measurment_types_seq');

-- Таблица с параметрами
create table igorr.measurment_input_params
(
    id integer primary key not null,
    measurment_type_id integer not null,
    height numeric(8,2) default 0,
    temperature numeric(8,2) default 0,
    pressure numeric(8,2) default 0,
    wind_direction numeric(8,2) default 0,
    wind_speed numeric(8,2) default 0
);

insert into igorr.measurment_input_params(id, measurment_type_id, height, temperature, pressure, wind_direction,wind_speed )
values(1, 1, 100,12,34,0.2,45);

create sequence igorr.measurment_input_params_seq start 2;

alter table igorr.measurment_input_params alter column id set default nextval('igorr.measurment_input_params_seq');

-- Таблица с историей
create table igorr.measurment_baths
(
        id integer primary key not null,
        emploee_id integer not null,
        measurment_input_param_id integer not null,
        started timestamp default now()
);

insert into igorr.measurment_baths(id, emploee_id, measurment_input_param_id)
values(1, 1, 1);

create sequence igorr.measurment_baths_seq start 2;

alter table igorr.measurment_baths alter column id set default nextval('igorr.measurment_baths_seq');

raise notice 'Создание общих справочников и наполнение выполнено успешно'; 

create table if not exists igorr.calc_temperatures_correction
(
   temperature numeric(8,2) primary key,
   correction numeric(8,2)
);

insert into igorr.calc_temperatures_correction(temperature, correction)
Values(0, 0.5),(5, 0.5),(10, 1), (20,1), (25, 2), (30, 3.5), (40, 4.5);

drop type if exists igorr.interpolation_type;
create type igorr.interpolation_type as
(
    x0 numeric(8,2),
    x1 numeric(8,2),
    y0 numeric(8,2),
    y1 numeric(8,2)
);

raise notice 'Расчетные структуры сформированы';

begin 
    
    alter table igorr.measurment_baths
    add constraint emploee_id_fk 
    foreign key (emploee_id)
    references igorr.employees (id);    
    
    alter table igorr.measurment_baths
    add constraint measurment_input_param_id_fk 
    foreign key(measurment_input_param_id)
    references igorr.measurment_input_params(id);
    
    alter table igorr.measurment_input_params
    add constraint measurment_type_id_fk
    foreign key(measurment_type_id)
    references igorr.measurment_types (id);
    
    alter table igorr.employees
    add constraint military_rank_id_fk
    foreign key(military_rank_id)
    references igorr.military_ranks (id);

end;

raise notice 'Связи сформированы';
raise notice 'Структура сформирована успешно';

end $$;

drop table if exists igorr.measure_settings;
drop table if exists igorr.constants;
--------------------------------------
CREATE TABLE IF NOT EXISTS igorr.constants
(
    key character varying(30) COLLATE pg_catalog."default" NOT NULL,
    value text COLLATE pg_catalog."default" NOT NULL
)

TABLESPACE pg_default;

insert into igorr.constants(key,value) values('const_pressure','750');
insert into igorr.constants(key,value) values('const_temperature','15.9');

------------------------------------------------------------------------------
select * from constants;

ALTER TABLE IF EXISTS igorr.constants
    OWNER to zelmoron;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_key
    ON igorr.constants USING btree
    (key COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
--------------------------------------------------------------------
CREATE TABLE if not exists igorr.measure_settings (
    param VARCHAR(50) NOT NULL,
    min_value NUMERIC NOT NULL,
    max_value NUMERIC NOT NULL,
    unit VARCHAR(20) NOT NULL
);

DO $$
begin
    IF (SELECT COUNT(*) FROM igorr.measure_settings) >= 3 THEN
        RAISE NOTICE 'Данные уже добавлены';
    else
        INSERT INTO igorr.measure_settings (param, min_value, max_value, unit) VALUES
        ('Высота метеопоста', -10000, 10000, 'м'),
        ('Температура', -58, 58, '°C'),
        ('Давление', 500, 900, 'мм рт. ст.'),
        ('Направление ветра', 0, 59, '°'),
        ('Скорость ветра', 0, 15, 'м/c'),
        ('Дальность сноса пуль', 0, 150, 'м');
        
        RAISE NOTICE 'Данные добавлены успешно';
    end if;
END;
$$;
--------------------------------------------------------------------------------------------
DROP TYPE IF EXISTS igorr.measure_type CASCADE;
CREATE TYPE igorr.measure_type AS (
    param NUMERIC,
	ttype text
);

CREATE OR REPLACE FUNCTION igorr.get_measure_setting(type_param VARCHAR, value_param numeric)
RETURNS igorr.measure_type AS $$
DECLARE
    mn_value numeric;
    mx_value numeric;
    result igorr.measure_type;
BEGIN
    -- Получаем минимальное и максимальное значение для параметра
    SELECT min_value, max_value
    INTO mn_value, mx_value
    FROM igorr.measure_settings
    WHERE param = type_param;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Параметр % не найден', type_param;
    END IF;

    -- Проверка на null
    IF value_param IS NULL THEN
        RAISE EXCEPTION 'Null вместо значения';
    END IF;

    -- Проверка на диапазон
    IF value_param < mn_value OR value_param > mx_value THEN
        -- Возвращаем NULL, что будет означать ошибку
        RETURN NULL;
    END IF;

    -- Возвращаем результат
    result.param := value_param;
    result.ttype := type_param;
    RETURN result;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS igorr."fnHeaderGetPresure"();
DROP FUNCTION IF EXISTS igorr."fnHeaderGetData"();
DROP FUNCTION IF EXISTS igorr."fnHeaderGetHeight"();



CREATE OR REPLACE FUNCTION igorr."fnHeaderGetData"()
    RETURNS text 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result text;
BEGIN
    var_result := TO_CHAR(NOW(), 'DDHH') || LEFT(TO_CHAR(NOW(), 'MI'), 1);
    RETURN var_result;
END;
$$;

CREATE OR REPLACE FUNCTION igorr."fnHeaderGetHeight"(
    height integer
)
    RETURNS text 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result text; 
BEGIN
    var_result := LPAD(height::text, 4, '0');
    RAISE NOTICE 'Результат: %', var_result;
    RETURN var_result;
END;
$$;
--------------------------------------------------------------------
CREATE OR REPLACE FUNCTION igorr.interpolate_correction(temp_input NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    interp_data igorr.interpolation_type;
    correction_result NUMERIC;
BEGIN
    SELECT correction INTO correction_result
    FROM igorr.calc_temperatures_correction
    WHERE temperature = temp_input;
    
    IF FOUND THEN
        RETURN correction_result;
    END IF;

    SELECT 
        t1.temperature, t2.temperature, 
        t1.correction, t2.correction
    INTO interp_data
    FROM 
        (SELECT temperature, correction 
         FROM igorr.calc_temperatures_correction 
         WHERE temperature <= temp_input 
         ORDER BY temperature DESC 
         LIMIT 1) AS t1,
        (SELECT temperature, correction 
         FROM igorr.calc_temperatures_correction 
         WHERE temperature >= temp_input 
         ORDER BY temperature ASC 
         LIMIT 1) AS t2;

    IF interp_data.x0 IS NULL OR interp_data.x1 IS NULL THEN
        RETURN NULL;
    END IF;

    correction_result := interp_data.y0 + 
                         (interp_data.y1 - interp_data.y0) * 
                         (temp_input - interp_data.x0) / 
                         (interp_data.x1 - interp_data.x0);
    
    RETURN correction_result;
END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION igorr."fnHeaderGetPresure"(
    pressure NUMERIC, temperature NUMERIC
)
RETURNS TEXT
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result NUMERIC;
    txt TEXT;
    results NUMERIC;
    int_res INTEGER;
    temp_correction NUMERIC;
    temp_adjusted NUMERIC;
    delta_temp INTEGER;
BEGIN

	RAISE NOTICE 'Входное значение temperature: %', temperature;
  	-- SELECT igorr.get_measure_setting('Температура', 23) INTO checkd;
	 
	  
    SELECT value::NUMERIC INTO var_result
    FROM igorr.constants
    WHERE key = 'const_pressure';

 
    results := pressure - var_result;
    int_res := results::INTEGER;


    temp_correction := igorr.interpolate_correction(temperature);
    

    temp_adjusted := temperature + temp_correction;
    
  
    SELECT value::NUMERIC INTO var_result
    FROM igorr.constants
    WHERE key = 'const_temperature';
    

    delta_temp := ROUND(temp_adjusted - var_result)::INTEGER;
    

    IF int_res > 0 THEN
        txt := LPAD(int_res::TEXT, 3, '0') || LPAD(delta_temp::TEXT, 2, '0');
    ELSE
        int_res := int_res * -1;
        txt := '5' || LPAD(int_res::TEXT, 2, '0') || LPAD(delta_temp::TEXT, 2, '0');
    END IF;
    
    RETURN txt;
END;
$$;
------------------------------------------------------------------

-- SELECT igorr."fnHeaderGetPresure"(730,23);
-- SELECT igorr."fnHeaderGetData"();
-- SELECT igorr."fnHeaderGetHeight"(10);

-- select * from igorr.calc_temperatures_correction;
-- SELECT igorr.interpolate_correction(23);

INSERT INTO igorr.employees (id, name, birthday, military_rank_id) 
VALUES
    (2, 'Иванов Иван Иванович', '1985-03-15', 1),
    (3, 'Петров Петр Петрович', '1990-07-10', 2),
    (4, 'Сидоров Александр Александрович', '1982-09-23', 1),
    (5, 'Кузнецов Дмитрий Дмитриевич', '1992-01-05', 2);

DO $$
DECLARE
    user_id INTEGER;
    measurment_type_id INTEGER;
    param_id INTEGER;
BEGIN
    FOR user_id IN 1..5 LOOP
        FOR measurment_type_id IN 1..2 LOOP
            FOR i IN 1..100 LOOP
                INSERT INTO igorr.measurment_input_params (
                    measurment_type_id, 
                    height, 
                    temperature, 
                    pressure, 
                    wind_direction, 
                    wind_speed
                ) 
                VALUES (
                    measurment_type_id, 
                    100 + (random() * 400),
                    20 + (random() * 10),
                    500 + (random() * 20),
                    random() * 80,
                    random() * 15
                ) RETURNING id INTO param_id;

                INSERT INTO igorr.measurment_baths (
                    emploee_id, 
                    measurment_input_param_id, 
                    started
                ) 
                VALUES (
                    user_id, 
                    param_id, 
                    NOW() - (random() * INTERVAL '30 days')
                );
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

-- select * from igorr.measurment_baths;
-- SELECT igorr."fnHeaderGetPresure"(780,27);
-- select igorr.get_measure_setting('Температура',123)
-- Создание таблицы температурных отклонений
-----------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS igorr.temperature_deviations;
CREATE TABLE IF NOT EXISTS igorr.temperature_deviations (
    height integer PRIMARY KEY,
    dev_1 numeric,
    dev_2 numeric,
    dev_3 numeric,
    dev_4 numeric,
    dev_5 numeric,
    dev_6 numeric,
    dev_7 numeric,
    dev_8 numeric,
    dev_9 numeric,
    dev_10 numeric,
    dev_20 numeric,
    dev_30 numeric,
    dev_40 numeric,
    dev_50 numeric
);


INSERT INTO igorr.temperature_deviations VALUES
(200, -1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49),
(400, -1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48),
(800, -1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46),
(1200, -1, -2, -3, -4, -5, -5, -5, -6, -7, -8, -17, -26, -35, -44),
(1600, -1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42),
(2000, -1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40),
(2400, -1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38),
(3000, -1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37),
(4000, -1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34);

------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS igorr.temperature_deviations_plus;
CREATE TABLE IF NOT EXISTS igorr.temperature_deviations_plus (
    height integer PRIMARY KEY,
    dev_1 numeric,
    dev_2 numeric,
    dev_3 numeric,
    dev_4 numeric,
    dev_5 numeric,
    dev_6 numeric,
    dev_7 numeric,
    dev_8 numeric,
    dev_9 numeric,
    dev_10 numeric,
    dev_20 numeric,
    dev_30 numeric,
    dev_40 numeric,
    dev_50 numeric
);


INSERT INTO igorr.temperature_deviations_plus VALUES
(200, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(400, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(800, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(1200, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(1600, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(2000, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(2400, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(3000, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null),
(4000, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 20, 30, null, null);

-------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION igorr."get_deviation_value"(
    p_height integer,
    p_value integer,
	sign bool
) RETURNS numeric AS $$
BEGIN
	IF sign = false THEN
		
	    RETURN CASE 
	        WHEN p_value <= 10 THEN
	            (SELECT CASE p_value
	                WHEN 1 THEN dev_1
	                WHEN 2 THEN dev_2
	                WHEN 3 THEN dev_3
	                WHEN 4 THEN dev_4
	                WHEN 5 THEN dev_5
	                WHEN 6 THEN dev_6
	                WHEN 7 THEN dev_7
	                WHEN 8 THEN dev_8
	                WHEN 9 THEN dev_9
	                WHEN 10 THEN dev_10
	            END
	            FROM temperature_deviations 
	            WHERE height = p_height)
	        WHEN p_value = 20 THEN
	            (SELECT dev_20 FROM temperature_deviations WHERE height = p_height)
	        WHEN p_value = 30 THEN
	            (SELECT dev_30 FROM temperature_deviations WHERE height = p_height)
	        WHEN p_value = 40 THEN
	            (SELECT dev_40 FROM temperature_deviations WHERE height = p_height)
	        WHEN p_value = 50 THEN
	            (SELECT dev_50 FROM temperature_deviations WHERE height = p_height)
	    END;
	END IF;
	RETURN CASE 
	        WHEN p_value <= 10 THEN
	            (SELECT CASE p_value
	                WHEN 1 THEN dev_1
	                WHEN 2 THEN dev_2
	                WHEN 3 THEN dev_3
	                WHEN 4 THEN dev_4
	                WHEN 5 THEN dev_5
	                WHEN 6 THEN dev_6
	                WHEN 7 THEN dev_7
	                WHEN 8 THEN dev_8
	                WHEN 9 THEN dev_9
	                WHEN 10 THEN dev_10
	            END
	            FROM igorr.temperature_deviations_plus
	            WHERE height = p_height)
	        WHEN p_value = 20 THEN
	            (SELECT dev_20 FROM igorr.temperature_deviations_plus WHERE height = p_height)
	        WHEN p_value = 30 THEN
	            (SELECT dev_30 FROM igorr.temperature_deviations_plus WHERE height = p_height)
	        WHEN p_value > 39 THEN NULL
	    END;
	
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION igorr.calculate_temperature_deviation(
    p_height integer,
    p_temperature numeric
) RETURNS numeric[] AS $$
DECLARE
    v_tens integer;
    v_ones integer;
    v_dev_tens numeric;
    v_dev_ones numeric;
    v_result numeric;
	sign bool;
BEGIN
	
    v_tens := CASE 
        WHEN p_temperature < 0 THEN 
            GREATEST(FLOOR(p_temperature / 10) * 10, -10)  
        ELSE 
            FLOOR(p_temperature / 10) * 10
    END;
    
    v_ones := p_temperature - v_tens;
    sign := true;
	IF p_temperature < 0 THEN
		sign := false;

	END IF;
    v_dev_tens := igorr.get_deviation_value(p_height, ABS(v_tens),sign);
    v_dev_ones := igorr.get_deviation_value(p_height, ABS(v_ones),sign);

    v_result := v_dev_tens + v_dev_ones;
    

	-- IF v_result is null then
	-- 	Raise exception "Нельзя посчитать"
	-- END IF;
    IF p_temperature < 0 THEN
        v_result := ABS(v_result) + 50;
    END IF;

    RETURN ARRAY[ABS(v_tens), ABS(v_ones), v_dev_tens, v_dev_ones, v_result];
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------



WITH measurements AS (
	SELECT 
		mb.emploee_id,
		mip.temperature,
		mip.pressure,
		mip.wind_direction,
		mip.wind_speed
	FROM igorr.measurment_baths mb
	JOIN igorr.measurment_input_params mip 
		ON mb.measurment_input_param_id = mip.id
),
errors AS (
	SELECT 
		m.emploee_id,
		COUNT(*) FILTER (WHERE 
			(
				SELECT igorr.get_measure_setting('Температура', m.temperature) IS NULL
			) OR 
			(
				SELECT igorr.get_measure_setting('Давление', m.pressure) IS NULL
			) OR 
			(
				SELECT igorr.get_measure_setting('Направление ветра', m.wind_direction) IS NULL
			) OR 
			(
				SELECT igorr.get_measure_setting('Скорость ветра', m.wind_speed) IS NULL
			)
		) AS error_count
	FROM measurements m
	GROUP BY m.emploee_id
)
SELECT 
	e.name AS "ФИО",
	mr.description AS "Должность",  
	COUNT(mb.id) AS "Кол-во измерений",
	COALESCE(err.error_count, 0) AS "Количество ошибочных данных"
FROM igorr.employees e
LEFT JOIN igorr.military_ranks mr ON e.military_rank_id = mr.id
LEFT JOIN igorr.measurment_baths mb ON e.id = mb.emploee_id
LEFT JOIN errors err ON e.id = err.emploee_id
GROUP BY e.id, e.name, mr.description, err.error_count  
ORDER BY "Количество ошибочных данных" DESC;

--select igorr."calculate_temperature_deviation"(200,40);
-- SELECT * FROM igorr.employees LIMIT 5;
-- -- SELECT * FROM igorr.measurment_baths LIMIT 5;
-- select * from igorr.measurment_input_params;
-- SELECT igorr.get_measure_setting('Температура', 1);
-- SELECT * FROM igorr.military_ranks LIMIT 5;

