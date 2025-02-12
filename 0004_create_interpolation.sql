CREATE OR REPLACE FUNCTION igor.interpolate_deltat(input_t numeric)
RETURNS numeric AS $$
DECLARE
    lower_t integer;
    upper_t integer;
    lower_deltat numeric;
    upper_deltat numeric;
    interpolated_deltat numeric;
BEGIN
    SELECT t, deltat INTO lower_t, lower_deltat
    FROM igor.temperature
    WHERE t <= input_t
    ORDER BY t DESC
    LIMIT 1;

    SELECT t, deltat INTO upper_t, upper_deltat
    FROM igor.temperature
    WHERE t >= input_t
    ORDER BY t ASC
    LIMIT 1;

    IF lower_t IS NULL OR upper_t IS NULL THEN
        RETURN NULL;
    END IF;

    IF lower_t = upper_t THEN
        RETURN lower_deltat;
    END IF;

    interpolated_deltat := lower_deltat + (upper_deltat - lower_deltat) * (input_t - lower_t) / (upper_t - lower_t);

    RETURN interpolated_deltat;
END;
$$ LANGUAGE plpgsql;


SELECT igor.interpolate_deltat(
	18
); 
