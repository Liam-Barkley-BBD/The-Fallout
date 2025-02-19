/*
=============================================
Description:    Function to check if a given ID iexists or not.
Parameters:     - p_ID (TEXT): The ID to be checked.
                - p_ColName (TEXT): The name of the primary key column.
                - p_TabName (TEXT): The name of the table where the
                                    column is.
Returns:        BOOLEAN - t: if the string is valid, f: if not valid.
=============================================
*/
CREATE OR REPLACE FUNCTION IdExists(
    p_ID INT,
    p_ColName TEXT,
    p_TabName TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_ExistsFlag BOOLEAN;
    v_SqlQuery TEXT;
BEGIN
    v_SqlQuery := FORMAT('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1)',
    p_TabName, p_ColName);

    EXECUTE v_SqlQuery INTO v_ExistsFlag USING p_ID;

    RETURN v_ExistsFlag;
END;
$$ LANGUAGE plpgsql;

/*
=============================================
Description:    Function to check if a given string is valid name or not.
                For a name to be valid, it must be:
                    1. Non-empty
                    2. Only contain alphabetical letters
Parameters:     p_in (VARCHAR) - The string to be validated.
Returns:        BOOLEAN - t: if the string is valid, f: if not valid.
=============================================
*/
CREATE OR REPLACE FUNCTION ValidName(
    p_in VARCHAR(128)
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_in = '' OR p_in !~ '^[A-Za-z]+([ ''-][A-Za-z]+)*$' THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
=============================================
Description:    Function to check if a given survivor is deceased or not.
Parameters:     p_SurvivorID (INTEGER) - The SurvivorID to be checked.
Returns:        BOOLEAN - t: if the survivor is deceased, f: if not.
=============================================
*/
CREATE OR REPLACE FUNCTION IsDeceased(
    p_SurvivorID INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_deceased DATE;
BEGIN
    IF NOT IdExists(p_SurvivorID, 'SurvivorID', 'Survivors') THEN
        RAISE EXCEPTION 'SurvivorID % does not exist', p_SurvivorID;
    END IF;

    SELECT "DeceasedDate" INTO v_deceased FROM "Survivors"
    WHERE "SurvivorID" = p_SurvivorID;

    IF v_deceased IS NOT NULL THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GetShelter(
    p_SurvivorID INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_ShelterID INTEGER;
BEGIN
    IF NOT IdExists(p_SurvivorID, 'ShelterID', 'Shelters') THEN
        RAISE EXCEPTION 'SurvivorID % does not exist', p_SurvivorID;
    END IF;

    SELECT "ShelterID" INTO v_ShelterID FROM "ShelterSurvivors"
    WHERE "SurvivorID" = p_SurvivorID LIMIT 1;

    RETURN v_ShelterID;

END;
$$ LANGUAGE plpgsql;