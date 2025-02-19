DO $$
BEGIN
    FOR i IN 1..10 LOOP
        CALL InsertBeanSupply(2, 1);
    END LOOP;

    FOR i IN 1..5 LOOP
        CALL InsertBeanSupply(2, 2);
    END LOOP;
END $$;

CALL MakeBeanRequest(1);