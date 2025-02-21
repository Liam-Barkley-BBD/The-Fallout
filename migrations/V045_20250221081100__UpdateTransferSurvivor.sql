CREATE OR REPLACE FUNCTION GetShelterStats(p_shelter_id INTEGER)
RETURNS TABLE (
    ShelterID INTEGER,
    Latitude NUMERIC,
    Longitude NUMERIC,
    BottleCapAllowance INTEGER,
    Total_Survivors INTEGER,
    Total_Bean_Supplies INTEGER,
    Available_Bean_Supplies INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sh."ShelterID",
        sh."Latitude",
        sh."Longitude",
        sh."BottleCapAllowance",
        COUNT(DISTINCT ss."SurvivorID")::INTEGER AS Total_Survivors,
        COALESCE(bs_data.Total_Bean_Supplies, 0)::INTEGER AS Total_Bean_Supplies,
        COALESCE(bs_data.Available_Bean_Supplies, 0)::INTEGER AS Available_Bean_Supplies
    FROM 
        "Shelters" sh
    LEFT JOIN 
        "ShelterSurvivors" ss ON sh."ShelterID" = ss."ShelterID"
    LEFT JOIN (
        SELECT 
            bs."ShelterID",
            COUNT(bs."BeanSupplyID")::INTEGER AS Total_Bean_Supplies,
            COUNT(CASE WHEN bs."ConsumedDate" IS NULL THEN 1 END)::INTEGER AS Available_Bean_Supplies
        FROM "BeanSupplies" bs
        GROUP BY bs."ShelterID"
    ) bs_data ON sh."ShelterID" = bs_data."ShelterID"
    WHERE
        sh."ShelterID" = p_shelter_id
    GROUP BY 
        sh."ShelterID", sh."Latitude", sh."Longitude", sh."BottleCapAllowance", 
        bs_data.Total_Bean_Supplies, bs_data.Available_Bean_Supplies;
END;
$$;

