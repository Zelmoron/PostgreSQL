select * from igor.measurment_type;
insert into igor.measurment_type(equip_type) values ('Test'),('Test2');

DO $$
DECLARE
    record_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO record_count FROM igor.measurment_type;
    RAISE NOTICE 'Кол-во: %', record_count;
    IF record_count > 3 THEN
        RAISE EXCEPTION 'Количество записей превышает допустимый лимит (2).';
    END IF;
END;
$$;





-- delete from igor.measurment_type where igor.measurment_type.id = 4;